return {
  "navarasu/onedark.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'warmer',
      highlights = {
        -- diff 색상 강화 (added/removed/changed 배경색을 더 진하게)
        DiffAdd      = { bg = "#2a4a2a" },
        DiffChange   = { bg = "#3a3a1a" },
        DiffDelete   = { bg = "#4a2a2a" },
        DiffText     = { bg = "#4a4a1a" },

        -- diffview/fugitive 등에서 사용하는 하이라이트
        DiffAdded    = { fg = "#98c379", bg = "#2a4a2a" },
        DiffRemoved  = { fg = "#e06c75", bg = "#4a2a2a" },
        DiffChanged  = { fg = "#e5c07b", bg = "#3a3a1a" },
      },
    }
    require('onedark').load()
  end
}

