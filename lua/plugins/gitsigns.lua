return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" }, -- 파일 열릴 때 로드
  opts = {
    signs                   = {
      add          = { text = "│" },
      change       = { text = "│" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
    },
    signcolumn              = true,  -- git 변경 사항을 signcolumn에 표시
    numhl                   = false, -- 줄 번호 강조 비활성화
    linehl                  = false, -- 줄 전체 강조 비활성화
    word_diff               = false, -- 단어 단위 diff 비활성화

    watch_gitdir            = {
      interval = 1000,
      follow_files = true,
    },

    attach_to_untracked     = true,
    current_line_blame      = false, -- 현재 줄 blame 비활성화
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 끝에 표시
      delay = 1000,
      ignore_whitespace = false,
    },
  },
}
