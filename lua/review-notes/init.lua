-- review-notes
-- 로컬 전용 코드 리뷰 메모. PR 에는 올라가지 않는다.
--
-- 자기가 올린 PR 을 자기가 리뷰하면서 "고쳤으면 하는 것" 을 적어두고,
-- 나중에 고칠 때(또는 에이전트가 고칠 때) 그 목록을 쓰는 용도.
--
-- 저장: ~/.hbrness/review-notes/<owner>/<repo>/{notes.json,notes.md}
--   - 워크트리 경로가 아니라 레포 정체성으로 키를 잡으므로 워크트리 간 공유된다
--   - 브랜치는 레코드 필드라서 "브랜치 무관 파일별 조회" 가 가능하다
--   - 레포 안에 없으므로 프로젝트에 잡히지 않는다
local store = require("review-notes.store")
local anchor = require("review-notes.anchor")
local ui = require("review-notes.ui")

local M = {}

M.config = {
  view = true, -- 커서 팝업 기본 on/off
  debounce_ms = 120, -- updatetime(4000) 대신 자체 디바운스를 쓴다
  popup_width = 50, -- 고정 너비. 창이 좁으면 그만큼만 줄어든다
  max_popup_height = 20,
}

--- 팝업 표시 여부. 전역 토글.
local view_enabled = true
local timer

---@return boolean
function M.view_enabled()
  return view_enabled
end

local function cancel_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

--- 커서 위치를 보고 팝업을 갱신한다.
local function update_popup()
  if not view_enabled then
    ui.close_popup()
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  if ui.is_popup_buf(bufnr) or not anchor.is_attached(bufnr) then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local entries = anchor.notes_at(bufnr, lnum)
  if #entries == 0 then
    ui.close_popup()
    return
  end
  ui.show_popup(entries, {
    max_height = M.config.max_popup_height,
    width = M.config.popup_width,
  })
end

local function schedule_popup()
  cancel_timer()
  if not view_enabled then
    ui.close_popup()
    return
  end
  timer = vim.uv.new_timer()
  timer:start(
    M.config.debounce_ms,
    0,
    vim.schedule_wrap(function()
      cancel_timer()
      pcall(update_popup)
    end)
  )
end

----------------------------------------------------------------------
-- 액션
----------------------------------------------------------------------

--- 메모 추가. Normal 은 커서 줄, Visual 은 선택 범위.
---@param line1? integer
---@param line2? integer
function M.add(line1, line2)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = anchor.buf_path(bufnr)
  if not path then
    vim.notify(
      "[review-notes] 이 버퍼는 git 레포의 파일이 아닙니다 (Octo 리뷰 버퍼도 아님)",
      vim.log.levels.WARN
    )
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local lnum = line1 or cursor
  local end_lnum = math.max(line2 or lnum, lnum)

  local side = anchor.octo_side(bufnr)
  local title = ("review note — %s %s"):format(
    path,
    lnum == end_lnum and ("L%d"):format(lnum) or ("L%d-%d"):format(lnum, end_lnum)
  )
  if side then
    title = title .. (" [%s]"):format(side)
  end

  ui.input({ title = title }, function(text)
    local snippet = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)
    local note = {
      path = path,
      lnum = lnum,
      end_lnum = end_lnum,
      branch = store.branch(),
      sha = store.head_sha(),
      snippet = snippet,
      text = text,
      side = side,
    }
    local saved, err = store.add(note)
    if not saved then
      vim.notify("[review-notes] 저장 실패: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    anchor.refresh_all()
    schedule_popup()
    vim.notify(("[review-notes] 메모를 저장했습니다 (%s)"):format(title), vim.log.levels.INFO)
  end)
end

---@param bufnr integer
---@return table[]
local function entries_at_cursor(bufnr)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  return anchor.notes_at(bufnr, lnum)
end

--- 번호로 메모를 찾는다.
---@param number integer
---@return table|nil
local function find_by_number(number)
  for _, n in ipairs(store.query({})) do
    if n.number == number then
      return n
    end
  end
  return nil
end

--- 번호로 메모 위치로 점프. 에이전트가 "#7 봤어" 라고 할 때 바로 가기 위한 통로.
---@param number integer
function M.goto_number(number)
  local note = find_by_number(number)
  if not note then
    vim.notify(("[review-notes] #%d 메모를 찾을 수 없습니다"):format(number), vim.log.levels.WARN)
    return
  end
  local root = store.git_root()
  local abs = root and (root .. "/" .. note.path)
  if not abs or vim.fn.filereadable(abs) == 0 then
    vim.notify(
      ("[review-notes] #%d 의 파일이 현재 작업트리에 없습니다: %s"):format(number, note.path),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(abs))
  local total = vim.api.nvim_buf_line_count(0)
  pcall(vim.api.nvim_win_set_cursor, 0, { math.max(1, math.min(note.lnum, total)), 0 })
  vim.cmd("normal! zz")
  if note.branch and note.branch ~= store.branch() then
    vim.notify(
      ("[review-notes] #%d 은 다른 브랜치(%s)의 메모입니다"):format(number, note.branch),
      vim.log.levels.WARN
    )
  end
