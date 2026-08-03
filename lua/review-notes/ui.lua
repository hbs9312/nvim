-- review-notes/ui.lua
-- 노트 팝업과 여러 줄 메모 입력창.
--
-- 팝업은 커서를 따라다니지 않는다. 범위의 시작 라인 높이에, 창 오른쪽에 붙어 고정된다.
-- 중첩된 범위는 시작 라인이 서로 다르므로 그룹마다 박스를 하나씩 띄운다.
-- (1-10 과 5-10 이 걸리면 1행 옆과 5행 옆에 각각)
--
-- 라인 그룹은 각각 완전히 독립된 사각형이다. 범위 라벨은 테두리 title 로 올리고,
-- 박스 사이에는 빈 줄을 둔다. 테두리가 맞붙어 하나의 표처럼 보이면 안 된다.
local M = {}

--- 현재 떠 있는 팝업들. { {win=, buf=}, ... }
local popups = {}
--- 마지막으로 그린 상태의 서명. 같으면 다시 그리지 않는다(깜빡임 방지).
local last_signature

local hl_ns = vim.api.nvim_create_namespace("review_notes_popup")

--- 박스 오른쪽에 남길 여백(칼럼). 테두리 1칸은 별도로 계산한다.
local GAP = 1
--- 박스 사이에 둘 빈 줄. 0 이어도 테두리는 각자 한 줄씩 쓰므로 맞붙지 않는다.
local BOX_GAP = 0
--- 동시에 띄울 박스 최대 개수. 넘으면 마지막 박스에 안내를 붙인다.
local MAX_BOXES = 4

--- nvim_open_win 은 테두리를 footprint 안쪽에 그린다.
--- row/col 은 위/왼쪽 테두리 줄이고, 실제로 차지하는 높이는 height + 2 다.
---@param height integer
---@return integer
local function outer_height(height)
  return height + 2
end

--- 기본 하이라이트. 컬러스킴이 바뀌어도 링크가 유지되도록 default = true.
function M.setup_highlights()
  local defs = {
    ReviewNoteSign = "DiagnosticSignHint",
    ReviewNoteSignResolved = "Comment",
    ReviewNoteHeader = "Title",
    ReviewNoteOpen = "DiagnosticWarn",
    ReviewNoteResolved = "Comment",
    ReviewNoteStale = "DiagnosticError",
    ReviewNoteMeta = "Comment",
  }
  for name, link in pairs(defs) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

function M.close_popup()
  for _, p in ipairs(popups) do
    if vim.api.nvim_win_is_valid(p.win) then
      pcall(vim.api.nvim_win_close, p.win, true)
    end
  end
  popups = {}
  last_signature = nil
end

---@return boolean
function M.popup_open()
  return #popups > 0
end

---@param bufnr integer
---@return boolean
function M.is_popup_buf(bufnr)
  for _, p in ipairs(popups) do
    if p.buf == bufnr then
      return true
    end
  end
  return false
end

