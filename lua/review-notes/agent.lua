-- review-notes/agent.lua
-- 고른 노트를 에이전트에게 "지목" 한다.
--
-- 두 갈래로 보낸다.
--   1. 위치: claudecode 의 @멘션 (파일 내용을 에이전트가 직접 읽게 한다)
--   2. 지시문 + 노트 본문: 터미널 프롬프트 텍스트
--
-- 멘션은 claudecode 안에서 50ms 디바운스로 배치 전송되므로, 텍스트가 멘션보다 먼저
-- 프롬프트에 꽂히지 않도록 그만큼 늦춰 보낸다. Claude 가 아직 안 붙어 있으면
-- send_at_mention 이 멘션을 큐에 넣고 터미널을 띄우므로, 연결을 기다린 뒤 텍스트를 넣는다.
--
-- claudecode 가 없거나 끝내 붙지 않으면 같은 프롬프트를 클립보드로 넘긴다.
-- 어느 경로로 가든 에이전트가 받는 내용은 동일하다.
local store = require("review-notes.store")

local M = {}

M.config = {
  --- 멘션 디바운스(50ms)보다 넉넉하게. 텍스트를 이만큼 늦춰 보낸다.
  mention_flush_ms = 200,
  --- Claude 부팅/연결 대기. 넘으면 클립보드로 폴백한다.
  connect_timeout_ms = 15000,
  poll_ms = 250,
  --- false 면 프롬프트에 넣기만 하고 제출은 사용자가 한다.
  submit = true,
}

---@param note table
---@return string
local function range_label(note)
  if note.lnum == note.end_lnum then
    return ("L%d"):format(note.lnum)
  end
  return ("L%d-%d"):format(note.lnum, note.end_lnum)
end

