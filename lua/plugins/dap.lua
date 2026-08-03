-- 어댑터와 configuration 은 여기, 키맵은 lua/config/keymap.lua 에 모아둔다.
local mason = vim.fn.stdpath("data") .. "/mason"

local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

-- package.json 의 스크립트 목록을 읽어 고르게 한다.
-- coroutine 을 돌려주는 게 핵심: dap 이 부모를 yield 시킨 뒤에 이 스레드를 깨우므로
-- vim.ui.select 구현이 동기여도(nvim 기본값이 그렇다) resume 이 yield 보다 앞서지 않는다.
local function npm_run_args()
  return coroutine.create(function(dap_co)
    local root = vim.fs.root(0, "package.json")
    local names = {}
    if root then
      local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
      if ok and type(decoded) == "table" and type(decoded.scripts) == "table" then
        for name in pairs(decoded.scripts) do
          table.insert(names, name)
        end
        table.sort(names)
      end
    end

    if #names == 0 then
      local typed = vim.fn.input("npm script: ")
      -- 취소하면 인자 없는 run — 스크립트 목록만 찍고 끝난다.
      coroutine.resume(dap_co, typed ~= "" and { "run", typed } or { "run" })
      return
    end

    vim.ui.select(names, { prompt = "npm script" }, function(choice)
      coroutine.resume(dap_co, choice and { "run", choice } or { "run" })
    end)
  end)
end

-- 프로젝트가 쓰는 패키지 매니저를 lockfile 로 판별한다.
-- bun 은 일부러 빼둔다 — js-debug 가 붙을 자식 node 프로세스를 만들지 않아서
-- runtimeExecutable 로 넣으면 조용히 안 멈춘다.
local function package_manager()
  local root = vim.fs.root(0, { "pnpm-lock.yaml", "yarn.lock", "package-lock.json" })
  if not root then
    return "npm"
  end
  for file, cmd in pairs({
    ["pnpm-lock.yaml"] = "pnpm",
    ["yarn.lock"] = "yarn",
  }) do
    if vim.uv.fs_stat(root .. "/" .. file) then
      return cmd
    end
  end
  return "npm"
end

