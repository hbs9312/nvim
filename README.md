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

# Neovim 단축키 정리

## 기본 편집

### 라인/블록 이동
- `]m` - 현재 줄을 아래로 이동 (Normal)
- `[m` - 현재 줄을 위로 이동 (Normal)
- `]m` - 선택한 블록을 아래로 이동 (Visual)
- `[m` - 선택한 블록을 위로 이동 (Visual)

### 클립보드
- `<leader>cc` - 시스템 클립보드로 복사 (Visual)
- `<leader>cp` - 시스템 클립보드에서 붙여넣기 (Visual)

### 파일 및 윈도우 관리
- `<leader>w` - 파일 저장
- `<leader>q` - 전체 종료
- `<leader>cw` - 현재 윈도우 종료

### 윈도우 이동
- `<leader>h` - 왼쪽 윈도우로 이동
- `<leader>j` - 아래 윈도우로 이동
- `<leader>k` - 위 윈도우로 이동
- `<leader>l` - 오른쪽 윈도우로 이동

### 화면 분할
- `<leader>ss` - 수평 분할
- `<leader>sv` - 수직 분할

### 버퍼
- `<leader>bd` - 현재 버퍼 강제 종료

---

## Telescope

### 파일 검색
- `<leader>ff` - 파일 찾기
- `<leader>fg` - 파일 내용 검색 (live grep)
- `<leader>fb` - 열린 버퍼 목록
- `<leader>fh` - 도움말 태그 검색
- `<leader>fr` - 최근 파일 검색 (프로젝트 내)

### Git
- `<leader>gc` - Git 커밋 히스토리
- `<leader>gb` - 현재 파일의 Git blame 커밋

---

## Trouble.nvim

### Diagnostics
- `<leader>xx` - 진단 토글
- `<leader>xX` - 현재 버퍼 진단 필터
- `<leader>cs` - 심볼 목록
- `<leader>cl` - LSP 정의/참조 등
- `<leader>xL` - Location List
- `<leader>xQ` - Quickfix List

### 기타
- `<leader>d` - 플로팅 윈도우에서 진단 표시

---

## LSP Saga

### 코드 탐색
- `sp` - 정의 미리보기 (peek definition)
- `st` - 타입 정의 미리보기 (peek type definition)
- `sd` - 정의로 이동 (go to definition)
- `<CR>` - 정의 파일 열기 (LSP Saga 윈도우 내에서)

### 코드 액션
- `<leader>ca` - 코드 액션

---

## Neo-tree

- `<leader>e` - 파일 탐색기 열기/닫기/포커스

---

## BufferLine

### 버퍼 이동
- `<Tab>` - 다음 버퍼
- `<S-Tab>` - 이전 버퍼
- `<leader>1` ~ `<leader>9` - 1~9번 버퍼로 직접 이동

---

## Gitsigns

### Hunk 탐색
- `]c` - 다음 변경 영역
- `[c` - 이전 변경 영역

### Hunk 작업
- `<leader>gs` - 현재 hunk stage
- `<leader>gr` - 현재 hunk reset
- `<leader>gp` - hunk 미리보기
- `<leader>gb` - 현재 줄 blame 보기

---

## Diffview

- `<leader>gd` - 현재 파일 diff 보기
- `<leader>gD` - 이전 커밋과 diff 보기
- `<leader>gh` - 현재 파일 히스토리 보기
- `<leader>gq` - Diffview 닫기

---

## DAP (Debug Adapter Protocol)

### 디버깅 제어
- `<F5>` - 디버깅 계속/시작
- `<F10>` - Step Over
- `<F11>` - Step Into
- `<F12>` - Step Out

### 브레이크포인트
- `<leader>bp` - 브레이크포인트 토글
- `<leader>B` - 조건부 브레이크포인트 설정

---

## 참고사항

- `<leader>` 키는 Space로 설정되어 있습니다
- 대부분의 명령은 Normal 모드 기준입니다
- Visual 모드 전용 명령은 별도 표시했습니다재시도황각 단축키를 목록 말고 표로 정리해줘.네, 표 형식으로 다시 정리해드릴게요!
markdown# Neovim 단축키 정리

## 기본 편집

### 라인/블록 이동
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `]m` | Normal | 현재 줄을 아래로 이동 |
| `[m` | Normal | 현재 줄을 위로 이동 |
| `]m` | Visual | 선택한 블록을 아래로 이동 |
| `[m` | Visual | 선택한 블록을 위로 이동 |

