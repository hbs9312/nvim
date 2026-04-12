vim.opt_local.suffixesadd:prepend({ ".js", ".jsx", ".ts", ".tsx", ".json", ".mjs", ".cjs" })
vim.opt_local.path:append({ "src", "." })
vim.opt_local.includeexpr = "v:lua.require('util.gf').includeexpr(v:fname)"
vim.opt_local.isfname:append("@-@")
