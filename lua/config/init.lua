vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.lazy")
require("config.keymap")
require("config.opt")

-- 로컬 전용 리뷰 메모 (PR 에는 올라가지 않음)
require("review-notes").setup({})


