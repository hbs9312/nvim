# nvim
nvim 플러그인 설정

## 설정 파일 위치
~/.config/nvim

## 진입점
~/.config/nvim/init.lua

## 루트 폴더 경로
~/.config/nvim/lua

## 플러그인 매니저
lazy.nvim

## 플러그인
- windwp/nvim-autopairs
- willamboman/mason-lspconfig : lsp-install
- nvim-neo-tree/neo-tree : 파일 탐색기 
- nvim-telescope/telescope : 파일 검색
- hrsh7th/nvim-cmp : 코드 자동완성
- nvim-treesitter/nvim-treesitter : 코드 하이라이팅
- folke/trouble.nvim : diagnostics
- stevearc/conform.nvim : code formatter
- nvimdev/lspsaga : LSP UI plugin
- windwp/nvim-ts-autotag : html 태그 등 닫는 태그 자동완성
- mfussenegger/nvim-lint : Linting 
- akinsho/bufferline.nvim : 탭바 플러그인. buffer 표시.
- lewis6991/gitsigns.nvim : 라인 단위 git diff 표시. 
- sindrets/diffview.nvim : 파일 단위 git diff viewer.
- ahmedkhalf/project.nvim : 프로젝트 루트 인식 플러그인 

## 참고사항

- `<leader>` 키는 **Space**로 설정되어 있습니다
- 대부분의 명령은 Normal 모드 기준입니다
- Visual 모드 전용 명령은 별도 표시했습니다
