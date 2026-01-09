vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
-- 들여쓰기
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.o.signcolumn = "yes"

-- 연속키
vim.o.timeoutlen = 500
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  command = "checktime",
})

vim.api.nvim_create_autocmd({"FocusGained", "BufEnter"}, {
  pattern = "*",
  command = "checktime"
})