end

--- 번호로 resolve 토글. 에이전트가 고친 항목을 번호로 닫을 때 쓴다.
---@param number integer
function M.resolve_number(number)
  local note = find_by_number(number)
  if not note then
    vim.notify(("[review-notes] #%d 메모를 찾을 수 없습니다"):format(number), vim.log.levels.WARN)
    return
  end
  local new_state
  store.update(note.id, function(n)
    n.resolved = not n.resolved
    new_state = n.resolved
  end)
  anchor.refresh_all()
  schedule_popup()
  vim.notify(
    ("[review-notes] #%d %s"):format(number, new_state and "resolve 처리" or "미해결로 되돌림"),
    vim.log.levels.INFO
  )
end

--- 커서 위치 메모의 resolve 상태를 토글.
function M.toggle_resolve()
  local bufnr = vim.api.nvim_get_current_buf()
  local entries = entries_at_cursor(bufnr)
  if #entries == 0 then
    vim.notify("[review-notes] 커서 위치에 메모가 없습니다", vim.log.levels.INFO)
    return
  end
  ui.select_entry(entries, "resolve 토글할 메모:", function(entry)
    if not entry then
      return
    end
    local ok, err = store.update(entry.note.id, function(n)
      n.resolved = not n.resolved
    end)
    if not ok then
      vim.notify("[review-notes] " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    anchor.refresh_all()
    schedule_popup()
    vim.notify(
      ("[review-notes] %s 처리했습니다"):format(entry.note.resolved and "미해결로" or "resolve"),
      vim.log.levels.INFO
    )
  end)
end

--- 커서 위치 메모 수정.
function M.edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local entries = entries_at_cursor(bufnr)
  if #entries == 0 then
    vim.notify("[review-notes] 커서 위치에 메모가 없습니다", vim.log.levels.INFO)
    return
  end
  ui.select_entry(entries, "수정할 메모:", function(entry)
    if not entry then
      return
    end
    ui.input({
      title = ("review note 수정 — %s"):format(entry.note.path),
      text = entry.note.text,
    }, function(text)
      store.update(entry.note.id, function(n)
        n.text = text
      end)
      anchor.refresh_all()
      schedule_popup()
    end)
  end)
end

--- 커서 위치 메모 삭제.
function M.delete()
  local bufnr = vim.api.nvim_get_current_buf()
  local entries = entries_at_cursor(bufnr)
  if #entries == 0 then
    vim.notify("[review-notes] 커서 위치에 메모가 없습니다", vim.log.levels.INFO)
    return
  end
  ui.select_entry(entries, "삭제할 메모:", function(entry)
    if not entry then
      return
    end
    store.remove(entry.note.id)
    anchor.refresh_all()
    ui.close_popup()
    vim.notify("[review-notes] 메모를 삭제했습니다", vim.log.levels.INFO)
  end)
end

--- 팝업 on/off.
---@param state? boolean|string  nil 이면 토글
function M.toggle_view(state)
  if state == nil or state == "toggle" or state == "" then
    view_enabled = not view_enabled
  elseif state == true or state == "on" then
    view_enabled = true
  else
    view_enabled = false
  end
  if not view_enabled then
    ui.close_popup()
  else
    schedule_popup()
  end
  vim.notify(
    ("[review-notes] 커서 팝업 %s"):format(view_enabled and "on" or "off"),
    vim.log.levels.INFO
  )
end

--- 저장 내용이 바뀐 뒤 커서 팝업을 다시 그린다.
--- 목록에서 일괄 처리하면 커서가 움직이지 않아 자동 갱신 계기가 없다.
function M.refresh_popup()
  ui.close_popup()
  schedule_popup()
end

---@param opts? table
function M.list(opts)
  require("review-notes.picker").open(opts)
end

--- 에이전트용 마크다운 미러를 연다.
function M.open_md()
  local p = store.md_path()
  if not p then
    vim.notify("[review-notes] git 레포가 아닙니다", vim.log.levels.WARN)
    return
  end
  if vim.fn.filereadable(p) == 0 then
    vim.notify("[review-notes] 아직 기록된 메모가 없습니다", vim.log.levels.INFO)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(p))
end

--- 저장 위치와 현재 상태를 보여준다. 에이전트에게 경로를 알려줄 때 쓴다.
function M.info()
  local key, err = store.repo_key()
  if not key then
    vim.notify("[review-notes] " .. tostring(err), vim.log.levels.WARN)
    return
  end
  local all = store.query({})
  local open = store.query({ resolved = false })
  local branch_notes = store.query({ branch = store.branch() })
  local msg = table.concat({
    "레포 키   : " .. key,
    "브랜치    : " .. store.branch(),
    "JSON      : " .. tostring(store.json_path()),
    "Markdown  : " .. tostring(store.md_path()),
    ("메모      : 전체 %d개 (미해결 %d) / 현재 브랜치 %d개"):format(
      #all,
      #open,
      #branch_notes
    ),
    "커서 팝업 : " .. (view_enabled and "on" or "off"),
  }, "\n")
  vim.notify(msg, vim.log.levels.INFO, { title = "review-notes" })
