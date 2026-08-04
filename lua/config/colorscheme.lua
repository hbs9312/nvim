-- 활성 테마와, 테마가 바뀌어도 유지하고 싶은 하이라이트를 한곳에서 관리한다.
--
-- 테마 선택은 두 군데서 온다:
--   1. <leader>uc (Telescope colorscheme) 로 고른 값 → state 파일에 저장되고 다음 기동에도 유지
--   2. state 파일이 없거나 적용에 실패하면 아래 M.default
-- state 파일을 지우고 default 로 돌아가려면 :ColorschemeReset.
local M = {}

M.default = "sorbet"

-- git 에 올라가지 않는 로컬 상태. 레포만 clone 한 다른 머신에서는 default 로 시작한다.
local state_file = vim.fs.joinpath(vim.fn.stdpath("state"), "colorscheme")

-- diff 색상. 테마마다 diff 색이 제각각이고 대체로 너무 흐려서, 테마와 무관하게
-- 이 값으로 덮는다 (ColorScheme 이벤트마다 다시 적용).
--
-- 배경 틴트를 낮게 잡는 게 핵심이다. 처음엔 tokyonight 에서 가져온 #2a4a2a /
-- #4a2a2a 를 썼는데, 채도·명도가 높아서 그 위에 얹히는 문법색이 뭉개졌다
-- (sorbet 기준 최저 3.18:1). 아래 값은 문법색 최저 대비를 5:1 대로 끌어올린 것.
--
-- 줄 단위 그룹(DiffAdded/Removed/Changed)은 글자색까지 지정하는데, 같은 색조가
-- 겹치지 않도록 배경보다 훨씬 밝은 톤을 쓴다. 초록 글자 + 초록 배경은 명도차만
-- 남아서 수치가 통과해도 실제로는 잘 안 보인다.
local diff_overrides = {
  -- diff mode (diffview, vimdiff): 배경만 칠하고 글자는 파일의 문법색을 그대로 둔다
  DiffAdd     = { bg = "#1c2a1c" },
  DiffChange  = { bg = "#2a2814" },
  DiffDelete  = { bg = "#301c1c" },
  -- 변경된 줄 안에서 실제로 바뀐 부분. DiffChange 보다 밝게 만들면 그 위의
  -- 문법색이 죽는다 (sorbet Constant 기준 4.03 → 3.18:1). 후보를 훑어봤지만
  -- "문법색 유지 + DiffChange 와 밝기 구분" 을 동시에 만족하는 색은 없었다.
  -- 그래서 밝기는 DiffChange 와 같게 두고 색조·bold·밑줄로 구분한다.
  DiffText    = { bg = "#33240f", bold = true, underline = true },

  -- 줄 단위 그룹 (filetype=diff, diffview 파일 패널, fugitive)
  -- diffview 는 소문자 diffAdded 에 링크하지만 하이라이트 이름은 대소문자를
  -- 구분하지 않으므로 같은 그룹이다.
  DiffAdded   = { fg = "#b7e88f", bg = "#1c2a1c" },
  DiffRemoved = { fg = "#f4a2a2", bg = "#301c1c" },
  DiffChanged = { fg = "#eccb8c", bg = "#2a2814" },

  -- Octo 리뷰창은 좌/우 창에 namespace 하이라이트를 걸어 DiffText 를 자기
  -- 그룹으로 링크한다 (octo/reviews/layout.lua). 그 기본값이 GitHub 브랜드색
  -- (#238636 / #da3633) + 흰 글자라 이 팔레트보다 훨씬 밝고, 바뀐 구간의
  -- 문법색이 흰색으로 덮인다. 그래서 밴드 배경을 그대로 쓰고 bold·밑줄로만
  -- 구분한다 — DiffText 와 같은 방식이고, 흰 글자를 없애 문법색이 살아난다.
  -- octo 는 hlexists 로 가드하므로(octo/ui/colors.lua) 여기서 먼저 정의해두면
  -- octo 로드 시 덮이지 않는다. octo 는 ColorScheme 에 반응하지 않는다.
  OctoReviewDiffAddText    = { bg = "#1c2a1c", bold = true, underline = true },
  OctoReviewDiffDeleteText = { bg = "#301c1c", bold = true, underline = true },
}

local function apply_overrides()
  -- 어두운 배경 기준으로 고른 색이라 light 테마에서는 건드리지 않는다.
  if vim.o.background ~= "dark" then
    return
  end
  for name, val in pairs(diff_overrides) do
    vim.api.nvim_set_hl(0, name, val)
  end
end

local function read_state()
  local fd = io.open(state_file, "r")
  if not fd then
    return nil
  end
  local name = vim.trim(fd:read("*l") or "")
  fd:close()
  return name ~= "" and name or nil
end

-- 현재 state 파일에 있는 값. 같은 값을 다시 쓰지 않기 위한 캐시.
local saved = nil

local function write_state(name)
  if name == saved then
    return
  end
  -- default 와 같아지면 파일을 지운다. "파일 없음 = default 사용" 이라는 규칙을
  -- 지켜야, 나중에 M.default 를 고쳤을 때 낡은 state 파일이 이기지 않는다.
  if name == M.default then
    vim.fn.delete(state_file)
    saved = nil
    return
  end
  local fd = io.open(state_file, "w")
  if not fd then
    vim.notify(("colorscheme state 저장 실패: %s"):format(state_file), vim.log.levels.WARN)
    return
  end
  fd:write(name .. "\n")
  fd:close()
  saved = name
end

-- 이 모듈이 스스로 적용하는 동안은 저장하지 않는다. 기동/리셋 때 default 를
-- 적용한 것까지 state 파일로 굳어버리면 위와 같은 문제가 생긴다.
local applying = false

local function apply(name)
  applying = true
  local ok, err = pcall(vim.cmd.colorscheme, name)
  applying = false
  if not ok then
    vim.notify(("colorscheme %q 적용 실패: %s"):format(name, err), vim.log.levels.WARN)
  end
  return ok
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserColorScheme", { clear = true }),
    desc = "diff 하이라이트 재적용 + 선택한 테마 기억",
    callback = function(ev)
      apply_overrides()

      if applying then
        return
      end

      -- Telescope 프리뷰 중에는 저장하지 않는다. 프리뷰는 커서를 옮길 때마다
      -- ColorScheme 을 쏘기 때문에 훑고 지나간 테마까지 저장돼 버린다.
      -- <CR>/<Esc> 로 확정되는 순간의 colorscheme 은 프롬프트 창이 닫힌 뒤에
      -- 실행되므로 (telescope __internal.lua 의 select_default / close_windows),
      -- 현재 버퍼가 TelescopePrompt 인지로 프리뷰와 확정을 구분할 수 있다.
      if vim.bo.filetype == "TelescopePrompt" then
        return
      end
      write_state(ev.match)
    end,
  })

  vim.api.nvim_create_user_command("ColorschemeReset", function()
    vim.fn.delete(state_file)
    saved = nil
    if apply(M.default) then
      vim.notify(("colorscheme 기본값 %q 으로 복귀"):format(M.default), vim.log.levels.INFO)
    end
  end, { desc = "저장된 테마를 지우고 default 로 되돌린다" })

  local wanted = read_state()
  if wanted then
    saved = wanted -- 이미 파일에 있는 값이므로 다시 쓸 필요 없다
    if apply(wanted) then
      return
    end
    -- 저장된 이름이 더 이상 유효하지 않다 (플러그인 제거, 오타 등) → 상태를 버린다
    vim.fn.delete(state_file)
    saved = nil
  end
  apply(M.default)
end

return M
