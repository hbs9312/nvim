return {
  'ahmedkhalf/project.nvim',
  config = function()
    local in_review_worktree = vim.fn.getcwd():find('/.claude/worktrees/reviews', 1, true) ~= nil

    require('project_nvim').setup({
      detection_methods = { 'pattern', 'lsp' },
      patterns = { '.git', 'package.json', 'Cargo.toml', 'go.mod' },
      silent_chdir = false,
      manual_mode = in_review_worktree,
    })

    -- telescope 연동
    require('telescope').load_extension('projects')
  end,
}
