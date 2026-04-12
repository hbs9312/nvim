vim.opt_local.suffixesadd:prepend({ ".py", ".pyi" })
vim.opt_local.path:append({ "src", "." })
vim.opt_local.includeexpr = "v:lua.require('util.gf').includeexpr(v:fname)"