### 클립보드
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>cc` | Visual | 시스템 클립보드로 복사 |
| `<leader>cp` | Visual | 시스템 클립보드에서 붙여넣기 |

### 파일 및 윈도우 관리
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>w` | Normal | 파일 저장 |
| `<leader>q` | Normal | 전체 종료 |
| `<leader>cw` | Normal | 현재 윈도우 종료 |

### 윈도우 이동
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>h` | Normal | 왼쪽 윈도우로 이동 |
| `<leader>j` | Normal | 아래 윈도우로 이동 |
| `<leader>k` | Normal | 위 윈도우로 이동 |
| `<leader>l` | Normal | 오른쪽 윈도우로 이동 |

### 화면 분할
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>ss` | Normal | 수평 분할 |
| `<leader>sv` | Normal | 수직 분할 |

### 버퍼
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>bd` | Normal | 현재 버퍼 강제 종료 |

---

## Telescope

### 파일 검색
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>ff` | Normal | 파일 찾기 |
| `<leader>fg` | Normal | 파일 내용 검색 (live grep) |
| `<leader>fb` | Normal | 열린 버퍼 목록 |
| `<leader>fh` | Normal | 도움말 태그 검색 |
| `<leader>fr` | Normal | 최근 파일 검색 (프로젝트 내) |

### Git
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>gc` | Normal | Git 커밋 히스토리 |
| `<leader>gb` | Normal | 현재 파일의 Git blame 커밋 |

---

## Trouble.nvim

| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>xx` | Normal | 진단 토글 |
| `<leader>xX` | Normal | 현재 버퍼 진단 필터 |
| `<leader>cs` | Normal | 심볼 목록 |
| `<leader>cl` | Normal | LSP 정의/참조 등 |
| `<leader>xL` | Normal | Location List |
| `<leader>xQ` | Normal | Quickfix List |
| `<leader>d` | Normal | 플로팅 윈도우에서 진단 표시 |

---

## LSP Saga

### 코드 탐색
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `sp` | Normal | 정의 미리보기 (peek definition) |
| `st` | Normal | 타입 정의 미리보기 (peek type definition) |
| `sd` | Normal | 정의로 이동 (go to definition) |
| `<CR>` | Normal | 정의 파일 열기 (LSP Saga 윈도우 내) |

### 코드 액션
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>ca` | Normal | 코드 액션 |

---

## Neo-tree

| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>e` | Normal | 파일 탐색기 열기/닫기/포커스 |

---

## BufferLine

| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<Tab>` | Normal | 다음 버퍼 |
| `<S-Tab>` | Normal | 이전 버퍼 |
| `<leader>1` ~ `<leader>9` | Normal | 1~9번 버퍼로 직접 이동 |

---

## Gitsigns

### Hunk 탐색
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `]c` | Normal | 다음 변경 영역 |
| `[c` | Normal | 이전 변경 영역 |

### Hunk 작업
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>gs` | Normal | 현재 hunk stage |
| `<leader>gr` | Normal | 현재 hunk reset |
| `<leader>gp` | Normal | hunk 미리보기 |
| `<leader>gb` | Normal | 현재 줄 blame 보기 |

---

## Diffview

| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>gd` | Normal | 현재 파일 diff 보기 |
| `<leader>gD` | Normal | 이전 커밋과 diff 보기 |
| `<leader>gh` | Normal | 현재 파일 히스토리 보기 |
| `<leader>gq` | Normal | Diffview 닫기 |

---

## DAP (Debug Adapter Protocol)

### 디버깅 제어
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<F5>` | Normal | 디버깅 계속/시작 |
| `<F10>` | Normal | Step Over |
| `<F11>` | Normal | Step Into |
| `<F12>` | Normal | Step Out |

### 브레이크포인트
| 단축키 | 모드 | 설명 |
|--------|------|------|
| `<leader>bp` | Normal | 브레이크포인트 토글 |
| `<leader>B` | Normal | 조건부 브레이크포인트 설정 |

---

## 참고사항

- `<leader>` 키는 **Space**로 설정되어 있습니다
- 대부분의 명령은 Normal 모드 기준입니다
- Visual 모드 전용 명령은 별도 표시했습니다
