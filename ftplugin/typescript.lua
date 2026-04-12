vim.opt_local.suffixesadd:prepend({ ".ts", ".tsx", ".js", ".jsx", ".json", ".d.ts" })
vim.opt_local.path:append({ "src", "." })
vim.opt_local.includeexpr = "v:lua.require('util.gf').includeexpr(v:fname)"
vim.opt_local.isfname:append("@-@")
