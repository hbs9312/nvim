-- keymaps.lua
-- Assumes mapleader = " " (space). If not set elsewhere, this sets it.
local map = vim.keymap.set
local silent = { silent = true, noremap = true }

-- Disable <Space> default behavior in common modes (leader key remains functional)
do
  local modes = { "n", "v", "x", "s", "o" }
  for _, mode in ipairs(modes) do
    map(mode, "<Space>", "<Nop>", { silent = true })
  end
end

-- which-key grouping (prevents "+N keymaps" and improves discoverability)
do
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>f", group = "Find/File" },
      { "<leader>g", group = "Git" },
      { "<leader>w", group = "Window" },
      { "<leader>b", group = "Buffer" },
      { "<leader>c", group = "Code/LSP" },
      { "<leader>x", group = "Diagnostics/Trouble" },
      { "<leader>d", group = "Debug (DAP)" },
      { "<leader>y", group = "Clipboard" },
      { "<leader>e", group = "Explorer" },
      { "<leader>a", group = "AI (Claude)" },
      { "<leader>1", group = "Go to buffer (1~9)" }, -- 대표 라벨
    })
  end
end

----------------------------------------------------------------------
-- Move lines / blocks
----------------------------------------------------------------------
-- Normal: [m up / ]m down
map("n", "]m", ":m .+1<CR>==", vim.tbl_extend("force", silent, { desc = "Move line down" }))
map("n", "[m", ":m .-2<CR>==", vim.tbl_extend("force", silent, { desc = "Move line up" }))

-- Visual: [m / ]m move selection
map("v", "]m", ":m '>+1<CR>gv=gv", vim.tbl_extend("force", silent, { desc = "Move block down" }))
map("v", "[m", ":m '<-2<CR>gv=gv", vim.tbl_extend("force", silent, { desc = "Move block up" }))

----------------------------------------------------------------------
-- File / session
----------------------------------------------------------------------
map("n", "<leader>fs", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa!<CR>", { desc = "Quit all" })

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
map("n", "<leader>wc", "<cmd>q<CR>", { desc = "Close window" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })

map("n", "<leader>wh", "<C-w>h", { desc = "Go left window" })
map("n", "<leader>wj", "<C-w>j", { desc = "Go down window" })
map("n", "<leader>wk", "<C-w>k", { desc = "Go up window" })
map("n", "<leader>wl", "<C-w>l", { desc = "Go right window" })

----------------------------------------------------------------------
-- Buffer
----------------------------------------------------------------------
map("n", "<leader>bd", function()
  local buf = vim.api.nvim_get_current_buf()
  -- ignore scratch buffer
  if vim.bo[buf].buftype ~= "" or (vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified) then
    return
  end
  local function is_normal_buf(b)
    return vim.fn.buflisted(b) == 1
      and vim.bo[b].buftype == ""
      and b ~= buf
  end
  -- try alternate buffer first
  local alt = vim.fn.bufnr("#")
  if alt > 0 and is_normal_buf(alt) then
    vim.api.nvim_set_current_buf(alt)
  else
    -- find any other normal buffer
    local found = false
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if is_normal_buf(b) then
        vim.api.nvim_set_current_buf(b)
        found = true
        break
      end
    end
    if not found then
      vim.cmd("enew")
      vim.bo.bufhidden = "wipe"
    end
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end, { desc = "Force delete buffer (keep window)" })

----------------------------------------------------------------------
-- Clipboard (system clipboard)
----------------------------------------------------------------------
map("v", "<leader>y", '"+y', vim.tbl_extend("force", silent, { desc = "Yank to clipboard" }))
map("v", "<leader>p", '"+p', vim.tbl_extend("force", silent, { desc = "Paste from clipboard" }))

----------------------------------------------------------------------
-- Telescope (Find)
----------------------------------------------------------------------
do
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then
    map("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
    map("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
    map("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
    map("n", "<leader>fh", telescope.help_tags, { desc = "Help tags" })
    map("n", "<leader>fr", function()
      telescope.oldfiles({
        cwd = vim.loop.cwd(),
        only_cwd = true,
        prompt_title = "Recent Project Files",
      })
    end, { desc = "Recent files (project)" })

    -- Git (Telescope)
    map("n", "<leader>gc", telescope.git_commits, { desc = "Git commits" })
    map("n", "<leader>gC", telescope.git_bcommits, { desc = "Buffer commits" })
  end
end

----------------------------------------------------------------------
-- Trouble (Diagnostics/Trouble)
----------------------------------------------------------------------
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Diagnostics (buf only)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list (Trouble)" })

map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map(
  "n",
  "<leader>cl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP list (Trouble)" }
)

-- Show diagnostics float (moved under x for consistency)
map("n", "<leader>xd", function()
  vim.diagnostic.open_float(nil, { focus = false, border = "rounded" })
end, { desc = "Show diagnostics (float)" })

----------------------------------------------------------------------
-- lspsaga
----------------------------------------------------------------------
map("n", "sp", "<cmd>Lspsaga peek_definition<CR>", { silent = true, noremap = true, desc = "Peek definition" })
map("n", "st", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true, noremap = true, desc = "Peek type definition" })
map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true, noremap = true, desc = "Code action" })
map("n", "sd", "<cmd>Lspsaga goto_definition<CR>", { noremap = true, desc = "Go to definition" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lspsaga",
  callback = function()
    map("n", "<CR>", function()
      vim.cmd("Lspsaga goto_definition")
    end, { buffer = true, desc = "Open definition file" })
  end,
})

