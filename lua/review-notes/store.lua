-- review-notes/store.lua
-- 영속 저장. 정공본은 notes.json, 에이전트용 미러는 notes.md.
--
-- 저장 위치는 워크트리 경로가 아니라 "레포 정체성" 으로 키를 잡는다.
-- 그래서 같은 레포의 워크트리 여러 개가 동일한 파일을 공유한다.
--   1순위: git remote 의 owner/repo
--   2순위: realpath(git rev-parse --git-common-dir) 슬러그  (remote 없는 레포)
local M = {}

local ROOT = vim.fn.expand("~/.hbrness/review-notes")

---@param args string[]
---@param dir string
---@return string[]|nil
local function git(args, dir)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

---@param args string[]
---@param dir string
---@return string|nil
local function git1(args, dir)
  local out = git(args, dir)
  if not out or not out[1] or out[1] == "" then
    return nil
  end
  return (out[1]:gsub("%s+$", ""))
end

--- git 명령을 실행할 기준 디렉터리.
--- octo:// 같은 가상 버퍼는 경로가 없으므로 cwd 로 폴백한다.
---@return string
function M.ctx_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and not name:match("^%a[%w+.-]*://") then
    local dir = vim.fn.fnamemodify(name, ":p:h")
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return vim.fn.getcwd()
end

---@param dir? string
---@return string|nil
function M.git_root(dir)
  return git1({ "rev-parse", "--show-toplevel" }, dir or M.ctx_dir())
end

--- 현재 워크트리의 브랜치. detached HEAD 면 "detached@<short-sha>".
---@param dir? string
---@return string
function M.branch(dir)
  dir = dir or M.ctx_dir()
  local b = git1({ "branch", "--show-current" }, dir)
  if b and b ~= "" then
    return b
  end
  local sha = git1({ "rev-parse", "--short", "HEAD" }, dir)
  return sha and ("detached@" .. sha) or "unknown"
end

---@param dir? string
---@return string|nil
function M.head_sha(dir)
  return git1({ "rev-parse", "--short", "HEAD" }, dir or M.ctx_dir())
end

