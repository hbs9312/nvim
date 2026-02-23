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
      separator_style = "slant",
      custom_filter = function(buf)
        return vim.bo[buf].buftype ~= "terminal"
      end,
      get_element_icon = function(element)
        local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
        if devicons_ok then
          local icon, hl = devicons.get_icon(element.name, nil, { default = false })
          if icon then
            return icon, hl
          end
        end
        return "", nil
      end
    }
  }
}


