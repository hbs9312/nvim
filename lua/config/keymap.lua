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
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fr", function()
	local cwd = vim.loop.cwd()

	telescope.oldfiles({
		cwd = cwd,
		only_cwd = true,
		prompt_title = "Recent Project Files",
	})
end, { desc = "Find recent files (project only)" })

vim.keymap.set("n", "<leader>gc", require("telescope.builtin").git_commits, { desc = "Git Commits" })
vim.keymap.set("n", "<leader>gb", require("telescope.builtin").git_bcommits, { desc = "Git Blame Commits" })


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
	local neotree_win = nil

	-- 모든 윈도우를 확인해서 Neotree가 열려 있는지 체크
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		if ft == "neo-tree" then
			neotree_win = win
		end
	end

	if neotree_win == nil then
		vim.cmd("Neotree toggle")
	elseif neotree_win == vim.api.nvim_get_current_win() then
		vim.cmd("Neotree toggle")
	else
		vim.api.nvim_set_current_win(neotree_win)
	end
end, { desc = "Neotree 열고/닫기 토글" })
