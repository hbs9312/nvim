return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "InsertLeave" },
  config = function()
    require("lint").linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      callback = function()
        require("lint").try_lint()
      end
    })

    require("lint").linters.eslint_d = {
      cmd = "eslint_d",
      args = {
        "--stdin",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_name(0)
        end
      },
      stream = "stderr",
      ingnore_exsitcode = true,
      parser = require("lint.parser").from_errorformat("%f:%l:%c: %m"),
      {
        source = "eslint_d",
        severity = vim.diagnostic.severity.WARN
      }

    }
  end,
}
