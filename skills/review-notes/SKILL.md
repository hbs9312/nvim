---
name: review-notes
description: "This skill should be used when the user refers to local review notes made in Neovim — \"리뷰 노트\", \"리뷰 메모\", \"노트 #3 고쳐줘\", \"노트 목록\", \"메모 처리해줘\", \"review note\", \"fix review notes\", or invokes /review-notes. These notes live OUTSIDE the repo (~/.hbrness/review-notes/<owner>/<repo>/) so they cannot be found by searching the project — read and resolve them through the CLI documented here. Use it to list pending notes, fix the code they point at, and close them by number."
---

# Review Notes (nvim 로컬 리뷰 메모)

사용자가 Neovim 에서 코드 라인에 붙여둔 **로컬 전용 리뷰 메모**다. 자기가 올린 PR 을 자기가 리뷰하면서 "고쳤으면 하는 것" 을 적어둔 것이고, 그 목록을 지금 처리하는 게 이 스킬의 일이다.

- GitHub 에 올라가지 않는다. PR 코멘트나 Octo 의 pending 코멘트와는 다른 것이다.
- 각 노트에 **`#N` 고정 번호**가 있다. 레포 단위로 증가하고 삭제해도 재사용하지 않는다. 사용자와의 대화는 이 번호로 한다.
- 저장소는 **레포 밖**(`~/.hbrness/review-notes/<owner>/<repo>/`)에 있다. 프로젝트를 grep 해도 안 나온다. 아래 CLI 가 유일한 접근 경로다.

## CLI

반드시 대상 레포 안에서(cwd 가 워크트리 안) 실행한다. 경로는 `git remote` 의 `owner/repo` 에서 파생되므로 워크트리가 여러 개여도 같은 저장소를 본다.

```bash
RN="nvim -l ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lua/review-notes/cli.lua"

$RN list --json                                  # 현재 브랜치의 미해결 노트 (기본)
$RN list --json --file src/foo.ts                # 그 파일만 (절대/상대 경로 모두)
$RN list --json --all-branches --include-resolved # 전부
$RN show 3 7 --json                              # 번호로 상세
$RN resolve 3 7                                  # 실제로 고친 것만 닫는다
$RN resolve --off 3                              # 미해결로 되돌리기
$RN path                                         # 저장 디렉터리
$RN md                                           # notes.md 경로 (읽기 전용 미러)
```

`git 레포가 아닙니다` 가 나오면 cwd 를 레포 안으로 옮긴 뒤 다시 실행한다. `nvim` 이 PATH 에 있어야 한다.

### 레코드 필드

`list --json` 은 다음 형태의 배열을 준다.

| 필드 | 뜻 |
|------|-----|
| `number` | `#N` 고정 번호. 사용자와 이 번호로 소통한다 |
| `path` | 레포 상대경로 |
| `lnum`, `end_lnum` | 노트가 붙은 라인 범위 (1-indexed). **마지막 저장 시점 기준** |
| `snippet[1]` | 노트를 적을 때의 **기준줄 내용**. 위치가 밀렸을 때 이걸로 찾는다 |
| `text` | 메모 본문 = 지시 내용. 여러 줄일 수 있다 |
| `branch`, `sha` | 노트를 적은 브랜치와 그때의 HEAD |
| `resolved` | 처리 여부. 기본 목록에는 `false` 만 나온다 |
| `id`, `created_at`, `updated_at` | 내부용 |

## 작업 순서

1. `$RN list --json` 으로 노트를 받는다. 사용자가 번호를 지정했으면 `$RN show <번호들> --json`.
2. 각 노트에서 `path` 를 열고 **`lnum` 을 그대로 믿지 말고 `snippet[1]` 로 실제 위치를 확인한다.** 노트를 적은 뒤 코드가 밀렸을 수 있다. 기준줄이 그 자리에 없으면 파일 안에서 그 내용을 검색해 위치를 다시 잡는다. 그래도 없으면 그 노트는 건드리지 말고 "위치를 못 찾았다" 로 보고한다.
3. `text` 가 지시다. 고친다.
4. **실제로 고친 것만** `$RN resolve <번호들>` 로 닫는다.
5. 번호별로 한 줄씩 보고한다.

```
#3 고침 — foo() 진입부에 인자 검증 추가 (nil 이면 에러 반환)
#7 고침 — error() 대신 컨텍스트 붙여 재던지기
#9 안 함 — 기준줄을 찾을 수 없음 (그 함수가 삭제된 듯). 확인 필요
```

## 지켜야 할 것

- **`notes.md` 를 쓰지 마라.** 저장할 때마다 재생성되는 미러라서 쓴 내용이 사라진다. 읽기만 한다.
- **`notes.json` 을 직접 편집하지 마라.** 파일 락·번호 관리·저장 형식이 CLI(그리고 nvim) 쪽에 있다. 직접 쓰면 다른 쪽 쓰기와 충돌해 유실된다. 반드시 `$RN resolve` 를 쓴다.
- **고쳤는지 확신이 없으면 resolve 하지 마라.** 열어두고 보고하는 쪽이 낫다. 되돌리려면 사용자가 `--off` 를 쓰거나 nvim 에서 다시 열 수 있지만, 놓친 항목이 조용히 닫히는 게 더 나쁘다.
- 사용자가 "이것만" 이라고 번호를 집었으면 그 번호만 처리한다. 목록 전체를 임의로 손대지 않는다.
- 다른 브랜치에서 적은 노트(`branch` 가 현재와 다름)는 지금 작업트리와 어긋날 수 있다. 기본 목록에는 안 나오고, `--all-branches` 로만 보인다. 굳이 처리할 때는 브랜치가 다르다는 걸 보고에 적는다.

## 참고: 사용자가 직접 지목하는 경로

사용자는 nvim 에서 `<leader>na`(커서 위치) 또는 목록에서 `<Space>` 선택 후 `<C-y>` 로 노트를 프롬프트에 직접 밀어넣을 수 있다. 그때는 `@파일#L10-20` 멘션과 노트 본문이 이미 들어와 있으니 CLI 로 다시 조회할 필요가 없다 — 번호만 맞춰서 처리하고, 닫을 때만 `$RN resolve` 를 쓴다.
