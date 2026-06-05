local M = {}

M.servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" }
        },
        workspace = {
          checkThirdParty = false,
          library = (pcall(function() return vim.api.nvim_get_runtime_file("", true) end)
                   and vim.api.nvim_get_runtime_file("", true)
                   or {})
        }
      }
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = {
      python = {
        analysis = {
          autoImportCompletions = true,
          diagnosticMode = "workspace",
          typeCheckingMode = "basic",
          useLibraryCodeForTypes = true,
        },
      },
    },
    on_new_config = function(new_config, root_dir)
      local python_path = M.detect_python_path(root_dir)
      new_config.settings = new_config.settings or {}
      new_config.settings.python = new_config.settings.python or {}
      new_config.settings.python.pythonPath = python_path
    end,
  },
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
    settings = {
      typescript = {
        suggest = {
          autoImports = true
        },
        preferences = {
          importModuleSpecifierPreference = "relative"
        }
      },
      javascript = {
        suggestions = {
          autoImports = true
        },
        preferences = {
          importModuleSpecifierPreference = "relative"
        }
      }
    },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    settings = {
      ["rust-analyzer"] = {
        assist = {
          importGranularity = "module",
          importPrefix = "by_self",
          importGroup = true
        },
        cargo = {
          loadOutDirsFromCheck = true,
          allTargets = true,
          checkOnSave = {
            command = "clippy"
          }
        },
        procMacro = {
          enable = true
        },
        inlayHints = {
          enable = true
        }
      }
    },
  },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod" },
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
        analyses = {
          unusedparams = true,
          shadow = true
        }
      }
    },
  },
  metals = {
    cmd = { "metals" },
    filetypes = { "scala", "sbt" },
    settings = {},
  },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, filetypes = { "json" }, settings = {} },
  yamlls = { cmd = { "yaml-language-server", "--stdio" }, filetypes = { "yaml" }, settings = {} },
  bashls = { cmd = { "bash-language-server", "start" }, filetypes = { "sh" }, settings = {} },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, filetypes = { "html" }, settings = {} },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, filetypes = { "css" }, settings = {} },
}

M._last_detect = {}

