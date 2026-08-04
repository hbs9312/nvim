-- 테마 후보 인벤토리. 설치만 하고 적용은 하지 않는다 —
-- 실제로 어떤 테마가 뜨는지는 lua/config/colorscheme.lua 가 결정한다.
-- 바꾸려면 <leader>uc (Telescope colorscheme, 라이브 프리뷰) 로 고르면 그대로 저장된다.
--
-- lazy = false 인 이유: lazy 로 두면 플러그인이 rtp 에 없어서 :colorscheme 자동완성
-- (= Telescope 피커 목록) 에 뜨지 않는다. colorscheme 플러그인은 적용 전까지
-- 하이라이트를 계산하지 않으므로 로드 비용은 무시할 수준이다 (총 3~4ms).

return {
  -- tokyonight-night / -storm / -moon / -day
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night", -- "storm" | "night" | "moon" | "day"
      on_highlights = function(hl)
        -- 기본 주석 #565f89 는 배경 대비가 2.76:1 뿐이라 눈이 아프다
        hl.Comment = { fg = "#8b96c4", italic = true }
      end,
    },
  },

  -- catppuccin-mocha / -macchiato / -frappe / -latte
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 900,
    opts = {
      flavour = "mocha",
      custom_highlights = function(colors)
        -- overlay0(#6c7086) → overlay2(#9399b2) 로 한 단계 밝게
        return { Comment = { fg = colors.overlay2, style = { "italic" } } }
      end,
    },
  },

  -- kanagawa-wave / -dragon / -lotus
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 900,
    opts = {
      commentStyle = { italic = true },
      overrides = function()
        -- fujiGray(#727169) 는 그럭저럭이지만 조금 더 올린다
        return { Comment = { fg = "#9b9a90", italic = true } }
      end,
    },
  },

  -- gruvbox-material (따뜻한 레트로 톤, 주석 대비 4.02:1)
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 900,
    init = function()
      vim.g.gruvbox_material_background = "medium" -- "hard" | "medium" | "soft"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
    end,
  },

  -- github_dark_default / github_dark_dimmed / github_dark_high_contrast
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 900,
    config = function()
      require("github-theme").setup({})
    end,
  },

  -- everforest (녹색 계열, 저채도 고대비)
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 900,
    config = function()
      require("everforest").setup({
        background = "medium", -- "hard" | "medium" | "soft"
        italics = true,
      })
    end,
  },
}
