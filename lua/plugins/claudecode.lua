-- Claude Code IDE 통합 (공식 VS Code 확장과 동일한 WebSocket MCP 프로토콜)
-- 키맵은 lua/config/keymap.lua 의 "AI (Claude Code)" 섹션에 정의
local claude_bin = vim.fn.exepath("claude")

return {
  "coder/claudecode.nvim",
  -- keys 대신 cmd 로 지연 로딩: keymap.lua 의 <cmd>ClaudeCode*<CR> 매핑이
  -- 플러그인 로드 전에도 동작하도록 커맨드 스텁을 만들어 둔다.
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSelectModel",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeSendText",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  opts = {
    -- 네이티브 바이너리 설치라 절대 경로로 고정 (PATH 미상속 환경 대비)
    terminal_cmd = claude_bin ~= "" and claude_bin or nil,
    terminal = {
      provider = "native", -- snacks.nvim 미설치 → nvim 내장 터미널
      split_side = "right",
      split_width_percentage = 0.35,
    },
    diff_opts = {
      layout = "vertical",
      keep_terminal_focus = false,
    },
  },
}
