-- review-notes/anchor.lua
-- 메모를 버퍼 위치에 붙여둔다.
--
-- 두 층으로 방어한다.
--   1. 세션 중 편집: extmark 가 범위를 따라 움직인다.
--   2. 외부 편집(에이전트가 파일을 고친 뒤 재로드): 저장해 둔 snippet 으로 재탐색한다.
local store = require("review-notes.store")

local M = {}

M.ns = vim.api.nvim_create_namespace("review_notes")

--- bufnr -> { [note_id] = extmark_id }
local marks = {}
--- bufnr -> { [note_id] = true }  (재앵커 실패한 메모)
local stale = {}
--- bufnr -> repo 상대경로
local paths = {}

local SEARCH_RADIUS = 40

--- 버퍼가 가리키는 레포 상대경로. octo 리뷰 버퍼도 처리한다.
---@param bufnr integer
---@return string|nil
function M.buf_path(bufnr)
  bufnr = bufnr or 0
  -- Octo 리뷰 diff 버퍼는 octo_diff_props 에 레포 상대경로를 갖고 있다.
  -- 공식 API 가 아니라 구현 세부사항이므로 실패해도 조용히 폴백한다.
  local ok, props = pcall(vim.api.nvim_buf_get_var, bufnr, "octo_diff_props")
  if ok and type(props) == "table" and type(props.path) == "string" and props.path ~= "" then
    return props.path
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or name:match("^%a[%w+.-]*://") then
    return nil
  end
  return store.rel_path(name)
end

--- Octo 리뷰 버퍼인지, 그렇다면 어느 쪽 diff 인지.
---@param bufnr integer
---@return string|nil  "LEFT" | "RIGHT"
function M.octo_side(bufnr)
  local ok, props = pcall(vim.api.nvim_buf_get_var, bufnr or 0, "octo_diff_props")
  if ok and type(props) == "table" then
    return props.split
  end
  return nil
end

---@param bufnr integer
---@param lnum integer  1-indexed
---@return string
local function line_at(bufnr, lnum)
  local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
  return l or ""
end

--- 저장된 위치가 여전히 맞는지 확인하고, 틀리면 snippet 으로 다시 찾는다.
---@param bufnr integer
---@param note table
---@return integer lnum, integer end_lnum, boolean is_stale
local function relocate(bufnr, note)
  local total = vim.api.nvim_buf_line_count(bufnr)
  local lnum = math.max(1, math.min(note.lnum or 1, total))
  local end_lnum = math.max(lnum, math.min(note.end_lnum or lnum, total))

  local want = note.snippet and note.snippet[1]
  if not want or want == "" then
    -- 비교 기준이 없으면 저장된 라인을 그대로 신뢰한다.
    return lnum, end_lnum, false
  end

  if line_at(bufnr, lnum) == want then
    return lnum, end_lnum, false
  end

  -- 위아래로 번갈아 탐색해서 가장 가까운 일치를 고른다.
  local span = (note.end_lnum or lnum) - (note.lnum or lnum)
  for d = 1, SEARCH_RADIUS do
    for _, cand in ipairs({ (note.lnum or 1) - d, (note.lnum or 1) + d }) do
      if cand >= 1 and cand <= total and line_at(bufnr, cand) == want then
        return cand, math.min(cand + span, total), false
      end
    end
  end

  return lnum, end_lnum, true
end

--- 해당 버퍼의 메모를 extmark 로 심는다. 현재 브랜치 메모만 대상으로 한다.
---@param bufnr integer
function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = M.buf_path(bufnr)
  if not path then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
  marks[bufnr] = {}
  stale[bufnr] = {}
  paths[bufnr] = path

  local notes = store.query({ path = path, branch = store.branch() })
  for _, note in ipairs(notes) do
    local lnum, end_lnum, is_stale = relocate(bufnr, note)
    local ok, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, lnum - 1, 0, {
      end_row = end_lnum - 1,
      sign_text = note.resolved and "✓" or "▌",
      sign_hl_group = note.resolved and "ReviewNoteSignResolved" or "ReviewNoteSign",
    })
    if ok then
      marks[bufnr][note.id] = id
      if is_stale then
        stale[bufnr][note.id] = true
      end
    end
  end
end

---@param bufnr integer
function M.detach(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, M.ns, 0, -1)
  end
  marks[bufnr] = nil
  stale[bufnr] = nil
  paths[bufnr] = nil
end

--- extmark 기준 현재 위치. 세션 중 편집이 반영된 값이다.
---@param bufnr integer
---@return table<string, {lnum: integer, end_lnum: integer}>
function M.live_positions(bufnr)
  local out = {}
  local m = marks[bufnr]
  if not m then
    return out
  end
  for note_id, mark_id in pairs(m) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, M.ns, mark_id, { details = true })
    if pos and pos[1] then
      local details = pos[3] or {}
      local start_row = pos[1]
      local end_row = details.end_row or start_row
      out[note_id] = { lnum = start_row + 1, end_lnum = math.max(start_row, end_row) + 1 }
    end
  end
  return out
end

--- 커서 줄을 포함하는 모든 메모. 중첩된 범위는 전부 반환한다.
---@param bufnr integer
---@param lnum integer  1-indexed
---@return table[]  { note = ..., lnum = ..., end_lnum = ..., stale = boolean }
function M.notes_at(bufnr, lnum)
  local path = paths[bufnr]
  if not path then
    return {}
  end
  local positions = M.live_positions(bufnr)
  local by_id = {}
  for _, n in ipairs(store.query({ path = path, branch = store.branch() })) do
    by_id[n.id] = n
  end

  local out = {}
  for note_id, pos in pairs(positions) do
    local note = by_id[note_id]
    if note and lnum >= pos.lnum and lnum <= pos.end_lnum then
      out[#out + 1] = {
        note = note,
        lnum = pos.lnum,
        end_lnum = pos.end_lnum,
        stale = (stale[bufnr] or {})[note_id] == true,
      }
    end
  end

  -- 범위 시작 → 끝 → 생성순. 팝업에서 안정적인 순서를 보장한다.
  table.sort(out, function(a, b)
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    if a.end_lnum ~= b.end_lnum then
      return a.end_lnum < b.end_lnum
    end
    return (a.note.created_at or "") < (b.note.created_at or "")
  end)
  return out
end

--- extmark 위치를 디스크에 반영한다. 버퍼 저장 시 호출.
---@param bufnr integer
function M.persist(bufnr)
  local path = paths[bufnr]
  if not path or not marks[bufnr] then
    return
  end
  local updates = {}
  for note_id, pos in pairs(M.live_positions(bufnr)) do
    updates[note_id] = {
      lnum = pos.lnum,
      end_lnum = pos.end_lnum,
      snippet = { line_at(bufnr, pos.lnum) },
    }
  end
  store.update_positions(updates)
end

--- 열려 있는 모든 버퍼를 다시 붙인다. 메모 추가/삭제 후 호출.
function M.refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and paths[bufnr] then
      M.attach(bufnr)
    end
  end
end

---@param bufnr integer
---@return boolean
function M.is_attached(bufnr)
  return paths[bufnr] ~= nil
end

return M
