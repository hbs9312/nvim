local modes = { "n", "v", "x", "s", "o", "t" }
for _, mode in ipairs(modes) do
  vim.keymap.set(mode, "<Space>", "<Nop>", { silent = true })
end

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc="파일 저장" })
vim.keymap.set("n", "<leader>q", ":qa!<CR>", { desc = "전체 종료" })
vim.keymap.set("n", "<leader>c", ":q<CR>", { desc = "윈도우 종료"})
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
