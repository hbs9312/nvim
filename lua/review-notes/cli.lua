-- review-notes/cli.lua
-- nvim 밖에서(주로 에이전트가) 노트를 읽고 닫는 통로.
--
--   cd <레포> && nvim -l ~/.config/nvim/lua/review-notes/cli.lua list --json
--
-- 사람이 쓰는 UI 는 nvim 안의 :ReviewNote* 커맨드다. 여기서 store.lua 를 그대로
-- require 하므로 경로 파생(레포 정체성 키)·저장 형식·락이 nvim 쪽과 항상 같다.
-- 셸 스크립트로 다시 구현하면 어긋나기 때문에 이 경로를 택했다.

-- nvim -l 은 사용자 설정을 읽지 않으므로 스크립트 위치에서 lua/ 를 직접 잡는다.
local script = (arg and arg[0]) or debug.getinfo(1, "S").source:sub(2)
local lua_dir = vim.fn.fnamemodify(script, ":p:h:h")
package.path = ("%s/?.lua;%s/?/init.lua;%s"):format(lua_dir, lua_dir, package.path)

local store = require("review-notes.store")

local USAGE = [[
review-notes CLI  (nvim -l <이 파일> <서브커맨드>)

  list [옵션]              노트 목록. 기본은 현재 브랜치의 미해결만
    --json                 원본 레코드를 JSON 배열로
    --file <path>          그 파일의 노트만 (절대/상대 경로 모두)
    --branch <name>        그 브랜치만
    --all-branches         브랜치 무관
    --include-resolved     resolve 된 것도 포함
  show <N...> [--json]     번호로 상세 (본문 전체)
  resolve <N...> [--off]   번호로 resolve 처리 (--off 면 미해결로 되돌림)
  path                     스토어 디렉터리
  md                       notes.md 경로 (사람이 읽는 미러, 쓰지 말 것)

노트 위치(lnum)는 마지막 저장 시점 기준이다. 코드가 밀렸을 수 있으니
snippet(기준줄)로 실제 위치를 다시 확인할 것.
]]

---@param msg string
local function die(msg)
  io.stderr:write("review-notes: " .. msg .. "\n")
  os.exit(1)
end

