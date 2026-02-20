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

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  command = "checktime"
})

local function fcitx_to_en()
  vim.fn.system("fcitx5-remote -c")
end

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = fcitx_to_en
})

local uv = vim.uv or vim.loop
local timer

local function check_visible_buffers_all_tabs()
  local seen = {}

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)

      -- 중복 방지
      if not seen[buf] then
        seen[buf] = true

        -- 파일 버퍼만 체크 (terminal, help 등 제외)
        local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local name = vim.api.nvim_buf_get_name(buf)

        if bt == "" and name ~= "" then
          vim.cmd("silent! checktime " .. buf)
        end
      end
    end
  end
end

local function start_poll(ms)
  if timer then return end
  timer = uv.new_timer()
  timer:start(ms, ms, vim.schedule_wrap(function()
    check_visible_buffers_all_tabs()
  end))
end

local function stop_poll()
  if not timer then return end
  timer:stop()
  timer:close()
  timer = nil
end

start_poll(500) -- 1초 (원하면 500ms까지 낮출 수 있음)