M.detect_python_path = function(root_dir)
  -- Reset trace for debug command to inspect
  M._last_detect = { root_dir = root_dir, steps = {} }

  local function trace(step, outcome, detail)
    table.insert(M._last_detect.steps, { step = step, outcome = outcome, detail = detail or "" })
  end

  trace("start", "called", "root_dir=" .. tostring(root_dir))

  -- 1. VIRTUAL_ENV env var (set by uv run, poetry shell, pipenv shell, manual activation)
  local virtual_env = vim.env.VIRTUAL_ENV
  if virtual_env and virtual_env ~= "" then
    local python = virtual_env .. "/bin/python"
    if vim.fn.executable(python) == 1 then
      trace("VIRTUAL_ENV", "matched", python)
      vim.notify("[lsp] Python via VIRTUAL_ENV: " .. python, vim.log.levels.INFO)
      return python
    end
    trace("VIRTUAL_ENV", "skipped", "env set but " .. python .. " not executable")
  else
    trace("VIRTUAL_ENV", "skipped", "not set or empty")
  end

  -- Helper: does the project have a pyproject.toml?
  local function has_pyproject()
    return root_dir and vim.fn.filereadable(root_dir .. "/pyproject.toml") == 1
  end

  -- 2. uv detection (runs `uv run --directory <root> python -c ...`)
  if has_pyproject() then
    trace("pyproject.toml", "found", root_dir .. "/pyproject.toml")
    if vim.fn.executable("uv") == 1 then
      trace("uv", "on PATH", "")
      local uv_cmd = string.format(
        'uv run --directory %s python -c "import sys; print(sys.executable)" 2>/dev/null',
        vim.fn.shellescape(root_dir)
      )
      local result = vim.fn.system(uv_cmd)
      local exit_code = vim.v.shell_error
      local uv_python = result and vim.trim(result) or ""
      if exit_code == 0 and uv_python ~= "" and vim.fn.executable(uv_python) == 1 then
        trace("uv run", "matched", uv_python)
        vim.notify("[lsp] Python via uv: " .. uv_python, vim.log.levels.INFO)
        return uv_python
      end
      trace("uv run", "failed", string.format("exit=%d stderr=%s", exit_code, vim.trim(result)))
    else
      trace("uv", "not found", "uv not on PATH")
    end
  else
    trace("pyproject.toml", "not found", root_dir and (root_dir .. "/pyproject.toml") or "root_dir=nil")
  end

  -- 3. poetry detection (runs `poetry -C <root> env info --path`)
  local function has_poetry_lock()
    return root_dir and vim.fn.filereadable(root_dir .. "/poetry.lock") == 1
  end
  if has_poetry_lock() then
    trace("poetry.lock", "found", root_dir .. "/poetry.lock")
    if vim.fn.executable("poetry") == 1 then
      trace("poetry", "on PATH", "")
      local poetry_cmd = string.format(
        "poetry -C %s env info --path 2>/dev/null",
        vim.fn.shellescape(root_dir)
      )
      local result = vim.fn.system(poetry_cmd)
      local exit_code = vim.v.shell_error
      local poetry_venv = result and vim.trim(result) or ""
      if exit_code == 0 and poetry_venv ~= "" then
        local poetry_python = poetry_venv .. "/bin/python"
        if vim.fn.executable(poetry_python) == 1 then
          trace("poetry env info", "matched", poetry_python)
          vim.notify("[lsp] Python via poetry: " .. poetry_python, vim.log.levels.INFO)
          return poetry_python
        end
        trace("poetry env info", "failed", "venv " .. poetry_venv .. "/bin/python not executable")
      else
        trace("poetry env info", "failed", string.format("exit=%d stderr=%s", exit_code, vim.trim(result)))
      end
    else
      trace("poetry", "not found", "not on PATH")
    end
  else
    trace("poetry.lock", "not found", root_dir and (root_dir .. "/poetry.lock") or "root_dir=nil")
  end

  -- Helper: find python binary inside a venv directory (tries python3 then python)
  local function find_venv_python(venv_dir)
    for _, bin in ipairs({ "python3", "python" }) do
      local p = venv_dir .. "/bin/" .. bin
      if vim.fn.executable(p) == 1 then return p end
    end
    return nil
  end

  -- 4. .venv in project root (covers `uv venv`, `poetry config virtualenvs.in-project true`)
  if root_dir then
    local venv_python = find_venv_python(root_dir .. "/.venv")
    if venv_python then
      trace(".venv", "matched", venv_python)
      vim.notify("[lsp] Python via .venv: " .. venv_python, vim.log.levels.INFO)
      return venv_python
    end
    trace(".venv", "skipped", "no python3/python in " .. root_dir .. "/.venv/bin/")
  end

  -- 5. Other common venv directories
  if root_dir then
    for _, dir in ipairs({ "venv", "env", "virtualenv" }) do
      local venv_python = find_venv_python(root_dir .. "/" .. dir)
      if venv_python then
        trace(dir, "matched", venv_python)
        vim.notify("[lsp] Python via " .. dir .. ": " .. venv_python, vim.log.levels.INFO)
        return venv_python
      end
      trace(dir, "skipped", "no python3/python in " .. root_dir .. "/" .. dir .. "/bin/")
    end
  end

  -- 6. Conda
  local conda_prefix = vim.env.CONDA_PREFIX
  if conda_prefix and conda_prefix ~= "" then
    local python = conda_prefix .. "/bin/python"
    if vim.fn.executable(python) == 1 then
      trace("CONDA_PREFIX", "matched", python)
      vim.notify("[lsp] Python via conda: " .. python, vim.log.levels.INFO)
      return python
    end
    trace("CONDA_PREFIX", "skipped", python .. " not executable")
  else
    trace("CONDA_PREFIX", "skipped", "not set or empty")
  end

  -- 7. System fallback
  local fallback = vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
  trace("system fallback", "used", fallback)
  vim.notify("[lsp] Python via system fallback: " .. fallback, vim.log.levels.WARN)
  return fallback
end

