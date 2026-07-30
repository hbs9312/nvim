-- review-notes/picker.lua
-- 메모 목록. 스코프(파일/브랜치/전체)와 resolve 필터를 전환할 수 있다.
-- telescope 가 없으면 quickfix 로 폴백한다.
--
-- 노멀 모드 <Space>(또는 <Tab>) 로 여러 개를 고르면 resolve/삭제가 한 번에 적용된다.
-- 고른 게 없으면 커서 항목 하나만 처리한다.
local store = require("review-notes.store")

local M = {}

--- 스코프 순환 순서
local SCOPES = { "file", "branch", "all" }
local SCOPE_LABEL = {
  file = "현재 파일 (전체 브랜치)",
  branch = "현재 브랜치",
  all = "전체",
}
local FILTER_LABEL = { open = "미해결만", all = "전체" }

---@param opts table
---@return table[]
local function collect(opts)
  local filter = {}
  if opts.scope == "file" then
    filter.path = opts.path
  elseif opts.scope == "branch" then
    filter.branch = store.branch()
  end
  if opts.resolved == "open" then
    filter.resolved = false
  end
  return store.query(filter)
end

---@param note table
---@return string
local function display(note, scope)
  local range = note.lnum == note.end_lnum and ("L%d"):format(note.lnum)
    or ("L%d-%d"):format(note.lnum, note.end_lnum)
  local first = vim.split(note.text or "", "\n", { plain = true })[1] or ""
  local num = ("#%-4s"):format(tostring(note.number or "?"))
  local mark = note.resolved and "✓" or "●"
  if scope == "file" then
    -- 파일이 고정이므로 브랜치를 보여주는 게 더 유용하다
    return ("%s %s %-10s %-9s %s"):format(num, mark, range, note.branch or "?", first)
  end
  return ("%s %s %s:%s  %s"):format(num, mark, note.path or "?", range, first)
end

--- 메모 위치로 점프. 다른 브랜치 메모는 라인이 어긋날 수 있다.
---@param note table
local function jump(note)
  local root = store.git_root()
  if not root then
    vim.notify("[review-notes] git 레포를 찾을 수 없습니다", vim.log.levels.WARN)
    return
  end
  local abs = root .. "/" .. note.path
  if vim.fn.filereadable(abs) == 0 then
    vim.notify(
      ("[review-notes] 현재 작업트리에 없는 파일입니다: %s"):format(note.path),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(abs))
  local total = vim.api.nvim_buf_line_count(0)
  pcall(vim.api.nvim_win_set_cursor, 0, { math.max(1, math.min(note.lnum, total)), 0 })
  vim.cmd("normal! zz")

  local cur = store.branch()
  if note.branch and note.branch ~= cur then
    vim.notify(
      ("[review-notes] 다른 브랜치(%s)의 메모입니다. 라인이 어긋날 수 있습니다."):format(note.branch),
      vim.log.levels.WARN
    )
  end
end

---@param notes table[]
local function to_quickfix(notes)
  local root = store.git_root() or vim.fn.getcwd()
  local items = {}
  for _, n in ipairs(notes) do
    items[#items + 1] = {
      filename = root .. "/" .. n.path,
      lnum = n.lnum,
      text = ("[%s]%s %s"):format(
        n.branch or "?",
        n.resolved and " ✓" or "",
        (vim.split(n.text or "", "\n", { plain = true })[1] or "")
      ),
    }
  end
  vim.fn.setqflist({}, "r", { title = "Review Notes", items = items })
  vim.cmd("copen")
end

