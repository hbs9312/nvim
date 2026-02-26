# nvim

Neovim 개인 설정 (WSL2 환경)

## 구조

```
~/.config/nvim/
├── init.lua                 # 진입점 → require("config")
├── lazy-lock.json           # 플러그인 버전 잠금
├── lua/
│   ├── config/
│   │   ├── init.lua         # leader 키 설정, 모듈 로드
│   │   ├── lazy.lua         # lazy.nvim 부트스트랩
│   │   ├── keymap.lua       # 키 바인딩
│   │   └── opt.lua          # Vim 옵션 및 autocmd
│   └── plugins/             # 개별 플러그인 설정 (lazy.nvim spec)
```

## 기본 설정

- **플러그인 매니저**: lazy.nvim (자동 부트스트랩)
- **Leader 키**: `Space`
- **들여쓰기**: 2칸 스페이스
- **줄 번호**: 상대 번호 + 절대 번호
- **fcitx5 한영 전환**: Insert 모드 나갈 때 / 포커스 시 자동 영문 전환
- **파일 변경 감지**: 500ms 폴링으로 외부 변경 자동 반영
- **터미널 자동 Insert**: 터미널 윈도우 진입 시 자동 Insert 모드

## 플러그인

| 카테고리 | 플러그인 | 설명 |
|---------|---------|------|
| **LSP** | neovim/nvim-lspconfig | LSP 클라이언트 설정 |
| | williamboman/mason-lspconfig | LSP 서버 자동 설치 |
| | nvimdev/lspsaga.nvim | LSP UI (peek, code action 등) |
| **자동완성** | hrsh7th/nvim-cmp | 코드 자동완성 |
| | windwp/nvim-autopairs | 괄호/따옴표 자동 페어링 |
| **검색** | nvim-telescope/telescope.nvim | 파일/텍스트 퍼지 검색 |
| **파일 탐색** | nvim-neo-tree/neo-tree.nvim | 파일 탐색기 |
| **UI** | akinsho/bufferline.nvim | 탭바 (버퍼 표시) |
| | nvim-lualine/lualine.nvim | 상태바 |
| | folke/which-key.nvim | 키 바인딩 힌트 |
| **코드 품질** | nvim-treesitter/nvim-treesitter | 코드 하이라이팅/파싱 |
| | stevearc/conform.nvim | 코드 포매터 |
| | mfussenegger/nvim-lint | Linting |
| | folke/trouble.nvim | Diagnostics 목록 |
| **Git** | lewis6991/gitsigns.nvim | 라인 단위 git diff 표시 |
| | sindrets/diffview.nvim | 파일 단위 git diff viewer |
| **디버깅** | mfussenegger/nvim-dap | Debug Adapter Protocol |
| **AI** | greggh/claude-code.nvim | Claude Code 터미널 통합 |
| | coder/nvim-claude-code | Claude Code 확장 기능 |
| **기타** | ahmedkhalf/project.nvim | 프로젝트 루트 인식 |
| | iamcco/markdown-preview.nvim | 마크다운 미리보기 |

## 키맵

`<leader>` = `Space`. 대부분 Normal 모드 기준.

### 파일/세션

| 키 | 설명 |
|----|------|
| `<leader>fs` | 파일 저장 |
| `<leader>qq` | 전체 종료 |

### 검색 (Telescope)

| 키 | 설명 |
|----|------|
| `<leader>ff` | 파일 검색 |
| `<leader>fg` | 텍스트 검색 (live grep) |
| `<leader>fb` | 버퍼 목록 |
| `<leader>fh` | 도움말 태그 |
| `<leader>fr` | 최근 파일 (프로젝트 내) |

### 윈도우

| 키 | 설명 |
|----|------|
| `<leader>wc` | 윈도우 닫기 |
| `<leader>ws` | 수평 분할 |
| `<leader>wv` | 수직 분할 |
| `<leader>wh/j/k/l` | 윈도우 이동 |
| `<C-h/j/k/l>` | 윈도우 이동 (Normal/Terminal) |

### 버퍼

| 키 | 설명 |
|----|------|
| `<Tab>` | 다음 버퍼 |
| `<S-Tab>` | 이전 버퍼 |
| `<leader>1~9` | 버퍼 번호로 이동 |
| `<leader>bd` | 버퍼 삭제 (윈도우 유지) |

### 파일 탐색기 (Neo-tree)

| 키 | 설명 |
|----|------|
| `<leader>e` | Neo-tree 토글/포커스 |

### Git

| 키 | 설명 |
|----|------|
| `]c` / `[c` | 다음/이전 hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gc` | Git commits (Telescope) |
| `<leader>gC` | 버퍼 commits (Telescope) |
| `<leader>gd` | Diffview 열기 |
| `<leader>gD` | Diffview (이전 커밋) |
| `<leader>gh` | 파일 히스토리 |
| `<leader>gq` | Diffview 닫기 |

### LSP / 코드

| 키 | 설명 |
|----|------|
| `sp` | Peek definition |
| `st` | Peek type definition |
| `sd` | Go to definition |
| `<leader>ca` | Code action |
| `<leader>cs` | Symbols (Trouble) |
| `<leader>cl` | LSP list (Trouble) |

### Diagnostics (Trouble)

| 키 | 설명 |
|----|------|
| `<leader>xx` | 전체 diagnostics |
| `<leader>xX` | 현재 버퍼 diagnostics |
| `<leader>xd` | Diagnostics float |
| `<leader>xL` | Location list |
| `<leader>xQ` | Quickfix list |

### 디버깅 (DAP)

| 키 | 설명 |
|----|------|
| `<F5>` | Continue |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>db` | 브레이크포인트 토글 |
| `<leader>dB` | 조건부 브레이크포인트 |

### 라인 이동

| 키 | 설명 |
|----|------|
| `]m` / `[m` | 줄/블록 아래/위로 이동 (Normal/Visual) |

### 클립보드 (Visual 모드)

| 키 | 설명 |
|----|------|
| `<leader>y` | 시스템 클립보드로 복사 |
| `<leader>p` | 시스템 클립보드에서 붙여넣기 |

### AI (Claude Code)

| 키 | 설명 |
|----|------|
| `<leader>aa` | Claude Code 열기 |
| `<leader>ae` | Claude 외부 터미널 |
| `<leader>as` | Claude 상태 |
| `<leader>ar` | Claude 서버 재시작 |
| `<leader>ax` | Claude 서버 중지 |
| `<leader>am` | 파일/선택 영역을 Claude에 전송 |
| `<leader>af` | Claude 터미널 포커스 (선택 영역 전송) |

