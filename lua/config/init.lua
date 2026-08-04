vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.lazy")
-- lazy 뒤에 온다: 플러그인 테마들이 rtp 에 올라온 다음 적용해야 한다
require("config.colorscheme").setup()
require("config.keymap")
require("config.opt")

-- 로컬 전용 리뷰 메모 (PR 에는 올라가지 않음)
require("review-notes").setup({})