-- pyright 쪽과 같은 규칙: 프로젝트 .venv 를 먼저 보고, 없으면 활성 venv, 그다음 시스템 python.
local function project_python()
  local root = vim.fs.root(0, { "pyproject.toml", "setup.py", "requirements.txt", ".git" }) or vim.fn.getcwd()
  local venv = root .. "/.venv/bin/python"
  if vim.uv.fs_stat(venv) then
    return venv
  end
  local active = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if active and vim.uv.fs_stat(active .. "/bin/python") then
    return active .. "/bin/python"
  end
  return vim.fn.exepath("python3")
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- js-debug-adapter / debugpy 를 mason 으로 깔아둔다 (설치만, 어댑터 설정은 아래에서 직접).
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
          ensure_installed = { "js", "python" },
          automatic_installation = true,
          -- handlers 를 주면 mason 이 어댑터/configuration 까지 기본값으로 덮는다.
          -- 설치만 맡기고 설정은 아래에서 직접 한다 — 그래서 일부러 비워둔다.
        },
      },
    },
    config = function()
      local dap = require("dap")

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticSignInfo" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticSignWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticSignWarn", linehl = "Visual" })

      ------------------------------------------------------------------
      -- JavaScript / TypeScript — vscode-js-debug
      ------------------------------------------------------------------
      -- 하나의 dapDebugServer 가 node 와 chrome 을 모두 처리한다. 자식 프로세스
      -- (fork, worker, --inspect 로 띄운 vite 등)까지 따라붙는 게 이 어댑터의 이유.
      for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
          type = "server",
          host = "127.0.0.1",
          port = "${port}",
          executable = {
            command = mason .. "/bin/js-debug-adapter",
            -- host 를 넘기지 않으면 ::1 에만 바인딩해서 127.0.0.1 접속이 거부된다.
            args = { "${port}", "127.0.0.1" },
          },
        }
      end

      local js_configs = {
        {
          name = "Launch file (node)",
          type = "pwa-node",
          request = "launch",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        },
        {
          name = "Launch file (tsx)",
          type = "pwa-node",
          request = "launch",
          program = "${file}",
          cwd = "${workspaceFolder}",
          -- ts 를 트랜스파일 없이 바로 실행. tsx 가 devDependency 에 있어야 한다.
          -- 함수로 둬야 dap 로드 시점이 아니라 실행 시점의 프로젝트를 기준으로 잡는다.
          runtimeExecutable = function()
            local pm = package_manager()
            return pm == "npm" and "npx" or pm
          end,
          runtimeArgs = { "tsx" },
          sourceMaps = true,
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        },
        {
          name = "Launch npm script",
          type = "pwa-node",
          request = "launch",
          cwd = "${workspaceFolder}",
          runtimeExecutable = package_manager,
          runtimeArgs = npm_run_args,
          sourceMaps = true,
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          -- npm 이 감싼 자식 node 프로세스에서 멈추게 한다.
          console = "integratedTerminal",
        },
        {
          name = "Attach to process",
          type = "pwa-node",
          request = "attach",
          processId = function()
            return require("dap.utils").pick_process({ filter = "node" })
          end,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          skipFiles = { "<node_internals>/**" },
        },
        {
          name = "Attach to port (node --inspect)",
          type = "pwa-node",
          request = "attach",
          port = function()
            return tonumber(vim.fn.input("Port [9229]: ")) or 9229
          end,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          skipFiles = { "<node_internals>/**" },
        },
        {
          name = "Attach to Chrome (--remote-debugging-port=9222)",
          type = "pwa-chrome",
          request = "attach",
          port = 9222,
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          name = "Launch Chrome against dev server",
          type = "pwa-chrome",
          request = "launch",
          url = function()
            local url = vim.fn.input("URL [http://localhost:5173]: ")
            return url ~= "" and url or "http://localhost:5173"
          end,
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
          -- 평소 쓰는 Chrome 프로필을 건드리지 않도록 별도 프로필로 띄운다.
          userDataDir = vim.fn.stdpath("cache") .. "/dap-chrome",
        },
      }

      for _, ft in ipairs(js_filetypes) do
        dap.configurations[ft] = vim.deepcopy(js_configs)
      end

      ------------------------------------------------------------------
      -- Python — debugpy
      ------------------------------------------------------------------
      dap.adapters.python = function(callback, config)
        if config.request == "attach" then
          callback({
            type = "server",
            host = config.host or "127.0.0.1",
            port = config.port or 5678,
            options = { source_filetype = "python" },
          })
        else
          callback({
            type = "executable",
            command = mason .. "/packages/debugpy/venv/bin/python",
            args = { "-m", "debugpy.adapter" },
            options = { source_filetype = "python" },
          })
        end
      end

      dap.configurations.python = {
        {
          name = "Launch file",
          type = "python",
          request = "launch",
          program = "${file}",
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          pythonPath = project_python,
          justMyCode = false,
        },
        {
          name = "Launch module",
          type = "python",
          request = "launch",
          module = function()
            return vim.fn.input("Module: ")
          end,
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          pythonPath = project_python,
          justMyCode = false,
        },
        {
          name = "pytest (current file)",
          type = "python",
          request = "launch",
          module = "pytest",
          args = { "${file}", "-s" },
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          pythonPath = project_python,
          justMyCode = false,
        },
        {
          name = "Attach to debugpy (:5678)",
          type = "python",
          request = "attach",
          connect = { host = "127.0.0.1", port = 5678 },
          pathMappings = { { localRoot = "${workspaceFolder}", remoteRoot = "." } },
        },
      }

      -- .vscode/launch.json 은 dap 이 실행 시점에 $cwd 기준으로 알아서 읽는다.
      -- VS Code 는 type 을 node/chrome 으로 쓰지만 js-debug 서버는 pwa-* 만 받는다
      -- (그냥 별칭으로 두면 어댑터가 연결을 끊는다). 그래서 type 을 바꿔 넘긴다.
      for legacy, modern in pairs({ node = "pwa-node", chrome = "pwa-chrome" }) do
        dap.adapters[legacy] = function(callback, config)
          config.type = modern
          callback(dap.adapters[modern])
        end
      end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    config = true,
  },
}
