return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      mode = "buffers",
      numbers = "ordinal",
      diagnostics = "nvim_lsp",
      show_buffer_close_icons = false,
      show_close_icon = false,
      separator_style = "slant"
    }
  }
}
