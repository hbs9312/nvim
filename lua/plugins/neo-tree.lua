return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    -- { "3rd/image.nvim", opts= {}},
    {
      "s1n7ax/nvim-window-picker",
      version = "2.*",
      config = function()
        require("window-picker").setup({
          filter_rules = {
            include_current_win = false,
            autoselect_one = true,
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify" },
              buftype = { "terminal", "quickfix" },
            },
          },
        })
      end,
    },
  },
  lazy = false,
  config = function()
    require("neo-tree").setup({
      window = {
        mappings = {
          ["<space>"] = "none",
          ["@"] = {
            function(state)
              local node = state.tree:get_node()
              if node.type == "file" or node.type == "directory" then
                require("claude-code").at_mention(node:get_id())
              end
            end,
            desc = "Send to Claude CLI (@mention)",
          },
        }
      },
      close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
      open_files_using_relative_paths = false,
      sort_case_insensitive = false,                                     -- used when sorting files and directories in the tree
      sort_function = nil,                                               -- use a custom function for sorting files and directories in the tree
      filesystem = {
        use_libuv_file_watcher = true,                                   -- It may not work in WSL
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        filtered_items = {
          visible = true,
          never_show = { ".git" }
        }
      },
    })

    -- 외부 프로세스 변경 포함 git 상태 주기적 리프레시 (2초)
    local timer = vim.uv.new_timer()
    timer:start(2000, 2000, vim.schedule_wrap(function()
      local ok, manager = pcall(require, "neo-tree.sources.manager")
      if ok then
        manager.refresh("filesystem")
      end
    end))
  end,
}


