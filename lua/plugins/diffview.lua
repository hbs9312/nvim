local function show_full_diff()
  vim.opt_local.foldenable = false
  vim.opt_local.foldlevel = 99
  vim.opt_local.foldcolumn = "0"
end

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    hooks = {
      diff_buf_read = function()
        show_full_diff()
      end,
      diff_buf_win_enter = function()
        show_full_diff()
      end,
    },
  },
}