--- 모든 워크트리가 공유하는 gitdir 의 절대 실경로.
---
--- 주의: `rev-parse --git-common-dir` 은 명령 cwd 기준 **상대경로**를 낼 수 있다
--- (레포 루트에서 ".git", 하위 디렉터리에서 "../.git"). 그래서
--- --path-format=absolute 를 쓰고, 이를 지원하지 않는 git(< 2.31)에서는
--- 기준 디렉터리에 직접 붙여 해석한다.
---@param dir? string
---@return string|nil
function M.common_dir(dir)
  dir = dir or M.ctx_dir()
  local abs = git1({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, dir)
  if not abs then
    local rel = git1({ "rev-parse", "--git-common-dir" }, dir)
    if not rel then
      return nil
    end
    abs = rel:sub(1, 1) == "/" and rel or (dir .. "/" .. rel)
  end
  return vim.uv.fs_realpath(abs) or abs
end

--- remote URL 에서 owner/repo 추출. ssh/https/scp 형식 모두 처리.
---@param dir string
---@return string|nil
local function remote_slug(dir)
  local remotes = git({ "remote" }, dir)
  if not remotes then
    return nil
  end
  -- origin 우선, 없으면 첫 remote
  local pick
  for _, r in ipairs(remotes) do
    if r == "origin" then
      pick = r
      break
    end
    pick = pick or (r ~= "" and r or nil)
  end
  if not pick then
    return nil
  end
  local url = git1({ "remote", "get-url", pick }, dir)
  if not url then
    return nil
  end
  url = url:gsub("%.git$", "")
  -- git@host:owner/repo | ssh://host/owner/repo | https://host/owner/repo
  local owner, repo = url:match("[:/]([^/:]+)/([^/]+)$")
  if owner and repo and owner ~= "" and repo ~= "" then
    return owner .. "/" .. repo
  end
  return nil
end

--- 워크트리 경로와 무관한 레포 식별 키.
---@param dir? string
---@return string|nil key, string|nil err
function M.repo_key(dir)
  dir = dir or M.ctx_dir()
  if not M.git_root(dir) then
    return nil, "git 레포가 아닙니다"
  end
  local slug = remote_slug(dir)
  if slug then
    return slug
  end
  -- remote 가 없으면 공용 gitdir 의 실제 경로로 키를 만든다.
  -- 링크 워크트리에서도 메인 레포의 .git 으로 수렴하므로 동일 키가 나온다.
  local common = M.common_dir(dir)
  if not common then
    return nil, "git-common-dir 을 확인할 수 없습니다"
  end
  local slugged = common:gsub("/%.git/?$", ""):gsub("/+$", ""):gsub("[/\\]", "-")
  return "_local/" .. slugged
end

---@param dir? string
---@return string|nil
function M.dir(dir)
  local key = M.repo_key(dir)
  if not key then
    return nil
  end
  return ROOT .. "/" .. key
end

---@param dir? string
---@return string|nil
function M.json_path(dir)
  local d = M.dir(dir)
  return d and (d .. "/notes.json") or nil
end

---@param dir? string
---@return string|nil
function M.md_path(dir)
  local d = M.dir(dir)
  return d and (d .. "/notes.md") or nil
end

----------------------------------------------------------------------
-- 파일 락
--
-- notes.json 은 여러 주체가 함께 쓴다. 워크트리별 nvim 인스턴스, 그리고
-- cli.lua 를 통해 들어오는 에이전트. read-modify-write 사이에 남의 쓰기가
-- 끼면 조용히 덮어써지므로(예: 에이전트의 resolve 가 nvim 의 위치 저장에 지워짐)
-- 쓰기 경로 전체를 자문 락으로 감싼다.
--
-- O_EXCL 로 잡고, 프로세스가 죽어 남겨진 락은 mtime 으로 뺏는다.
----------------------------------------------------------------------

local LOCK_NAME = "notes.json.lock"
--- 락을 기다리는 최대 시간. 넘으면 쓰지 않고 실패로 돌려준다.
local LOCK_TIMEOUT_MS = 2000
--- 이만큼 오래된 락은 죽은 프로세스가 남긴 것으로 보고 뺏는다.
local LOCK_STALE_MS = 10000
local LOCK_RETRY_MS = 20
--- 같은 프로세스 안에서의 재진입 깊이. load() 가 save() 를 부르는 경로가 있다.
local lock_depth = 0

---@param dir string
---@return integer|nil fd, string|nil err
local function lock_acquire(dir)
  local path = dir .. "/" .. LOCK_NAME
  local waited = 0
  while true do
    -- "wx" = O_WRONLY|O_CREAT|O_EXCL. 이미 있으면 실패한다.
    local fd = vim.uv.fs_open(path, "wx", tonumber("600", 8))
    if fd then
      pcall(vim.uv.fs_write, fd, tostring(vim.uv.os_getpid()))
      return fd
    end
    local st = vim.uv.fs_stat(path)
    if st and st.mtime and (os.time() - st.mtime.sec) * 1000 > LOCK_STALE_MS then
      pcall(vim.uv.fs_unlink, path)
    elseif waited >= LOCK_TIMEOUT_MS then
      return nil, ("%s 락을 얻지 못했습니다 (%s)"):format(LOCK_NAME, path)
    else
      vim.uv.sleep(LOCK_RETRY_MS)
      waited = waited + LOCK_RETRY_MS
    end
  end
end

--- 쓰기 경로를 감싼다. 반환값은 fn 의 앞 두 개(ok/err 관례)를 그대로 넘긴다.
--- 락을 못 얻거나 fn 이 죽으면 fail_value 와 에러 메시지를 돌려준다.
---@generic T
---@param fn fun(): T, string|nil
---@param fail_value any  락 실패 시 첫 반환값 (호출자의 실패 관례에 맞춘다)
---@return any, string|nil
local function with_lock(fn, fail_value)
  if lock_depth > 0 then
    return fn() -- 이미 이 프로세스가 쥐고 있다
  end
  local dir = M.dir()
  if not dir then
    return fn() -- 스토어 경로를 모르면 어차피 저장 단계에서 실패한다
  end
  if vim.fn.isdirectory(dir) == 0 and vim.fn.mkdir(dir, "p") == 0 then
    return fail_value, "디렉터리를 만들 수 없습니다: " .. dir
  end

  local fd, err = lock_acquire(dir)
  if not fd then
    -- 락 없이 밀어붙이지 않는다. 조용히 덮어쓰는 것보다 실패가 낫다.
    return fail_value, err
  end
  lock_depth = 1
  local ok, a, b = pcall(fn)
  lock_depth = 0
  pcall(vim.uv.fs_close, fd)
  pcall(vim.uv.fs_unlink, dir .. "/" .. LOCK_NAME)
  if not ok then
    return fail_value, tostring(a)
  end
  return a, b
end

--- 절대경로를 레포 상대경로로. 레포 밖이면 nil.
---@param abs string
---@param dir? string
---@return string|nil
function M.rel_path(abs, dir)
  local root = M.git_root(dir)
  if not root then
    return nil
  end
  local real = vim.uv.fs_realpath(abs) or abs
  local real_root = vim.uv.fs_realpath(root) or root
  if real == real_root then
    return nil
  end
  local prefix = real_root:gsub("/+$", "") .. "/"
  if real:sub(1, #prefix) ~= prefix then
    return nil
  end
  return real:sub(#prefix + 1)
end

---@return table
local function empty()
  return { version = 1, next_number = 1, notes = {} }
end

--- 노트 번호를 채운다.
---
--- 번호는 레포 단위로 단조 증가하며 삭제해도 재사용하지 않는다. GitHub 이슈 번호와
--- 같은 성질이라 "노트 #7 고쳐줘" 처럼 에이전트에게 그대로 지시할 수 있다.
--- 번호가 없던 기존 데이터(이 기능 추가 전에 만든 메모)는 작성순으로 부여한다.
---@param data table
---@return boolean changed
local function assign_numbers(data)
  local changed = false
  local maxn = 0
  local missing = {}
  for _, n in ipairs(data.notes) do
    if type(n.number) == "number" then
      maxn = math.max(maxn, n.number)
    else
      missing[#missing + 1] = n
    end
  end
  table.sort(missing, function(a, b)
    return ((a.created_at or "") .. (a.id or "")) < ((b.created_at or "") .. (b.id or ""))
  end)
  for _, n in ipairs(missing) do
    maxn = maxn + 1
    n.number = maxn
    changed = true
  end
  if type(data.next_number) ~= "number" or data.next_number <= maxn then
    data.next_number = maxn + 1
    changed = true
  end
  return changed
end

--- 항상 디스크에서 읽는다. 워크트리 여러 개가 같은 파일을 보므로 캐시하지 않는다.
---@param dir? string
---@return table data, string|nil err
function M.load(dir)
  local p = M.json_path(dir)
  if not p then
    return empty(), "git 레포가 아닙니다"
  end
  if vim.fn.filereadable(p) == 0 then
    return empty()
  end
  local raw = table.concat(vim.fn.readfile(p), "\n")
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" or type(data.notes) ~= "table" then
    -- 손상된 파일은 덮어쓰지 않고 백업해 둔다.
    local backup = p .. ".corrupt-" .. os.date("!%Y%m%dT%H%M%SZ")
    pcall(vim.fn.writefile, vim.fn.readfile(p), backup)
    vim.notify(
      ("[review-notes] notes.json 을 읽을 수 없어 백업했습니다: %s"):format(backup),
      vim.log.levels.WARN
    )
    return empty()
  end
  -- 번호가 빠진 레코드가 있으면 지금 부여하고 즉시 저장한다.
  -- (여러 워크트리가 같은 파일을 보므로 메모리에만 두면 인스턴스별로 번호가 갈린다)
  if assign_numbers(data) then
    M.save(data, dir)
  end
  return data
end

---@param notes table[]
---@return table[]
local function sorted(notes)
  local out = vim.deepcopy(notes)
  table.sort(out, function(a, b)
    if a.branch ~= b.branch then
      return (a.branch or "") < (b.branch or "")
    end
    if a.path ~= b.path then
      return (a.path or "") < (b.path or "")
    end
    if a.lnum ~= b.lnum then
      return (a.lnum or 0) < (b.lnum or 0)
    end
    return (a.created_at or "") < (b.created_at or "")
  end)
  return out
end

--- 사람과 에이전트가 읽는 마크다운 미러.
---@param notes table[]
---@param key string
---@return string[]
local function render_md(notes, key)
  local lines = {
    "# Review Notes — " .. key,
    "",
    "> 자동 생성 파일입니다. 직접 수정해도 다음 저장 때 덮어써집니다.",
    "> 정공본은 같은 디렉터리의 `notes.json` 입니다.",
    "> `- [ ]` 는 미해결, `- [x]` 는 resolve 처리된 항목입니다.",
    "> `#N` 은 레포 단위 고정 번호입니다. 삭제해도 재사용되지 않으므로 이 번호로 항목을 지칭하면 됩니다.",
    "",
  }
  if #notes == 0 then
    lines[#lines + 1] = "_기록된 메모가 없습니다._"
    return lines
  end

  local by_branch = {}
  local branch_order = {}
  for _, n in ipairs(sorted(notes)) do
    local b = n.branch or "unknown"
    if not by_branch[b] then
      by_branch[b] = {}
      branch_order[#branch_order + 1] = b
    end
    table.insert(by_branch[b], n)
  end

  for _, branch in ipairs(branch_order) do
    local group = by_branch[branch]
    local open = 0
    for _, n in ipairs(group) do
      if not n.resolved then
        open = open + 1
      end
    end
    lines[#lines + 1] = ("## %s  (미해결 %d / 전체 %d)"):format(branch, open, #group)
    lines[#lines + 1] = ""

    local cur_path
    for _, n in ipairs(group) do
      if n.path ~= cur_path then
        cur_path = n.path
        lines[#lines + 1] = "### " .. tostring(cur_path)
        lines[#lines + 1] = ""
      end
      local range = n.lnum == n.end_lnum and ("L%d"):format(n.lnum)
        or ("L%d-%d"):format(n.lnum, n.end_lnum)
      -- 기준줄을 함께 남긴다. 메모 작성 후 코드가 밀렸을 때
      -- 읽는 쪽(사람이든 에이전트든)이 라인 번호 대신 이걸로 위치를 찾을 수 있다.
      local head = ("- [%s] **#%s** %s"):format(
        n.resolved and "x" or " ",
        tostring(n.number or "?"),
        range
      )
      if n.sha then
        head = head .. (" `%s`"):format(n.sha)
      end
      local snip = n.snippet and n.snippet[1]
      if snip and snip:gsub("%s", "") ~= "" then
        head = head .. (" — 기준줄: `%s`"):format((snip:gsub("^%s+", "")))
      end
      lines[#lines + 1] = head
      for _, tl in ipairs(vim.split(n.text or "", "\n", { plain = true })) do
        lines[#lines + 1] = "  " .. tl
      end
      lines[#lines + 1] = ""
    end
  end
  return lines
end

--- notes.json + notes.md 를 함께 쓴다.
---@param data table
---@param dir? string
---@return boolean ok, string|nil err
function M.save(data, dir)
  local d = M.dir(dir)
  local key = M.repo_key(dir)
  if not d or not key then
    return false, "git 레포가 아닙니다"
  end
  if vim.fn.isdirectory(d) == 0 and vim.fn.mkdir(d, "p") == 0 then
    return false, "디렉터리를 만들 수 없습니다: " .. d
  end

  local notes = sorted(data.notes or {})
  -- 한 줄에 노트 하나씩 쓴다. 유효한 JSON 이면서 diff 가 읽힌다.
  local out = { ('{"version":1,"next_number":%d,"notes":['):format(data.next_number or (#notes + 1)) }
  for i, n in ipairs(notes) do
    out[#out + 1] = "  " .. vim.json.encode(n) .. (i < #notes and "," or "")
  end
  out[#out + 1] = "]}"

  local jok = pcall(vim.fn.writefile, out, d .. "/notes.json")
  if not jok then
    return false, "notes.json 을 쓸 수 없습니다"
  end
  pcall(vim.fn.writefile, render_md(notes, key), d .. "/notes.md")
  return true
end

local seeded = false
---@return string
local function new_id()
  if not seeded then
    math.randomseed(os.time() + vim.fn.getpid())
    seeded = true
  end
  return ("%d-%04x"):format(os.time(), math.random(0, 0xFFFF))
end

---@return string
local function now()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

--- 메모 추가.
---@param note table  path/lnum/end_lnum/text 필수
---@return table|nil note, string|nil err
function M.add(note)
  return with_lock(function()
    local data, err = M.load()
    if err then
      return nil, err
    end
    note.id = new_id()
    note.number = data.next_number or 1
    data.next_number = note.number + 1
    note.resolved = note.resolved or false
    note.created_at = now()
    note.updated_at = note.created_at
    table.insert(data.notes, note)
    local ok, serr = M.save(data)
    if not ok then
      return nil, serr
    end
    return note
  end, nil)
end

--- id 로 찾아 fn 을 적용. fn 이 false 를 반환하면 저장하지 않는다.
---@param id string
---@param fn fun(note: table): boolean|nil
---@return boolean ok, string|nil err
function M.update(id, fn)
  return with_lock(function()
    local data, err = M.load()
    if err then
      return false, err
    end
    for _, n in ipairs(data.notes) do
      if n.id == id then
        if fn(n) == false then
          return true
        end
        n.updated_at = now()
        return M.save(data)
      end
    end
    return false, "해당 메모를 찾을 수 없습니다"
  end, false)
end

---@param ids string[]
---@return table<string, boolean>
local function id_set(ids)
  local set = {}
  for _, id in ipairs(ids or {}) do
    set[id] = true
  end
  return set
end

--- 여러 메모에 fn 을 적용. 목록에서 골라 한꺼번에 처리할 때 쓴다.
--- id 마다 update() 를 부르면 그 수만큼 읽고 쓰므로, 여기서는 한 번만 읽고 한 번만 쓴다.
---@param ids string[]
---@param fn fun(note: table): boolean|nil  false 를 반환하면 그 메모는 건너뛴다
---@return integer changed, string|nil err
function M.update_many(ids, fn)
  local want = id_set(ids)
  if vim.tbl_isempty(want) then
    return 0
  end
  return with_lock(function()
    local data, err = M.load()
    if err then
      return 0, err
    end
    local changed = 0
    for _, n in ipairs(data.notes) do
      if want[n.id] and fn(n) ~= false then
        n.updated_at = now()
        changed = changed + 1
      end
    end
    if changed == 0 then
      return 0
    end
    local ok, serr = M.save(data)
    if not ok then
      return 0, serr
    end
    return changed
  end, 0)
end

--- 여러 메모를 한 번에 삭제.
---@param ids string[]
---@return integer removed, string|nil err
function M.remove_many(ids)
  local want = id_set(ids)
  if vim.tbl_isempty(want) then
    return 0
  end
  return with_lock(function()
    local data, err = M.load()
    if err then
      return 0, err
    end
    local kept, removed = {}, 0
    for _, n in ipairs(data.notes) do
      if want[n.id] then
        removed = removed + 1
      else
        kept[#kept + 1] = n
      end
    end
    if removed == 0 then
      return 0, "해당 메모를 찾을 수 없습니다"
    end
    data.notes = kept
    local ok, serr = M.save(data)
    if not ok then
      return 0, serr
    end
    return removed
  end, 0)
end

--- 여러 메모의 위치를 한 번에 갱신 (버퍼 저장 시 사용).
---@param updates table<string, {lnum: integer, end_lnum: integer, snippet: string[]}>
---@return boolean
function M.update_positions(updates)
  if vim.tbl_isempty(updates) then
    return true
  end
  return with_lock(function()
    local data, err = M.load()
    if err then
      return false, err
    end
    local dirty = false
    for _, n in ipairs(data.notes) do
      local u = updates[n.id]
      if u and (n.lnum ~= u.lnum or n.end_lnum ~= u.end_lnum) then
        n.lnum, n.end_lnum = u.lnum, u.end_lnum
        if u.snippet then
          n.snippet = u.snippet
        end
        n.updated_at = now()
        dirty = true
      end
    end
    if not dirty then
      return true
    end
    return M.save(data)
  end, false)
end

---@param id string
---@return boolean ok, string|nil err
function M.remove(id)
  local data, err = M.load()
  if err then
    return false, err
  end
  for i, n in ipairs(data.notes) do
    if n.id == id then
      table.remove(data.notes, i)
      return M.save(data)
    end
  end
  return false, "해당 메모를 찾을 수 없습니다"
end

--- 조건으로 메모 조회.
---@param filter? {path?: string, branch?: string, resolved?: boolean}
---@return table[]
function M.query(filter)
  filter = filter or {}
  local data = M.load()
  local out = {}
  for _, n in ipairs(data.notes) do
    local ok = true
    if filter.path and n.path ~= filter.path then
      ok = false
    end
    if filter.branch and n.branch ~= filter.branch then
      ok = false
    end
    if filter.resolved ~= nil and (n.resolved == true) ~= filter.resolved then
      ok = false
    end
    if ok then
      out[#out + 1] = n
    end
  end
  return sorted(out)
end

return M