M.debug_python = function()
  local lines = {}
  local function add(...) table.insert(lines, table.concat({...})) end

  add("")
  add(string.rep("=", 72))
  add("  LspPythonDebug Report")
  add(string.rep("=", 72))
  add("")

  -- 1. Last detect_python_path trace
  local last = M._last_detect
  add("── detect_python_path trace ──")
  add(string.format("  root_dir = %s", tostring(last.root_dir)))
  if last.steps and #last.steps > 0 then
    add(string.format("  steps (%d):", #last.steps))
    for _, s in ipairs(last.steps) do
      local marker = s.outcome == "matched" and " ✓" or (s.outcome == "failed" and " ✗" or "  ")
      add(string.format("    %s %-22s  %-8s  %s", marker, s.step, s.outcome, tostring(s.detail)))
    end
  else
    add("  (no trace data — detect_python_path has not been called yet)")
  end
  add("")

  -- 2. Current pyright client state
  add("── pyright LSP client ──")
  local pyright_found = false
  for _, client in pairs(vim.lsp.get_clients()) do
    if client.name == "pyright" then
      pyright_found = true
      add(string.format("  client id:    %s", tostring(client.id)))
      add(string.format("  root_dir:     %s", tostring(client.config.root_dir)))
      local py_settings = client.config.settings and client.config.settings.python
      if py_settings then
        add(string.format("  pythonPath:   %s", tostring(py_settings.pythonPath)))
        if py_settings.analysis then
          add(string.format("  analysis.diagnosticMode: %s", tostring(py_settings.analysis.diagnosticMode)))
          add(string.format("  analysis.typeCheckingMode: %s", tostring(py_settings.analysis.typeCheckingMode)))
          add(string.format("  analysis.useLibraryCodeForTypes: %s", tostring(py_settings.analysis.useLibraryCodeForTypes)))
        end
      end
      break
    end
  end
  if not pyright_found then
    add("  (no active pyright client — open a Python file)")
  end
  add("")

  -- 3. Environment variables
  add("── environment ──")
  add(string.format("  VIRTUAL_ENV:   %s", tostring(vim.env.VIRTUAL_ENV) or "(nil)"))
  add(string.format("  CONDA_PREFIX:  %s", tostring(vim.env.CONDA_PREFIX) or "(nil)"))
  if vim.env.PATH then
    local parts = vim.split(vim.env.PATH, ":")
    local preview = #parts > 3 and table.concat(parts, ":", 1, 3) .. ":..." or vim.env.PATH
    add(string.format("  PATH (first 3): %s", preview))
  else
    add("  PATH (first 3): (nil)")
  end
  add("")

  -- 4. Project files (use pyright's root_dir or cwd)
  local root = nil
  for _, client in pairs(vim.lsp.get_clients()) do
    if client.name == "pyright" then
      root = client.config.root_dir
      break
    end
  end
  root = root or vim.fn.getcwd()
  add(string.format("── project files (cwd: %s) ──", root))
  local function check_file(label, relpath)
    local full = root .. "/" .. relpath
    local ok = vim.fn.filereadable(full) == 1
    add(string.format("  %-20s %s  %s", relpath, ok and "✓" or "✗", ok and full or "(missing)"))
  end
  check_file("pyproject.toml", "pyproject.toml")
  check_file("poetry.lock", "poetry.lock")
  local function check_dir(label, relpath)
    local full = root .. "/" .. relpath
    local ok = vim.fn.isdirectory(full) == 1
    add(string.format("  %-20s %s  %s", relpath, ok and "✓" or "✗", ok and full or "(missing)"))
  end
  check_dir(".venv", ".venv")
  check_dir("venv", "venv")
  add("")

  -- 5. Tool availability
  add("── tool availability ──")
  local function check_tool(name)
    local ok = vim.fn.executable(name) == 1
    local path = ok and vim.fn.exepath(name) or "(not found)"
    add(string.format("  %-12s %s  %s", name, ok and "✓" or "✗", path))
  end
  check_tool("uv")
  check_tool("poetry")
  check_tool("python3")
  check_tool("python")
  add("")

  -- 6. Manual command tests (cheap checks, run only if tools present)
  add("── manual resolution (dry-run) ──")
  if root then
    if vim.fn.executable("uv") == 1 and vim.fn.filereadable(root .. "/pyproject.toml") == 1 then
      local uv_cmd = string.format(
        'uv run --directory %s python -c "import sys; print(sys.executable)" 2>&1',
        vim.fn.shellescape(root)
      )
      local result = vim.trim(vim.fn.system(uv_cmd))
      add(string.format("  uv result:    %s", result ~= "" and result or "(empty)"))
    else
      add("  uv:           (skipped — uv not found or no pyproject.toml)")
    end
    if vim.fn.executable("poetry") == 1 and vim.fn.filereadable(root .. "/poetry.lock") == 1 then
      local poetry_cmd = string.format(
        "poetry -C %s env info --path 2>&1",
        vim.fn.shellescape(root)
      )
      local result = vim.trim(vim.fn.system(poetry_cmd))
      add(string.format("  poetry result:%s", result ~= "" and result or "(empty)"))
    else
      add("  poetry:       (skipped — poetry not found or no poetry.lock)")
    end
  end
  add("")

  add(string.rep("=", 72))
  add("  Report complete — if pyright still sees system Python,")
  add("  check the trace above for which step matched (✓) and")
  add("  verify the path shown for uv/poetry matches your venv.")
  add(string.rep("=", 72))

  -- Output to a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_set_current_buf(buf)
end

M.server_exists = function(name)
  local server = M.servers[name]
  if not server then return false end
  local cmd = server.cmd
  if cmd and #cmd > 0 then
    return vim.fn.executable(cmd[1]) == 1
  end
  return false
end

M.get_capabilities = function()
  local caps = vim.lsp.protocol.make_client_capabilities()
  caps.offsetEncoding = { "utf-16", "utf-8" }
  local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp and type(cmp.default_capabilities) == "function" then
    caps = cmp.default_capabilities(caps)
  end
  return caps
end

M.setup_servers = function(on_attach)
  local diag = require("core.diagnostics")
  for name, cfg in pairs(M.servers) do
    -- Apply workspace settings via core.diagnostics if available
    local settings = cfg.settings
    if diag and type(diag.apply_workspace_settings) == "function" then
      local ok, applied = pcall(diag.apply_workspace_settings, name, settings)
      if ok and applied then
        settings = applied
      end
    end

    local server_cfg = vim.tbl_deep_extend("force",
    { capabilities = M.get_capabilities(), on_attach = on_attach },
    cfg,
    { settings = settings }
  )

    -- Record into vim.lsp.config so nvim-lspconfig (new API) and tests can see config
    vim.lsp.config[name] = server_cfg

    -- Mark server enabled for environments that expect vim.lsp.enable
    if vim.lsp.enable then
      pcall(vim.lsp.enable, name)
    else
      if type(vim.lsp) == "table" then
        vim.lsp.enable = vim.lsp.enable or function(_) end
        pcall(vim.lsp.enable, name)
      end
    end
  end
end

M.config = function()
  local diag = require("core.diagnostics")
  diag.setup_display()
  M.setup_servers(function(_, bufnr)
    local keymaps = require("core.keymaps")
    keymaps.lsp_on_attach(bufnr)
  end)

  -- Workaround: on_new_config doesn't fire with vim.lsp.enable() (new nvim-lspconfig API).
  -- Use LspAttach autocmd to set pythonPath AFTER pyright attaches, when root_dir is known.
  local pyright_augroup = vim.api.nvim_create_augroup("PyrightPythonPath", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = pyright_augroup,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "pyright" then return end
      local root_dir = client.config.root_dir
      local python_path = M.detect_python_path(root_dir)
      if python_path then
        client.config.settings = client.config.settings or {}
        client.config.settings.python = client.config.settings.python or {}
        client.config.settings.python.pythonPath = python_path
        -- Notify pyright so it picks up the new pythonPath
        client.notify("workspace/didChangeConfiguration", {
          settings = client.config.settings,
        })
        vim.notify("[lsp] pyright pythonPath set via LspAttach: " .. python_path, vim.log.levels.INFO)
      end
    end,
  })

  -- Debug command: inspect Python detection state
  pcall(vim.api.nvim_create_user_command, "LspPythonDebug", function()
    M.debug_python()
  end, { desc = "Show Python LSP detection trace and environment" })

  -- Mason setup for ensuring servers
  local ok, mason = pcall(require, "mason-lspconfig")
  if ok and mason and type(mason.setup) == "function" then
    mason.setup({
    ensure_installed = {
      "lua_ls",
      "pyright",
      "gopls",
      "rust_analyzer",
      "ts_ls"
    },
    automatic_installation = true
  })
  end
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim"
  },
  _internal_deps = { "core.diagnostics", "core.keymaps" },
  config = M.config,
  _module = M,
}
