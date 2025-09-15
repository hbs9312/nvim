return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      json = { " prettierd" },
      lua = { "stylua" },
      c = { "clangd" },
      html = { "prettierd" }
    },
    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 500,
    }
  }
}
