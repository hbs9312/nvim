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
│   ├── plugins/             # 개별 플러그인 설정 (lazy.nvim spec)
│   └── review-notes/        # 로컬 전용 리뷰 메모 (플러그인 아님, 자체 모듈)
│       └── cli.lua          # nvim 밖(에이전트)에서 부르는 통로 — nvim -l 로 실행
└── skills/
    └── review-notes/        # Claude 스킬 (~/.claude/skills 로 심볼릭 링크)
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
| | pwntester/octo.nvim | GitHub PR/이슈 리뷰 |
| **디버깅** | mfussenegger/nvim-dap | Debug Adapter Protocol |
| **AI** | coder/claudecode.nvim | Claude Code IDE 통합 (WebSocket MCP) |
| **기타** | ahmedkhalf/project.nvim | 프로젝트 루트 인식 |
| | iamcco/markdown-preview.nvim | 마크다운 미리보기 (브라우저) |
| | MeanderingProgrammer/render-markdown.nvim | 마크다운 버퍼 내 렌더링 |

플러그인이 아닌 자체 모듈: `lua/review-notes/` (아래 [Notes (Review)](#notes-review--로컬-전용-리뷰-메모) 참고).

## 키맵

`<leader>` = `Space`, `<localleader>` = `\`. 대부분 Normal 모드 기준.

### 기본

| 키 | 설명 |
|----|------|
| `<Esc>` | 검색 하이라이트 해제 (`nohlsearch`) |
| `<Space>` | leader 전용 — n/v/x/s/o 에서 기본 동작 제거 |

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
| `<C-w>H/J/K/L` | 윈도우 위치 이동 (Terminal 모드) |

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
| `<leader>e` | Neo-tree 토글 |
| `<leader>as` | 커서 위 파일을 Claude 컨텍스트에 추가 (탐색기 버퍼 전용) |

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
| `<leader>gD` | 최신 커밋 diff |
| `<leader>gh` | 파일 히스토리 |
| `<leader>gl` | 저장소 히스토리 |
| `<leader>gH` | 저장소 히스토리 |
| `<leader>gq` | Diffview 닫기 |

### GitHub PR/이슈 (Octo)

| 키 | 설명 |
|----|------|
| `<leader>op` | 현재 레포 PR 목록 |
| `<leader>or` | 내게 리뷰 요청된 PR (조직 전체) |
| `<leader>om` | 내가 올린 PR (조직 전체) |
| `<leader>ot` | 팀 PR — 내 것 제외, 아직 approve 안 된 것 |

조직은 `origin` remote 의 `github.com/<ORG>/` 에서 뽑고, 못 찾으면 `soymedia` 로 폴백한다.

### LSP / 코드 (lspsaga)

| 키 | 설명 |
|----|------|
| `gd` | 정의로 이동 |
| `gp` | 정의 미리보기 (peek) |
| `gt` | 타입 정의 미리보기 |
| `gr` | 참조 찾기 (finder) |
| `gi` | 구현 찾기 |
| `gn` | 심볼 이름 변경 |
| `ca` | Code action |
| `<leader>cs` | Symbols (Trouble) |
| `<leader>cl` | LSP list (Trouble) |

lspsaga 창(finder/peek) 안에서 `<CR>` 은 해당 정의 파일을 연다.

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

`coder/claudecode.nvim` — 공식 VS Code 확장과 동일한 WebSocket MCP 프로토콜로 붙기 때문에,
열려 있는 파일과 선택 영역이 실시간으로 Claude에 전달되고 변경 제안은 nvim 네이티브 diff로 리뷰한다.

| 키 | 설명 |
|----|------|
| `<leader>ac` | Claude 터미널 토글 |
| `<leader>af` | Claude 터미널 포커스 |
| `<leader>ar` | 세션 이어받기 (`--resume`) |
| `<leader>aC` | 직전 세션 계속 (`--continue`) |
| `<leader>am` | 모델 선택 |
| `<leader>ab` | 현재 버퍼를 컨텍스트에 추가 |
| `<leader>as` | 선택 영역 전송 (Visual) / 파일 추가 (neo-tree 등 탐색기) |
| `<leader>ai` | 서버 상태 |
| `<leader>ax` | 서버 중지 |

Diff 리뷰:

| 키 | 설명 |
|----|------|
| `<leader>aa` | diff 수락 (`:w` 도 동일) |
| `<leader>ad` | diff 거부 (`:q` 도 동일) |
| `<leader>aq` | 대기 중인 diff 전체 닫기 |

diff는 수락 전에 Claude의 제안을 직접 수정할 수 있다.
터미널은 snacks.nvim 없이 `native` 프로바이더(nvim 내장 터미널, 우측 35% 분할)를 사용한다.

### Notes (Review) — 로컬 전용 리뷰 메모

`lua/review-notes/` 로컬 모듈. **PR 에는 절대 올라가지 않는** 메모를 코드 라인에 붙여두고,
나중에 고칠 때(또는 에이전트가 고칠 때) 그 목록을 쓴다. 자기가 올린 PR 을 자기가 리뷰하는 용도.

Octo 리뷰 diff 버퍼에서도 그대로 동작하고(`<localleader>cn` 도 가능), Octo 없이 일반 버퍼에서도 쓸 수 있다.
Octo 의 pending 코멘트는 GitHub 서버에 저장되는 초안이라 성격이 다르다 — 이쪽은 로컬에만 남는다.

| 키 | 설명 |
|----|------|
| `<leader>nn` | 메모 추가 (Normal=커서 줄, Visual=선택 범위) |
| `<leader>nl` | 목록 — 현재 브랜치 (Telescope) |
| `<leader>nf` | 목록 — **현재 파일** (전체 브랜치) |
| `<leader>na` | 커서 위치 메모를 **에이전트에게 지목** (Claude 터미널) |
| `<leader>nA` | 같은 프롬프트를 **클립보드로만** (별도 세션·다른 도구용) |
| `<leader>nv` | 커서 팝업 on/off |
| `<leader>nr` | 커서 위치 메모 resolve 토글 |
| `<leader>ne` | 커서 위치 메모 수정 |
| `<leader>nd` | 커서 위치 메모 삭제 |
| `<leader>no` | `notes.md` 열기 (에이전트가 읽는 파일) |
| `<leader>ni` | 저장 경로·개수 확인 |
| `<localleader>cn` (`\cn`) | 메모 추가 — Octo 리뷰 diff 버퍼 전용 (Normal/Visual) |

메모 입력창에서는 `:w` 저장, `:q` 또는 `<C-c>` 취소.

번호로 다루기 — 에이전트와 주고받을 때 쓴다:

| 커맨드 | 설명 |
|----|------|
| `:ReviewNoteAgent` | 커서 위치 메모를 에이전트에게 지목 |
| `:ReviewNoteAgent 3 7` | `#3` `#7` 을 지목 (`#` 붙여도 됨) |
| `:ReviewNoteAgent! 3` | Claude 터미널을 건드리지 않고 클립보드로만 |
| `:ReviewNoteGoto 7` | `#7` 위치로 점프 |
| `:ReviewNoteResolve 7` | `#7` resolve 토글 (인자 없으면 커서 위치) |

#### 에이전트에게 지목하기

`<leader>na` (커서) 또는 목록에서 `<Space>` 로 고른 뒤 `<C-y>`. Claude 프롬프트에 이렇게 들어간다:

```
@lua/foo.lua#L10-20        ← 위치는 claudecode 의 @멘션으로 (파일을 직접 읽게)
@lua/bar.lua#L42

아래 로컬 리뷰 노트를 고쳐줘. (nvim review-notes 메모 — PR 코멘트가 아니라 로컬에만 있는 것)
고친 뒤 처리한 노트를 #번호로 알려줘. 안 고친 게 있으면 이유도 번호와 함께.

#3 lua/foo.lua:L10-20
  이 함수는 인자를 검증하지 않는다.
  (기준줄: local function foo(a, b))

#7 lua/bar.lua:L42
  에러 뿌리기 말고 컨텍스트 달아서 다시 던지기
```

- 위치는 `claudecode.send_at_mention` 으로, 지시문·본문은 터미널 프롬프트 텍스트로 보낸다. 멘션이 내부에서 50ms 디바운스로 배치 전송되므로 텍스트는 `mention_flush_ms`(200ms) 뒤에 보내 순서가 뒤집히지 않게 한다
- **Claude 가 안 떠 있어도 된다.** 멘션이 큐에 쌓이고 터미널이 뜨며, 연결되면(최대 `connect_timeout_ms` 15초) 프롬프트가 들어간다
- claudecode 가 없거나 끝내 붙지 않으면 **같은 프롬프트를 클립보드(`+`)로** 넘긴다. codex·웹 등 다른 도구에 붙여넣으면 된다
- 노트는 **번호 오름차순**으로 정렬해 보낸다. 멘션·본문·알림·에이전트 답신 순서가 어긋나지 않는다
- 같은 라인 범위에 노트가 여러 개면 멘션은 한 번만 (본문은 각각)
- 다른 브랜치에서 적어 현재 작업트리에 없는 파일은 멘션을 건너뛰고 본문만 보낸다 (경고로 알린다)
- 커서 경로는 extmark 로 움직인 **현재 위치**를 보낸다. 디스크 값은 마지막 저장 시점 기준이다
- 답신으로 번호를 받으면 `:ReviewNoteResolve 7` 로 닫는다 (nvim 이 자동 resolve 하지는 않는다)

#### nvim 밖의 세션에서 쓰기

Claude 가 nvim 안의 터미널이 아니라 별도 세션에서 돌 때는 세 갈래다.

| 상황 | 방법 |
|------|------|
| 같은 머신, `claude --ide` 또는 `/ide` 로 붙인 세션 | `<leader>na` 그대로. `@멘션`은 WebSocket 으로 그 세션에 꽂히고, 본문은 nvim 이 쓸 터미널이 없으니 클립보드로 떨어진다 → `<C-v>` 붙여넣기 |
| 완전히 별도 세션 (다른 pane·워크트리) | 에이전트가 **CLI 로 직접 읽는다**. `review-notes` 스킬이 이 흐름을 담고 있다 |
| 다른 도구 (codex, 웹) | `<leader>nA` 로 프롬프트만 클립보드에 담아 붙여넣기 |

**에이전트용 CLI** — `nvim -l` 로 `store.lua` 를 그대로 재사용하므로 경로 파생·저장 형식·락이 nvim 쪽과 항상 같다 (셸로 다시 구현하면 어긋난다):

```bash
RN="nvim -l ~/.config/nvim/lua/review-notes/cli.lua"
cd <레포>                       # 스토어 키를 git remote 에서 뽑으므로 레포 안에서
$RN list --json                 # 현재 브랜치 미해결 (--file/--branch/--all-branches/--include-resolved)
$RN show 3 7 --json
$RN resolve 3 7                 # --off 면 미해결로
$RN path ; $RN md
```

**스킬** — `skills/review-notes/SKILL.md` (`~/.claude/skills/review-notes` 로 심볼릭 링크). 스토어가 레포 밖이라 에이전트가 프로젝트를 grep 해도 찾을 수 없으므로, 위치·CLI 사용법·작업 순서·금지사항을 스킬로 넘긴다. 핵심 규칙은 셋이다.

- `lnum` 을 그대로 믿지 말고 **기준줄(`snippet[1]`)로 위치를 재확인**한다 (노트 작성 후 코드가 밀렸을 수 있다)
- **실제로 고친 것만** `resolve` 하고, 나머지는 열어둔 채 이유를 번호와 함께 보고한다
- `notes.md`·`notes.json` 을 직접 쓰지 않는다 (미러는 재생성되고, 정공본은 락으로 보호된다)

**동시 쓰기** — 에이전트가 `resolve` 하는 동안 nvim 이 버퍼를 저장하면 서로의 쓰기를 덮을 수 있다(load→modify→write 전체 파일). 그래서 모든 쓰기를 `notes.json.lock` (O_EXCL, 10초 넘은 락은 탈취, 같은 프로세스 안에서는 재진입) 으로 직렬화한다. 읽기는 잠그지 않는다.

목록(`<leader>nl` / `<leader>nf`) 안에서:

| 키 | 설명 |
|----|------|
| `<Space>` (노멀) / `<Tab>` | 여러 개 고르기. insert 모드에서는 공백이 검색어라 `<Tab>` 을 쓴다 |
| `<C-a>` | 전체 고르기/해제 |
| `<C-y>` | **에이전트에게 지목** — 고른 것 전부 (목록은 닫힌다) |
| `<C-r>` | resolve 토글 — **고른 것 전부**에 적용 |
| `<C-x>` | 삭제 — **고른 것 전부**에 적용 |
| `<C-s>` | 스코프 순환 (현재 브랜치 → 현재 파일 전체 브랜치 → 전체) |
| `<C-f>` | 미해결/전체 필터 |

- 고른 게 없으면 커서 항목 하나만 처리한다
- `<C-r>` 은 고른 것들의 상태를 **하나로 맞춘다**. 하나라도 미해결이면 전부 resolve, 전부 resolved 면 전부 미해결로 (섞인 상태가 남지 않는다)
- 여러 개 삭제는 되돌릴 수 없으므로 번호를 보여주고 한 번 묻는다 (`메모 3개(#1 #4 #7)를 삭제합니다`)
- 여러 건을 처리해도 `notes.json` 은 한 번만 읽고 한 번만 쓴다 (`store.update_many` / `store.remove_many`)

동작 방식:

- 커서가 메모 범위에 들어가면 팝업이 뜨고, 벗어나면 사라진다. 같은 범위의 메모는 한 그룹으로 묶이고, 범위 라벨은 **위 테두리에 얹힌다** (`╭─ L1-10 · 2 notes ───╮`)
- 각 메모에 **`#N` 고정 번호**가 붙는다. 레포 단위로 증가하고 **삭제해도 재사용하지 않는다**(GitHub 이슈 번호와 같은 성질). 팝업·목록·`notes.md` 에 모두 표시되므로 에이전트에게 "노트 #7 고쳐줘" 로 지칭할 수 있다
- 팝업 **너비는 고정**(기본 50칸, `popup_width`)이다. 커서를 옮겨도 박스 폭이 들썩이지 않는다. 긴 메모는 표시 너비 기준으로 접히고(한글 2칸 계산), 공백 없는 긴 문장은 문자 단위로 강제 개행된다
- 팝업은 **커서를 따라다니지 않는다.** 창 오른쪽에 붙어, **범위의 시작 라인 높이에 고정**된다. 10-15 메모면 10번째 줄 옆이다
- **중첩된 범위는 각자의 시작 라인에 박스가 하나씩** 뜬다. 1-10 과 5-10 이 걸리면 1행 옆과 5행 옆에 따로. 박스가 겹칠 위치면 아래로 밀어내고, **라인 그룹끼리 테두리를 공유하지 않는다** (`BOX_GAP` 으로 사이 여백 조절)
- 범위 안에서 커서만 움직이는 동안에는 박스를 다시 그리지 않는다 (깜빡임 방지). 스크롤·창 크기 변경 시에는 위치를 다시 잡는다
- 시작 라인이 화면 위로 스크롤돼 사라지면 창 최상단에 붙는다. `wrap` 이 켜져 있어 위치는 `screenpos()` 로 계산한다
- 동시에 4개 박스까지 띄우고, 넘거나 창에 자리가 없으면 겹쳐 그리지 않고 마지막 박스에 `… N개 그룹 더` 를 붙인다
- `updatetime` 이 4000ms 라 `CursorHold` 대신 `CursorMoved`/`WinScrolled` + 120ms 디바운스를 쓴다 (전역 설정을 건드리지 않기 위해)
- 세션 중 편집은 extmark 가 따라가고, 외부 편집(에이전트가 파일을 고친 경우)은 저장된 **기준줄 내용**으로 ±40줄 범위를 재탐색한다. 못 찾으면 `!` 로 표시
- 버퍼를 저장하면 갱신된 위치가 디스크에 반영된다

저장 위치 — `~/.hbrness/review-notes/<owner>/<repo>/`:

- `notes.json` 이 정공본, `notes.md` 는 쓰기마다 재생성되는 에이전트용 미러 (브랜치 → 파일 순으로 그룹핑, `- [ ]`/`- [x]` 체크박스, 기준줄 포함)
- 키를 **레포 정체성**(git remote 의 `owner/repo`, 없으면 `--path-format=absolute --git-common-dir`)에서 뽑기 때문에 **워크트리 경로와 무관하게** 같은 스토어를 공유한다
- 브랜치는 파일 분리 기준이 아니라 레코드 필드다. 그래서 "브랜치 무관 파일별 조회"가 가능하다
- 레포 밖이라 프로젝트에 잡히지 않고 gitignore 도 불필요하다

