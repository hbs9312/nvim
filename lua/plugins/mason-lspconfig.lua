return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "ts_ls", "pyright", "tailwindcss"},
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
        },
      },
    })

    vim.lsp.config("ts_ls", {})
    vim.lsp.config("pyright", {
      before_init = function(_, config)
        if not config.root_dir then
          return
        end
        local venv = config.root_dir .. "/.venv"
        if vim.fn.isdirectory(venv) == 1 then
          config.settings = config.settings or {}
          config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
            pythonPath = venv .. "/bin/python",
            venvPath = config.root_dir,
            venv = ".venv",
          })
        end
      end,
    })
    vim.lsp.config("tailwindcss", {})


    vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "tailwindcss" })

--     require("mason-lspconfig").setup_handlers({
--       function(server)
--         require("lspconfig")[server].setup({})
--       end,
--     })
  end,
}