--- 인자를 플래그와 위치 인자로 나눈다.
---@param argv string[]
---@return table flags, string[] rest
local function parse(argv)
  local flags, rest = {}, {}
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--file" or a == "--branch" then
      i = i + 1
      if not argv[i] then
        die(a .. " 에 값이 필요합니다")
      end
      flags[a:sub(3)] = argv[i]
    elseif a:sub(1, 2) == "--" then
      flags[a:sub(3):gsub("%-", "_")] = true
    else
      rest[#rest + 1] = a
    end
    i = i + 1
  end
  return flags, rest
end

---@param note table
---@return string
local function range_label(note)
  if note.lnum == note.end_lnum then
    return ("L%d"):format(note.lnum)
  end
  return ("L%d-%d"):format(note.lnum, note.end_lnum)
end

---@param notes table[]
local function print_human(notes)
  if #notes == 0 then
    print("(해당하는 노트가 없습니다)")
    return
  end
  for _, n in ipairs(notes) do
    print(
      ("#%-4s %s %s:%s  [%s]"):format(
        tostring(n.number or "?"),
        n.resolved and "✓" or "●",
        n.path or "?",
        range_label(n),
        n.branch or "?"
      )
    )
    for _, line in ipairs(vim.split(n.text or "", "\n", { plain = true })) do
      print("     " .. line)
    end
    local snip = n.snippet and n.snippet[1]
    if snip and snip:gsub("%s", "") ~= "" then
      print("     기준줄: " .. vim.trim(snip))
    end
    print("")
  end
end

--- 번호 목록을 노트로. 못 찾은 번호도 함께 돌려준다.
---@param nums string[]
---@return table[] notes, string[] missing
local function by_numbers(nums)
  local want = {}
  for _, raw in ipairs(nums) do
    local num = tonumber((raw:gsub("^#", "")))
    if not num then
      die(("번호가 아닙니다: %s"):format(raw))
    end
    want[num] = true
  end
  local found, notes = {}, {}
  for _, n in ipairs(store.query({})) do
    if want[n.number] then
      notes[#notes + 1] = n
      found[n.number] = true
    end
  end
  local missing = {}
  for num in pairs(want) do
    if not found[num] then
      missing[#missing + 1] = "#" .. num
    end
  end
  table.sort(missing)
  table.sort(notes, function(a, b)
    return (a.number or 0) < (b.number or 0)
  end)
  return notes, missing
end

local cmds = {}

function cmds.list(flags)
  local filter = {}
  if not flags.all_branches then
    filter.branch = flags.branch or store.branch()
  elseif flags.branch then
    die("--branch 와 --all-branches 는 함께 쓸 수 없습니다")
  end
  if not flags.include_resolved then
    filter.resolved = false
  end
  if flags.file then
    -- 절대/상대 경로를 레포 상대경로로 맞춘다. 이미 상대경로면 그대로 쓴다.
    filter.path = store.rel_path(vim.fn.fnamemodify(flags.file, ":p")) or flags.file
  end

  local notes = store.query(filter)
  if flags.json then
    print(vim.json.encode(notes))
  else
    print_human(notes)
  end
end

function cmds.show(flags, rest)
  if #rest == 0 then
    die("번호가 필요합니다: show 3 7")
  end
  local notes, missing = by_numbers(rest)
  if flags.json then
    print(vim.json.encode(notes))
  else
    print_human(notes)
  end
  if #missing > 0 then
    io.stderr:write(("review-notes: 찾을 수 없는 번호: %s\n"):format(table.concat(missing, " ")))
  end
  if #notes == 0 then
    os.exit(1)
  end
end

function cmds.resolve(flags, rest)
  if #rest == 0 then
    die("번호가 필요합니다: resolve 3 7")
  end
  local target = not flags.off
  local notes, missing = by_numbers(rest)
  if #missing > 0 then
    io.stderr:write(("review-notes: 찾을 수 없는 번호: %s\n"):format(table.concat(missing, " ")))
  end
  if #notes == 0 then
    os.exit(1)
  end

  local ids, already = {}, {}
  for _, n in ipairs(notes) do
    if n.resolved == target then
      already[#already + 1] = "#" .. tostring(n.number)
    else
      ids[#ids + 1] = n.id
    end
  end

  local changed, err = store.update_many(ids, function(n)
    n.resolved = target
  end)
  if err then
    die(err)
  end

  local done = {}
  for _, n in ipairs(notes) do
    if n.resolved ~= target then
      done[#done + 1] = "#" .. tostring(n.number)
    end
  end
  if #done > 0 then
    print(
      ("%s: %s (%d건)"):format(target and "resolved" or "unresolved", table.concat(done, " "), changed)
    )
  end
  if #already > 0 then
    print(("이미 %s 상태: %s"):format(target and "resolve" or "미해결", table.concat(already, " ")))
  end
end

function cmds.path()
  local dir, err = store.dir()
  if not dir then
    die(err or "스토어 경로를 알 수 없습니다 (git 레포인지 확인)")
  end
  print(dir)
end

function cmds.md()
  local p = store.md_path()
  if not p then
    die("스토어 경로를 알 수 없습니다 (git 레포인지 확인)")
  end
  print(p)
end

----------------------------------------------------------------------

local argv = {}
for i = 1, #(arg or {}) do
  argv[i] = arg[i]
end

local flags, rest = parse(argv)
local sub = table.remove(rest, 1)

if not sub or sub == "help" or flags.help then
  print(USAGE)
  os.exit(sub and 0 or 1)
end
if not cmds[sub] then
  io.stderr:write(("review-notes: 모르는 서브커맨드: %s\n"):format(sub))
  print(USAGE)
  os.exit(1)
end
if not store.git_root() then
  die("git 레포가 아닙니다 (cwd: " .. vim.fn.getcwd() .. ")")
end

cmds[sub](flags, rest)