--- 알림에 쓸 번호 목록.
---@param notes table[]
---@return string
local function numbers(notes)
  local out = {}
  for _, n in ipairs(notes) do
    out[#out + 1] = "#" .. tostring(n.number or "?")
  end
  return table.concat(out, " ")
end

--- 에이전트에게 보낼 프롬프트.
--- 번호를 앞세워서 답신도 번호로 오게 한다. 기준줄을 함께 주는 이유는
--- 노트를 적은 뒤 코드가 밀렸을 때 에이전트가 라인 번호 대신 이걸로 찾게 하기 위함이다.
---@param notes table[]
---@return string
function M.prompt(notes)
  local lines = {
    "아래 로컬 리뷰 노트를 고쳐줘. (nvim review-notes 메모 — PR 코멘트가 아니라 로컬에만 있는 것)",
    "고친 뒤 처리한 노트를 #번호로 알려줘. 안 고친 게 있으면 이유도 번호와 함께.",
    "",
  }
  for _, n in ipairs(notes) do
    lines[#lines + 1] = ("#%s %s:%s"):format(tostring(n.number or "?"), n.path or "?", range_label(n))
    for _, tl in ipairs(vim.split(n.text or "", "\n", { plain = true })) do
      lines[#lines + 1] = "  " .. tl
    end
    local snip = n.snippet and n.snippet[1]
    if snip and snip:gsub("%s", "") ~= "" then
      lines[#lines + 1] = ("  (기준줄: %s)"):format(vim.trim(snip))
    end
    lines[#lines + 1] = ""
  end
  return (table.concat(lines, "\n"):gsub("%s+$", ""))
end

--- 폴백. 프롬프트를 클립보드에 넣고 왜 그랬는지 알린다.
---@param text string
---@param why string
local function to_clipboard(text, why)
  vim.fn.setreg("+", text)
  vim.notify(
    ("[review-notes] %s 프롬프트를 클립보드(+)에 복사했습니다"):format(why),
    vim.log.levels.WARN
  )
end

--- 위치 멘션을 보낸다. 같은 범위가 여러 노트에 걸리면 한 번만.
---@param cc table  claudecode 모듈
---@param notes table[]
---@return string[] skipped  멘션을 보내지 못한 항목
local function send_mentions(cc, notes)
  local root = store.git_root()
  local seen, skipped = {}, {}
  for _, n in ipairs(notes) do
    local key = ("%s:%s"):format(n.path or "?", range_label(n))
    if not seen[key] then
      seen[key] = true
      local abs = root and n.path and (root .. "/" .. n.path)
      -- 파일이 없으면 claudecode 가 에러를 내므로 여기서 걸러낸다
      -- (다른 브랜치에서 적은 노트가 현재 작업트리에 없을 수 있다)
      if abs and vim.fn.filereadable(abs) == 1 then
        -- claudecode 는 0-indexed 라인을 받는다
        local ok = cc.send_at_mention(abs, (n.lnum or 1) - 1, (n.end_lnum or n.lnum or 1) - 1, "review-notes")
        if not ok then
          skipped[#skipped + 1] = key
        end
      else
        skipped[#skipped + 1] = key
      end
    end
  end
  return skipped
end

--- 노트를 에이전트에게 지목한다.
---@param notes table[]  store 레코드 (path/lnum/end_lnum/number/text/snippet)
---@param opts? {submit?: boolean, clipboard?: boolean}
function M.send(notes, opts)
  opts = opts or {}
  if not notes or #notes == 0 then
    vim.notify("[review-notes] 지목할 메모가 없습니다", vim.log.levels.INFO)
    return
  end

  -- 번호 오름차순으로 고정한다. 멘션·본문·알림이 같은 순서로 나가고,
  -- 에이전트도 그 순서로 답신한다. (같은 범위·같은 초에 만든 노트는 원래 순서가 tie)
  notes = vim.deepcopy(notes)
  table.sort(notes, function(a, b)
    return (a.number or math.huge) < (b.number or math.huge)
  end)

  local text = M.prompt(notes)
  local submit = opts.submit
  if submit == nil then
    submit = M.config.submit
  end

  -- 별도 세션(다른 터미널·tmux pane)이나 다른 도구(codex, 웹)에 붙여넣을 때.
  -- nvim 이 관리하는 Claude 터미널이 없으므로 아예 시도하지 않는다.
  if opts.clipboard then
    vim.fn.setreg("+", text)
    vim.notify(
      ("[review-notes] 노트 %d건 프롬프트를 클립보드(+)에 복사했습니다 (%s)"):format(
        #notes,
        numbers(notes)
      ),
      vim.log.levels.INFO
    )
    return
  end

  local ok, cc = pcall(require, "claudecode")
  if not ok then
    to_clipboard(text, "claudecode.nvim 이 없어")
    return
  end
  -- auto_start 가 꺼진 설정이면 서버가 없다. 이때만 띄운다.
  if not (cc.state and cc.state.server) then
    pcall(vim.cmd, "ClaudeCodeStart")
  end
  if not (cc.state and cc.state.server) then
    to_clipboard(text, "Claude Code 서버가 없어")
    return
  end

  local skipped = send_mentions(cc, notes)
  if #skipped > 0 then
    vim.notify(
      ("[review-notes] 위치 멘션을 건너뛴 항목: %s (본문은 그대로 보냅니다)"):format(
        table.concat(skipped, ", ")
      ),
      vim.log.levels.WARN
    )
  end

  local terminal = require("claudecode.terminal")
  local function push()
    if terminal.send_to_terminal(text, { submit = submit }) then
      vim.notify(
        ("[review-notes] 노트 %d건을 Claude 에 지목했습니다 (%s)"):format(#notes, numbers(notes)),
        vim.log.levels.INFO
      )
    else
      to_clipboard(text, "Claude 터미널에 쓸 수 없어")
    end
  end

  if cc.is_claude_connected() then
    vim.defer_fn(push, M.config.mention_flush_ms)
    return
  end

  -- send_at_mention 이 터미널을 띄웠다. 붙을 때까지 기다린다.
  vim.notify(
    ("[review-notes] Claude 연결을 기다립니다… (%s)"):format(numbers(notes)),
    vim.log.levels.INFO
  )
  local timer = vim.uv.new_timer()
  local waited, done = 0, false
  local function finish(fn)
    if done then
      return
    end
    done = true
    timer:stop()
    timer:close()
    fn()
  end
  timer:start(
    M.config.poll_ms,
    M.config.poll_ms,
    vim.schedule_wrap(function()
      waited = waited + M.config.poll_ms
      if cc.is_claude_connected() then
        finish(function()
          vim.defer_fn(push, M.config.mention_flush_ms)
        end)
      elseif waited >= M.config.connect_timeout_ms then
        finish(function()
          to_clipboard(text, "Claude 가 시간 안에 붙지 않아")
        end)
      end
    end)
  )
end

return M
