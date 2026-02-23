return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local sorters = require("telescope.sorters")

    -- 빈 프롬프트일 때 결과를 숨기는 sorter
    local file_sorter = sorters.get_fzy_sorter()
    file_sorter.discard = false
    local original_scoring = file_sorter.scoring_function
    file_sorter.scoring_function = function(self, prompt, line)
      if not prompt or prompt == "" then
        return -1
      end
      return original_scoring(self, prompt, line)
    end

    require("telescope").setup({
      defaults = {
        file_ignore_patterns = { "node_modules" },
      },
      pickers = {
        find_files = {
          sorter = file_sorter,
        },
      },
    })
  end,
}