end

----------------------------------------------------------------------
-- setup
----------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  view_enabled = M.config.view ~= false

  ui.setup_highlights()

  local group = vim.api.nvim_create_augroup("ReviewNotes", { clear = true })

  -- 버퍼가 화면에 올라올 때 메모를 붙인다.
  -- BufWinEnter 는 Octo 가 diff 버퍼를 창에 넣은 뒤에도 발생하므로 두 경우를 다 잡는다.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
    group = group,
    callback = function(ev)
      if ui.is_popup_buf(ev.buf) then
        return
      end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          pcall(anchor.attach, ev.buf)
        end
      end)
    end,
  })

  -- 저장 시 extmark 위치를 디스크에 반영
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      if anchor.is_attached(ev.buf) then
        pcall(anchor.persist, ev.buf)
      end
    end,
  })

  -- 팝업이 범위 시작 라인에 고정되므로, 커서 이동뿐 아니라
  -- 스크롤(<C-e>, zz 등 커서가 안 움직이는 경우)에도 위치를 다시 잡아야 한다.
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled", "WinResized" }, {
    group = group,
    callback = schedule_popup,
  })

  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave", "CmdlineEnter" }, {
    group = group,
    callback = function()
      cancel_timer()
      ui.close_popup()
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev)
      anchor.detach(ev.buf)
    end,
  })

  -- Octo 리뷰 버퍼에서는 Octo 의 코멘트 계열 키(<localleader>ca/sa)와 같은 자리에
  -- 로컬 메모를 붙여둔다. "comment note" 로 기억하면 된다.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev)
      if anchor.octo_side(ev.buf) then
        vim.keymap.set({ "n", "x" }, "<localleader>cn", function()
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" then
            local s, e = vim.fn.line("v"), vim.fn.line(".")
            vim.api.nvim_feedkeys(
              vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
              "nx",
              false
            )
            M.add(math.min(s, e), math.max(s, e))
          else
            M.add()
          end
        end, { buffer = ev.buf, desc = "로컬 리뷰 메모 추가" })
      end
    end,
  })

  local cmd = vim.api.nvim_create_user_command
  cmd("ReviewNote", function(o)
    M.add(o.line1, o.line2)
  end, { range = true, desc = "리뷰 메모 추가" })
  -- 인자로 스코프를 지정할 수 있다. 없으면 현재 브랜치.
  cmd("ReviewNoteList", function(o)
    local scope = (o.args or ""):gsub("%s", "")
    if scope == "" then
      M.list()
      return
    end
    if not vim.tbl_contains({ "file", "branch", "all" }, scope) then
      vim.notify(
        ("[review-notes] 스코프는 file|branch|all 중 하나입니다: %s"):format(scope),
        vim.log.levels.WARN
      )
      return
    end
    M.list({ scope = scope })
  end, {
    nargs = "?",
    complete = function()
      return { "file", "branch", "all" }
    end,
    desc = "리뷰 메모 목록 (file|branch|all)",
  })
  -- 인자 없으면 커서 위치, 번호를 주면 그 메모를 토글한다.
  cmd("ReviewNoteResolve", function(o)
    local num = tonumber((o.args or ""):match("#?(%d+)"))
    if num then
      M.resolve_number(num)
    else
      M.toggle_resolve()
    end
  end, { nargs = "?", desc = "resolve 토글 (커서 위치 또는 #번호)" })
  cmd("ReviewNoteGoto", function(o)
    local num = tonumber((o.args or ""):match("#?(%d+)"))
    if not num then
      vim.notify("[review-notes] 사용법: :ReviewNoteGoto <번호>", vim.log.levels.WARN)
      return
    end
    M.goto_number(num)
  end, { nargs = 1, desc = "번호로 메모 위치로 점프" })
  cmd("ReviewNoteEdit", function()
    M.edit()
  end, { desc = "커서 메모 수정" })
  cmd("ReviewNoteDelete", function()
    M.delete()
  end, { desc = "커서 메모 삭제" })
  cmd("ReviewNoteView", function(o)
    M.toggle_view(o.args ~= "" and o.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return { "on", "off", "toggle" }
    end,
    desc = "커서 팝업 on/off",
  })
  cmd("ReviewNoteOpen", function()
    M.open_md()
  end, { desc = "notes.md 열기" })
  cmd("ReviewNoteInfo", function()
    M.info()
  end, { desc = "저장 경로/상태 확인" })
end

return M