----------------------------------------------------------------------
-- Neo-tree (Explorer)
----------------------------------------------------------------------
map("n", "<leader>e", function()
  local neotree_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    if ft == "neo-tree" then
      neotree_win = win
      break
    end
  end

  if neotree_win == nil then
    vim.cmd("Neotree toggle")
  elseif neotree_win == vim.api.nvim_get_current_win() then
    vim.cmd("Neotree toggle")
  else
    vim.api.nvim_set_current_win(neotree_win)
  end
end, { desc = "Toggle Neo-tree" })

----------------------------------------------------------------------
-- Bufferline
----------------------------------------------------------------------
map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { noremap = true, silent = true, desc = "Prev buffer" })

for i = 1, 9 do
  map("n", "<leader>" .. i, function()
    local ok, bufferline = pcall(require, "bufferline")
    if ok then
      bufferline.go_to_buffer(i, true)
    end
  end, { desc = "which_key_ignore" }) -- 그룹 라벨만 보이도록 숨김
end

----------------------------------------------------------------------
-- Git: Gitsigns
----------------------------------------------------------------------
map("n", "]c", function()
  if vim.wo.diff then
    vim.cmd("normal! ]c")
    return
  end
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.next_hunk() end
end, { desc = "Next hunk" })

map("n", "[c", function()
  if vim.wo.diff then
    vim.cmd("normal! [c")
    return
  end
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.prev_hunk() end
end, { desc = "Previous hunk" })

map("n", "<leader>gs", function()
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.stage_hunk() end
end, { desc = "Stage hunk" })

map("n", "<leader>gr", function()
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.reset_hunk() end
end, { desc = "Reset hunk" })

map("n", "<leader>gp", function()
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.preview_hunk() end
end, { desc = "Preview hunk" })

map("n", "<leader>gb", function()
  local ok, gs = pcall(require, "gitsigns")
  if ok then gs.blame_line({ full = true }) end
end, { desc = "Blame line" })

----------------------------------------------------------------------
-- Git: Diffview
----------------------------------------------------------------------
map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Diffview open" })
map("n", "<leader>gD", "<cmd>DiffviewOpen HEAD~1<CR>", { desc = "Diffview prev commit" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history" })
map("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "Diffview close" })

----------------------------------------------------------------------
-- Debug Adapter Protocol (DAP)
----------------------------------------------------------------------
do
  local ok, dap = pcall(require, "dap")
  if ok then
    map("n", "<F5>", dap.continue, { desc = "DAP continue" })
    map("n", "<F10>", dap.step_over, { desc = "DAP step over" })
    map("n", "<F11>", dap.step_into, { desc = "DAP step into" })
    map("n", "<F12>", dap.step_out, { desc = "DAP step out" })

    map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    map("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Conditional breakpoint" })
  end
end

----------------------------------------------------------------------
-- Window navigation (Normal + Terminal)
----------------------------------------------------------------------
local function wincmd(dir)
  return function()
    vim.cmd("wincmd " .. dir)
    if vim.bo.buftype == "terminal" then
      vim.cmd("startinsert")
    end
  end
end

map("n", "<C-h>", wincmd("h"), { desc = "Go left window" })
map("n", "<C-j>", wincmd("j"), { desc = "Go down window" })
map("n", "<C-k>", wincmd("k"), { desc = "Go up window" })
map("n", "<C-l>", wincmd("l"), { desc = "Go right window" })

map("t", "<C-h>", function() vim.cmd("stopinsert") wincmd("h")() end, { desc = "Go left window" })
map("t", "<C-j>", function() vim.cmd("stopinsert") wincmd("j")() end, { desc = "Go down window" })
map("t", "<C-k>", function() vim.cmd("stopinsert") wincmd("k")() end, { desc = "Go up window" })
map("t", "<C-l>", function() vim.cmd("stopinsert") wincmd("l")() end, { desc = "Go right window" })

----------------------------------------------------------------------
-- Terminal mode: window position move
----------------------------------------------------------------------
map("t", "<C-w>H", "<C-\\><C-n><C-w>Hi", { desc = "Move window left" })
map("t", "<C-w>J", "<C-\\><C-n><C-w>Ji", { desc = "Move window down" })
map("t", "<C-w>K", "<C-\\><C-n><C-w>Ki", { desc = "Move window up" })
map("t", "<C-w>L", "<C-\\><C-n><C-w>Li", { desc = "Move window right" })

----------------------------------------------------------------------
-- AI (Claude Code)
----------------------------------------------------------------------
map("n", "<leader>aa", "<cmd>ClaudeCode<CR>", { desc = "Open Claude Code" })
map("n", "<leader>ae", "<cmd>ClaudeCode external<CR>", { desc = "Claude external terminal" })
map("n", "<leader>as", "<cmd>ClaudeCodeStatus<CR>", { desc = "Claude status" })
map("n", "<leader>ar", "<cmd>ClaudeCodeRestart<CR>", { desc = "Restart Claude server" })
map("n", "<leader>ax", "<cmd>ClaudeCodeStop<CR>", { desc = "Stop Claude server" })
map("n", "<leader>am", "<cmd>ClaudeAtMention<CR>", { desc = "Send file to Claude (@mention)" })
map("v", "<leader>am", "<cmd>ClaudeAtMention<CR>", { desc = "Send selection to Claude (@mention)" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<CR>", { desc = "Focus Claude terminal" })
map("x", "<leader>af", function()
  -- Capture visual selection and send notification while still in visual mode
  local ok, sel = pcall(require, "claude-code.tools.selection")
  if ok and sel._current then
    local server = require("claude-code.server")
    pcall(server.send_notification, "selection_changed", {
      text = sel._current.text,
      filePath = sel._current.filePath,
      fileUrl = sel._current.fileUrl,
      selection = sel._current.selection,
    })
  end
  -- Exit visual mode and focus Claude terminal
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  require("claude-code").focus_terminal()
end, { desc = "Send selection & focus Claude" })





