-- keymaps.lua
-- Assumes mapleader = " " (space). If not set elsewhere, this sets it.
local map = vim.keymap.set
local silent = { silent = true, noremap = true }

-- Clear search highlight on Esc
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

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
      { "<leader>a", group = "AI (Claude Code)" },
      { "<leader>n", group = "Notes (Review)" },
      { "<leader>o", group = "Octo (GitHub)" },
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
map("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { noremap = true, desc = "Go to definition" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { silent = true, noremap = true, desc = "Peek definition" })
map("n", "gt", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true, noremap = true, desc = "Peek type definition" })
map("n", "ca", "<cmd>Lspsaga code_action<CR>", { silent = true, noremap = true, desc = "Code action" })
map("n", "gr", "<cmd>Lspsaga finder<CR>", { silent = true, noremap = true, desc = "Go to references" })
map("n", "gi", "<cmd>Lspsaga finder imp<CR>", { silent = true, noremap = true, desc = "Go to implementation" })
map("n", "gn", "<cmd>Lspsaga rename<CR>", { silent = true, noremap = true, desc = "Rename symbol" })

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
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })

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
map("n", "<leader>gD", "<cmd>DiffviewOpen HEAD^!<CR>", { desc = "Diffview latest commit" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history" })
map("n", "<leader>gl", "<cmd>DiffviewFileHistory<CR>", { desc = "Repository history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<CR>", { desc = "Repository history" })
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
-- AI (Claude Code) -- coder/claudecode.nvim
----------------------------------------------------------------------
map("n", "<leader>ac", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<CR>", { desc = "Focus Claude terminal" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<CR>", { desc = "Resume Claude session" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<CR>", { desc = "Continue Claude session" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", { desc = "Select Claude model" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", { desc = "Add current buffer to context" })
map("v", "<leader>as", "<cmd>ClaudeCodeSend<CR>", { desc = "Send selection to Claude" })
map("n", "<leader>ax", "<cmd>ClaudeCodeStop<CR>", { desc = "Stop Claude server" })
map("n", "<leader>ai", "<cmd>ClaudeCodeStatus<CR>", { desc = "Claude server status" })

-- Diff review: 수락은 :w, 거부는 :q 로도 가능
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", { desc = "Accept diff" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", { desc = "Deny diff" })
map("n", "<leader>aq", "<cmd>ClaudeCodeCloseAllDiffs<CR>", { desc = "Close all pending diffs" })

-- 파일 탐색기에서 <leader>as 로 커서 위 파일을 @mention 컨텍스트에 추가
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "neo-tree", "NvimTree", "oil", "minifiles", "netrw" },
  callback = function(ev)
    map("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>", {
      buffer = ev.buf,
      desc = "Add file to Claude context",
    })
  end,
})

----------------------------------------------------------------------
-- Notes (Review) -- 로컬 전용 리뷰 메모, PR 에는 올라가지 않음
----------------------------------------------------------------------
-- Normal 은 커서 줄, Visual 은 선택 범위에 메모를 남긴다.
-- Octo 리뷰 diff 버퍼에서도 동작하며, 거기서는 <localleader>cn 도 쓸 수 있다.
map("n", "<leader>nn", "<cmd>ReviewNote<CR>", { desc = "Add note (current line)" })
map("x", "<leader>nn", ":ReviewNote<CR>", { desc = "Add note (selection)" })
-- 목록 안에서 <Space> 로 여러 개를 고르면 <C-r> resolve / <C-x> 삭제가 한 번에 적용된다.
map("n", "<leader>nl", "<cmd>ReviewNoteList<CR>", { desc = "List notes (current branch)" })
map("n", "<leader>nf", "<cmd>ReviewNoteList file<CR>", { desc = "List notes (current file)" })
map("n", "<leader>nv", "<cmd>ReviewNoteView<CR>", { desc = "Toggle cursor popup" })
map("n", "<leader>nr", "<cmd>ReviewNoteResolve<CR>", { desc = "Toggle resolve at cursor" })
map("n", "<leader>ne", "<cmd>ReviewNoteEdit<CR>", { desc = "Edit note at cursor" })
map("n", "<leader>nd", "<cmd>ReviewNoteDelete<CR>", { desc = "Delete note at cursor" })
map("n", "<leader>no", "<cmd>ReviewNoteOpen<CR>", { desc = "Open notes.md (agent mirror)" })
map("n", "<leader>ni", "<cmd>ReviewNoteInfo<CR>", { desc = "Show store path & counts" })

----------------------------------------------------------------------
-- Octo (GitHub PR/Issue)
----------------------------------------------------------------------
local function octo_current_org()
  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then cwd = vim.fn.getcwd() end
  local out = vim.fn.system({ "git", "-C", cwd, "remote", "get-url", "origin" })
  if vim.v.shell_error ~= 0 then return nil end
  -- git@github.com:ORG/REPO(.git)  or  https://github.com/ORG/REPO(.git)
  return vim.trim(out):match("github%.com[:/]([^/]+)/")
end

local function octo_search(query)
  return function()
    local org = octo_current_org() or "soymedia"
    vim.cmd(("Octo search %s org:%s"):format(query, org))
  end
end

map("n", "<leader>op", "<cmd>Octo pr list<CR>", { desc = "PR list (current repo)" })
map("n", "<leader>or", octo_search("is:pr is:open review-requested:@me"), { desc = "PRs to review" })
map("n", "<leader>om", octo_search("is:pr is:open author:@me"), { desc = "My PRs" })
map("n", "<leader>ot", octo_search("is:pr is:open -author:@me -review:approved"), { desc = "Team PRs needing review" })






