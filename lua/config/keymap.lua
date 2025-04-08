local modes = { "n", "v", "x", "s", "o", "t" }
for _, mode in ipairs(modes) do
  vim.keymap.set(mode, "<Space>", "<Nop>", { silent = true })
end

vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "파일 저장" })
vim.keymap.set("n", "<leader>q", "<cmd>qa!<CR>", { desc = "전체 종료" })
vim.keymap.set("n", "<leader>c", "<cmd>q<CR>", { desc = "윈도우 종료" })
-- 윈도우 이동
vim.keymap.set("n", "<leader>h", "<C-w>h")
vim.keymap.set("n", "<leader>j", "<C-w>j")
vim.keymap.set("n", "<leader>k", "<C-w>k")
vim.keymap.set("n", "<leader>l", "<C-w>l")
-- 화면 분할
vim.keymap.set("n", "<leader>s", "<C-w>s")
vim.keymap.set("n", "<leader>v", "<C-w>v")
-- telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
-- tourble.nvim
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
vim.keymap.set("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Denifitions / references / ... (Trouble)" })
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- show Diagnostics
vim.keymap.set("n", "<leader>d", function()
  vim.diagnostic.open_float(nil, { focus = false, border = "rounded" })
end, { desc = "Show diagnostics in floating window" })

-- lspsaga
vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", { silent = true })
vim.keymap.set("n", "gt", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true })
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true })

-- neotree
vim.keymap.set("n", "<leader>e", function()
  local neotree_open = false

  -- 모든 윈도우를 확인해서 Neotree가 열려 있는지 체크
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("neo%-tree") then
      neotree_open = true
      break
    end
  end

  if neotree_open then
    vim.cmd("Neotree close")
  else
    vim.cmd("Neotree toggle")
  end
end, { desc = "Neotree 열고/닫기 토글" })
