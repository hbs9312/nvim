return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "ts_ls", "pyright"},
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
        },
      },
    })

    vim.lsp.config("ts_ls", {})
    vim.lsp.config("pyright", {})


    vim.lsp.enable({ "lua_ls", "ts_ls", "pyright" })

--     require("mason-lspconfig").setup_handlers({
--       function(server)
--         require("lspconfig")[server].setup({})
--       end,
--     })
  end,
}
