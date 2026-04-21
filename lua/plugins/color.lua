return {
  "folke/tokyonight.nvim",
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "storm", -- "storm" | "night" | "moon" | "day"
      on_highlights = function(hl, c)
        -- diff 색상 강화 (added/removed/changed 배경색을 더 진하게)
        hl.DiffAdd     = { bg = "#2a4a2a" }
        hl.DiffChange  = { bg = "#3a3a1a" }
        hl.DiffDelete  = { bg = "#4a2a2a" }
        hl.DiffText    = { bg = "#4a4a1a" }

        -- diffview/fugitive 등에서 사용하는 하이라이트
        hl.DiffAdded   = { fg = "#98c379", bg = "#2a4a2a" }
        hl.DiffRemoved = { fg = "#e06c75", bg = "#4a2a2a" }
        hl.DiffChanged = { fg = "#e5c07b", bg = "#3a3a1a" }
      end,
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
