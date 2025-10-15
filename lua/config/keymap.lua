local modes = { "n", "v", "x", "s", "o", "t" }
for _, mode in ipairs(modes) do
  vim.keymap.set(mode, "<Space>", "<Nop>", { silent = true })
end

---- Normal: [m 위로 / ]m 아래로
vim.keymap.set("n", "]m", ":m .+1<CR>==", { silent = true, noremap = true, desc = "Move line down" })
vim.keymap.set("n", "[m", ":m .-2<CR>==", { silent = true, noremap = true, desc = "Move line up" })

-- Visual: [m / ]m 로 블록 이동
vim.keymap.set("v", "]m", ":m '>+1<CR>gv=gv", { silent = true, noremap = true, desc = "Move block down" })
vim.keymap.set("v", "[m", ":m '<-2<CR>gv=gv", { silent = true, noremap = true, desc = "Move block up" })

-- 시스템 클립보드 복사/붙여넣기
vim.keymap.set("v", "<leader>cc", '"+y', { silent = true, noremap = true, desc = "Copy to clipboard" })
vim.keymap.set("v", "<leader>cp", '"+p', { silent = true, noremap = true, desc = "Copy to clipboard" })

vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "파일 저장" })
vim.keymap.set("n", "<leader>q", "<cmd>qa!<CR>", { desc = "전체 종료" })
vim.keymap.set("n", "<leader>cw", "<cmd>q<CR>", { desc = "윈도우 종료" })
-- 윈도우 이동

vim.keymap.set("n", "<leader>h", "<C-w>h")
vim.keymap.set("n", "<leader>j", "<C-w>j")
vim.keymap.set("n", "<leader>k", "<C-w>k")
vim.keymap.set("n", "<leader>l", "<C-w>l")

-- 버퍼
vim.keymap.set("n", "<leader>bd", ":bd!<CR>", { desc = "버퍼 종료(강제)" })

-- 화면 분할
vim.keymap.set("n", "<leader>ss", "<C-w>s")
vim.keymap.set("n", "<leader>sv", "<C-w>v")

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
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Diagnostics filter (Trouble)" })
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
vim.keymap.set("n", "sp", "<cmd>Lspsaga peek_definition<CR>", { silent = true })
vim.keymap.set("n", "st", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true })
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true })
vim.keymap.set("n", "sd", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to Denifition" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lspsaga",
  callback = function()
    vim.keymap.set("n", "<CR>", function()
      vim.cmd("Lspsaga goto_definition")
    end, { buffer = true, desc = "Open Denifition File" })
  end,
})

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

-- bufferline
vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>")
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>")
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    require("bufferline").go_to_buffer(i, true)
  end)
end

-- gitsigns용 단축키
vim.keymap.set("n", "]c", function()
  if vim.wo.diff then return "]c" end
  require("gitsigns").next_hunk()
end, { desc = "다음 변경 영역" })

vim.keymap.set("n", "[c", function()
  if vim.wo.diff then return "[c" end
  require("gitsigns").prev_hunk()
end, { desc = "이전 변경 영역" })

vim.keymap.set("n", "<leader>gs", function()
  require("gitsigns").stage_hunk()
end, { desc = "현재 hunk stage" })

vim.keymap.set("n", "<leader>gr", function()
  require("gitsigns").reset_hunk()
end, { desc = "현재 hunk reset" })

vim.keymap.set("n", "<leader>gp", function()
  require("gitsigns").preview_hunk()
end, { desc = "hunk 미리보기" })

vim.keymap.set("n", "<leader>gb", function()
  require("gitsigns").blame_line({ full = true })
end, { desc = "현재 줄 blame 보기" })

-- diffview용 단축키
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "현재 파일 diff 보기" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewOpen HEAD~1<CR>", { desc = "이전 커밋과 diff 보기" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "현재 파일 히스토리 보기" })
vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "Diffview 닫기" })

-- dab : Debug Adapter Protocol
local dap = require("dap")
vim.keymap.set("n", "<F5>", dap.continue)
vim.keymap.set("n", "<F10>", dap.step_over)
vim.keymap.set("n", "<F11>", dap.step_into)
vim.keymap.set("n", "<F12>", dap.step_out)
vim.keymap.set("n", "<leader>bp", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>B", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end)