--- 동일 범위끼리 묶는다. 그룹 식별자는 "시작-끝" 라인 범위다.
---@param entries table[]  anchor.notes_at 결과
---@return table[]  { lnum, end_lnum, notes = {entry, ...} }
local function group_by_range(entries)
  local groups, order = {}, {}
  for _, e in ipairs(entries) do
    local key = e.lnum .. "-" .. e.end_lnum
    if not groups[key] then
      groups[key] = { lnum = e.lnum, end_lnum = e.end_lnum, notes = {} }
      order[#order + 1] = key
    end
    table.insert(groups[key].notes, e)
  end
  local out = {}
  for _, key in ipairs(order) do
    out[#out + 1] = groups[key]
  end
  return out
end

---@param group table
---@return string
local function range_label(group)
  if group.lnum == group.end_lnum then
    return ("L%d"):format(group.lnum)
  end
  return ("L%d-%d"):format(group.lnum, group.end_lnum)
end

---@param s string
---@return integer
local function dwidth(s)
  return vim.fn.strdisplaywidth(s)
end

--- 한 덩어리가 너비를 넘으면 문자 단위로 쪼갠다.
--- 공백 없는 긴 한글 문장이 여기로 온다.
---@param token string
---@param width integer
---@return string[]
local function hard_split(token, width)
  local parts, cur, cw = {}, "", 0
  for _, ch in ipairs(vim.fn.split(token, "\\zs")) do
    local w = dwidth(ch)
    if cw + w > width and cur ~= "" then
      parts[#parts + 1] = cur
      cur, cw = "", 0
    end
    cur, cw = cur .. ch, cw + w
  end
  if cur ~= "" then
    parts[#parts + 1] = cur
  end
  return parts
end

--- 표시 너비 기준 줄바꿈. 한글은 2칸으로 계산된다.
--- 너비를 고정했으므로 긴 메모가 잘려서 안 보이는 일이 없도록 여기서 접는다.
---@param text string
---@param width integer
---@return string[]
local function wrap_display(text, width)
  if width < 4 then
    return { text }
  end
  local out, cur, cw = {}, "", 0
  for token in text:gmatch("%S+") do
    local pieces = dwidth(token) > width and hard_split(token, width) or { token }
    for _, piece in ipairs(pieces) do
      local pw = dwidth(piece)
      if cur == "" then
        cur, cw = piece, pw
      elseif cw + 1 + pw <= width then
        cur, cw = cur .. " " .. piece, cw + 1 + pw
      else
        out[#out + 1] = cur
        cur, cw = piece, pw
      end
    end
  end
  if cur ~= "" then
    out[#out + 1] = cur
  end
  if #out == 0 then
    out = { "" }
  end
  return out
end

--- 그룹 하나를 박스 내용으로 렌더한다.
--- 범위 라벨은 테두리 title 로 나가므로 여기서는 메모만 담는다.
---@param group table
---@param max_height integer
---@param width integer  고정 너비
---@return string[] lines, table[] marks
local function render_group(group, max_height, width)
  local lines, marks = {}, {}
  --- end_col 을 주면 그 바이트까지만 칠한다. 없으면 줄 끝까지.
  local function add(text, hl, end_col)
    lines[#lines + 1] = text
    if hl then
      marks[#marks + 1] = { row = #lines - 1, hl = hl, end_col = end_col }
    end
  end

  for _, entry in ipairs(group.notes) do
    local note = entry.note
    local sym, hl
    if note.resolved then
      sym, hl = "✓", "ReviewNoteResolved"
    elseif entry.stale then
      sym, hl = "!", "ReviewNoteStale"
    else
      sym, hl = "●", "ReviewNoteOpen"
    end

    -- "#7 ● " 형태. 번호는 레포 단위 고정값이라 에이전트에게 그대로 말할 수 있다.
    local prefix = (" #%s %s "):format(tostring(note.number or "?"), sym)
    local indent = string.rep(" ", dwidth(prefix))
    local body_width = math.max(4, width - dwidth(prefix))

    local first = true
    for _, para in ipairs(vim.split(note.text or "", "\n", { plain = true })) do
      for _, wrapped in ipairs(wrap_display(para, body_width)) do
        if first then
          -- 상태색은 "#1 ● " 표식에만 준다. 본문까지 칠하면 첫 줄만 색이 달라
          -- 여러 줄 메모에서 어색해진다.
          add(prefix .. wrapped, hl, #prefix)
          first = false
        else
          add(indent .. wrapped)
        end
      end
    end
    if entry.stale then
      for _, wrapped in ipairs(wrap_display("(코드가 변경돼 위치를 찾지 못했습니다)", body_width)) do
        add(indent .. wrapped, "ReviewNoteMeta")
      end
    end
  end

  if #lines > max_height then
    local dropped = #lines - (max_height - 1)
    while #lines > max_height - 1 do
      table.remove(lines)
      -- 잘려나간 줄의 하이라이트도 버린다
      while #marks > 0 and marks[#marks].row > #lines - 1 do
        table.remove(marks)
      end
    end
    add(("   … %d줄 더 (<leader>nl)"):format(dropped), "ReviewNoteMeta")
  end

  -- 빈 메모만 있는 그룹도 박스는 떠야 한다(height 0 은 열 수 없다).
  if #lines == 0 then
    lines[1] = ""
  end

  return lines, marks
end

--- 다시 그릴 필요가 있는지 판단하기 위한 서명.
--- 커서가 같은 범위 안에서 움직이는 동안에는 박스가 미동도 하지 않아야 한다.
---@param entries table[]
---@param win integer
---@return string
local function signature(entries, win)
  local parts = { "w" .. win, "t" .. vim.fn.line("w0"), "W" .. vim.api.nvim_win_get_width(win) }
  for _, e in ipairs(entries) do
    parts[#parts + 1] = ("%d-%d:%s:%s"):format(
      e.lnum,
      e.end_lnum,
      e.note.id,
      tostring(e.note.resolved) .. tostring(e.stale)
    )
  end
  return table.concat(parts, "|")
end

---@param buf integer
---@param lines string[]
---@param marks table[]
local function fill(buf, lines, marks)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  for _, m in ipairs(marks) do
    local line = lines[m.row + 1] or ""
    pcall(vim.api.nvim_buf_set_extmark, buf, hl_ns, m.row, 0, {
      end_row = m.row,
      end_col = math.min(m.end_col or #line, #line),
      hl_group = m.hl,
    })
  end
end

--- 커서에 걸린 메모를 창 오른쪽에, 각 범위의 시작 라인 높이에 고정해 띄운다.
---@param entries table[]
---@param opts? {max_height: integer, max_width: integer}
function M.show_popup(entries, opts)
  opts = opts or {}
  if #entries == 0 then
    M.close_popup()
    return
  end

  local win = vim.api.nvim_get_current_win()
  local sig = signature(entries, win)
  if sig == last_signature and M.popup_open() then
    return -- 범위 안에서 커서만 움직인 경우: 그대로 둔다
  end

  local groups = group_by_range(entries)
  local wpos = vim.api.nvim_win_get_position(win)
  local wtop, wleft = wpos[1], wpos[2]
  local wwidth = vim.api.nvim_win_get_width(win)
  local wheight = vim.api.nvim_win_get_height(win)

  -- 테두리(좌우 각 1칸) + 오른쪽 여백을 뺀 가용 너비
  local avail_width = wwidth - 2 - GAP
  if avail_width < 16 then
    M.close_popup()
    return -- 창이 너무 좁으면 포기한다
  end
  -- 너비는 고정한다. 커서를 옮길 때마다 박스 폭이 들썩이지 않게.
  -- 창이 좁으면 그만큼만 줄인다.
  local width = math.max(16, math.min(opts.width or 50, avail_width))
  local max_height = math.max(3, math.min(opts.max_height or 20, wheight - 2))

  M.close_popup()

  -- 1) 내용을 먼저 만든다. 박스 높이를 알아야 자리를 잡을 수 있다.
  local boxes = {}
  for i = 1, math.min(#groups, MAX_BOXES) do
    local lines, marks = render_group(groups[i], max_height, width)
    boxes[#boxes + 1] = { group = groups[i], lines = lines, marks = marks }
  end

  -- 2) 위에서부터 자리를 잡는다. 앞 박스의 아래 테두리 밑으로 BOX_GAP 만큼
  --    빈 줄을 두므로 테두리가 맞붙지 않는다.
  local placed = {}
  local next_row -- 이 줄 위는 이미 다른 박스가 차지했다
  for _, box in ipairs(boxes) do
    local height = #box.lines
    -- 세로: 범위 시작 라인의 화면 위치. wrap/fold 를 고려해 screenpos 로 구한다.
    -- 시작 라인이 화면 밖(위로 스크롤됨)이면 창 최상단에 붙인다.
    local sp = vim.fn.screenpos(win, box.group.lnum, 1)
    local row = (sp.row > 0) and (sp.row - 1) or wtop
    if next_row and row < next_row then
      row = next_row
    end
    -- 아래 테두리까지 창 안에 들어오도록 제한
    row = math.min(row, wtop + wheight - outer_height(height))
    if row < wtop or (next_row and row < next_row) then
      break -- 겹치지 않게 넣을 자리가 없다. 남은 그룹은 overflow 로 안내한다.
    end
    placed[#placed + 1] = { box = box, row = row }
    next_row = row + outer_height(height) + BOX_GAP
  end

  -- 못 띄운 그룹 수. 박스 개수 제한과 자리 부족을 함께 센다.
  local overflow = #groups - #placed
  if overflow > 0 and #placed > 0 then
    local last = placed[#placed]
    local msg = ("   … %d개 그룹 더 (<leader>nl)"):format(overflow)
    if last.row + outer_height(#last.box.lines + 1) <= wtop + wheight then
      last.box.lines[#last.box.lines + 1] = msg
    else
      -- 한 줄 늘릴 자리가 없으면 마지막 줄을 안내로 바꾼다
      last.box.lines[#last.box.lines] = msg
      while #last.box.marks > 0 and last.box.marks[#last.box.marks].row >= #last.box.lines - 1 do
        table.remove(last.box.marks)
      end
    end
    last.box.marks[#last.box.marks + 1] = { row = #last.box.lines - 1, hl = "ReviewNoteMeta" }
  end

  -- 가로: 창 오른쪽 정렬 (테두리 좌우 1칸씩 + 여백 GAP)
  local col = math.max(wleft, wleft + wwidth - width - 2 - GAP)

  for _, p in ipairs(placed) do
    -- 범위 라벨은 위 테두리에 얹는다. 그룹 경계가 사각형 자체로 드러나야 한다.
    local label = range_label(p.box.group)
    local count = #p.box.group.notes
    local suffix = (" · %d notes"):format(count)
    if count > 1 and dwidth(label .. suffix) + 3 <= width then
      label = label .. suffix
    end
    if dwidth(label) + 3 > width then
      label = hard_split(label, math.max(1, width - 3))[1]
    end

    local buf = vim.api.nvim_create_buf(false, true)
    fill(buf, p.box.lines, p.box.marks)

    local ok, w = pcall(vim.api.nvim_open_win, buf, false, {
      relative = "editor",
      row = p.row,
      col = col,
      width = width,
      height = #p.box.lines,
      style = "minimal",
      border = "rounded",
      title = { { "─", "FloatBorder" }, { (" %s "):format(label), "ReviewNoteHeader" } },
      title_pos = "left",
      focusable = false,
      noautocmd = true,
      zindex = 40,
    })
    if ok then
      vim.wo[w].wrap = false
      popups[#popups + 1] = { win = w, buf = buf }
    else
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  last_signature = #popups > 0 and sig or nil
end

--- 여러 줄 메모 입력창. :w 저장, :q 취소.
---@param opts {title: string, text?: string}
---@param on_submit fun(text: string)
function M.input(opts, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  local initial = vim.split(opts.text or "", "\n", { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial)

  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "review-note://" .. os.time())

  local width = math.min(math.max(#opts.title + 6, 60), vim.o.columns - 8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - 12) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 8,
    style = "minimal",
    border = "rounded",
    title = " " .. opts.title .. " ",
    title_pos = "center",
    footer = " :w 저장   :q 취소 ",
    footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.bo[buf].modified = false

  local submitted = false
  local function finish()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      text = text:gsub("^%s*(.-)%s*$", "%1")
      vim.bo[buf].modified = false
      submitted = true
      finish()
      if text == "" then
        vim.notify("[review-notes] 내용이 비어 저장하지 않았습니다", vim.log.levels.WARN)
        return
      end
      on_submit(text)
    end,
  })

  -- :q 로 닫으면 취소. modified 여도 확인 없이 버린다.
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if not submitted then
        vim.notify("[review-notes] 취소했습니다", vim.log.levels.INFO)
      end
    end,
  })

  vim.keymap.set("n", "<C-c>", function()
    finish()
  end, { buffer = buf, desc = "메모 취소" })

  -- 새 메모면 바로 입력 모드로
  if opts.text == nil or opts.text == "" then
    vim.cmd("startinsert")
  end
end

--- 여러 메모 중 하나를 고른다. 하나뿐이면 바로 반환.
---@param entries table[]
---@param prompt string
---@param cb fun(entry: table|nil)
function M.select_entry(entries, prompt, cb)
  if #entries == 0 then
    cb(nil)
    return
  end
  if #entries == 1 then
    cb(entries[1])
    return
  end
  vim.ui.select(entries, {
    prompt = prompt,
    format_item = function(e)
      local first = vim.split(e.note.text or "", "\n", { plain = true })[1] or ""
      return ("#%s %s %s  %s"):format(
        tostring(e.note.number or "?"),
        e.note.resolved and "✓" or "●",
        range_label(e),
        first
      )
    end,
  }, cb)
end

return M
