return {
  "nvimdev/lspsaga.nvim",
  event = "LspAttach",
  opts = {
    beacon = {
      enable = false,
    }
  },
  dependecies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  }
}
