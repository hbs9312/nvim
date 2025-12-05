return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "ts_ls", "pyright", "clang-format" },
    })

    require("mason-lspconfig").setup_handlers({
      function(server)
        require("lspconfig")[server].setup({})
      end,
    })
  end,
}