--- 목록 열기.
---@param opts? {scope?: string, resolved?: string, path?: string}
function M.open(opts)
  opts = vim.tbl_extend("force", {
    scope = "branch",
    resolved = "open",
  }, opts or {})
  opts.path = opts.path or require("review-notes.anchor").buf_path(0)

  -- 현재 파일 스코프인데 파일을 특정할 수 없으면 브랜치 스코프로 내려간다
  if opts.scope == "file" and not opts.path then
    opts.scope = "branch"
  end

  local notes = collect(opts)

  local ok_tel, pickers = pcall(require, "telescope.pickers")
  if not ok_tel then
    if #notes == 0 then
      vim.notify("[review-notes] 표시할 메모가 없습니다", vim.log.levels.INFO)
      return
    end
    to_quickfix(notes)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local title = ("Review Notes — %s / %s (%d)"):format(
    SCOPE_LABEL[opts.scope],
    FILTER_LABEL[opts.resolved],
    #notes
  )

  local function reopen(next_opts)
    vim.schedule(function()
      M.open(next_opts)
    end)
  end

  --- 스페이스바로 고른 항목들. 고른 게 없으면 커서 항목 하나.
  ---@param prompt_bufnr integer
  ---@return table[] notes
  local function selection(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local out = {}
    for _, entry in ipairs(picker and picker:get_multi_selection() or {}) do
      out[#out + 1] = entry.value
    end
    if #out == 0 then
      local entry = action_state.get_selected_entry()
      if entry then
        out[1] = entry.value
      end
    end
    return out
  end

  --- 저장 후 화면을 맞춘다. 목록에서 처리하면 커서가 안 움직여서
  --- 팝업 갱신 계기(CursorMoved)가 없으므로 여기서 직접 다시 그린다.
  ---@param msg string
  local function after_change(msg)
    require("review-notes.anchor").refresh_all()
    require("review-notes").refresh_popup()
    vim.notify("[review-notes] " .. msg, vim.log.levels.INFO)
  end

  pickers
    .new({}, {
      prompt_title = title,
      results_title = "<Space> 선택  <C-a> 전체  <C-r> resolve  <C-x> 삭제  <C-s> 스코프  <C-f> 필터",
      finder = finders.new_table({
        results = notes,
        entry_maker = function(note)
          return {
            value = note,
            display = display(note, opts.scope),
            ordinal = table.concat({
              "#" .. tostring(note.number or ""),
              note.path or "",
              note.branch or "",
              note.text or "",
            }, " "),
            filename = (store.git_root() or "") .. "/" .. (note.path or ""),
            lnum = note.lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Note",
        define_preview = function(self, entry)
          local n = entry.value
          local range = n.lnum == n.end_lnum and ("L%d"):format(n.lnum)
            or ("L%d-%d"):format(n.lnum, n.end_lnum)
          local lines = {
            ("# #%s — %s"):format(tostring(n.number or "?"), n.path or "?"),
            "",
            ("- 범위: %s"):format(range),
            ("- 브랜치: %s"):format(n.branch or "?"),
            ("- 상태: %s"):format(n.resolved and "resolved" or "open"),
            ("- 작성: %s"):format(n.created_at or "?"),
          }
          if n.sha then
            lines[#lines + 1] = ("- 커밋: %s"):format(n.sha)
          end
          vim.list_extend(lines, { "", "---", "" })
          vim.list_extend(lines, vim.split(n.text or "", "\n", { plain = true }))
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = "markdown"
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            jump(entry.value)
          end
        end)

        -- resolve 토글. 여러 개를 골랐으면 전부 같은 상태로 맞춘다.
        -- (하나라도 미해결이면 전부 resolve, 전부 resolved 면 전부 미해결로)
        local function toggle_resolve()
          local picked = selection(prompt_bufnr)
          if #picked == 0 then
            return
          end
          local ids, all_resolved = {}, true
          for _, n in ipairs(picked) do
            ids[#ids + 1] = n.id
            if not n.resolved then
              all_resolved = false
            end
          end
          local target = not all_resolved

          actions.close(prompt_bufnr)
          local changed, err = store.update_many(ids, function(n)
            if n.resolved == target then
              return false
            end
            n.resolved = target
          end)
          if err then
            vim.notify("[review-notes] " .. tostring(err), vim.log.levels.ERROR)
          end
          after_change(
            ("메모 %d개를 %s 처리했습니다"):format(changed, target and "resolve" or "미해결로")
          )
          reopen(opts)
        end

        -- 삭제. 여러 개면 되돌릴 수 없으므로 한 번 묻는다.
        local function delete()
          local picked = selection(prompt_bufnr)
          if #picked == 0 then
            return
          end
          local ids, labels = {}, {}
          for _, n in ipairs(picked) do
            ids[#ids + 1] = n.id
            labels[#labels + 1] = "#" .. tostring(n.number or "?")
          end

          actions.close(prompt_bufnr)
          vim.schedule(function()
            if #ids > 1 then
              local answer = vim.fn.confirm(
                ("메모 %d개(%s)를 삭제합니다. 되돌릴 수 없습니다."):format(
                  #ids,
                  table.concat(labels, " ")
                ),
                "&Yes\n&No",
                2
              )
              if answer ~= 1 then
                vim.notify("[review-notes] 삭제를 취소했습니다", vim.log.levels.INFO)
                reopen(opts)
                return
              end
            end
            local removed, err = store.remove_many(ids)
            if err then
              vim.notify("[review-notes] " .. tostring(err), vim.log.levels.ERROR)
            end
            after_change(("메모 %d개를 삭제했습니다"):format(removed))
            reopen(opts)
          end)
        end

        -- 스코프 순환
        local function cycle_scope()
          local idx = 1
          for i, s in ipairs(SCOPES) do
            if s == opts.scope then
              idx = i
            end
          end
          local next_scope = SCOPES[(idx % #SCOPES) + 1]
          actions.close(prompt_bufnr)
          reopen(vim.tbl_extend("force", opts, { scope = next_scope }))
        end

        -- resolve 필터 순환
        local function cycle_filter()
          actions.close(prompt_bufnr)
          reopen(
            vim.tbl_extend("force", opts, { resolved = opts.resolved == "open" and "all" or "open" })
          )
        end

        -- 여러 개 고르기. 프롬프트 입력 중에는 공백이 검색어라서 노멀 모드에만 <Space> 를
        -- 붙이고, insert 모드에서는 telescope 기본값인 <Tab> 을 그대로 쓴다.
        local function toggle_select()
          actions.toggle_selection(prompt_bufnr)
          actions.move_selection_worse(prompt_bufnr)
        end

        map("n", "<Space>", toggle_select)
        for _, mode in ipairs({ "i", "n" }) do
          map(mode, "<C-a>", actions.toggle_all)
          map(mode, "<C-r>", toggle_resolve)
          map(mode, "<C-x>", delete)
          map(mode, "<C-s>", cycle_scope)
          map(mode, "<C-f>", cycle_filter)
        end
        return true
      end,
    })
    :find()
end

return M
