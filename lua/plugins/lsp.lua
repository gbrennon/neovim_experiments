-- plugins/lsp.lua
-- Provide a lazy.nvim spec compatible with the tests (exposes _module)

local M = {}

M.servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false, library = (pcall(function() return vim.api.nvim_get_runtime_file("", true) end) and vim.api.nvim_get_runtime_file("", true) or {}) } } },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = { python = { analysis = { autoImportCompletions = true, diagnosticMode = "workspace" } } },
  },
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
    settings = { typescript = { suggest = { autoImports = true }, preferences = { importModuleSpecifierPreference = "relative" } }, javascript = { suggestions = { autoImports = true }, preferences = { importModuleSpecifierPreference = "relative" } } },
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
          allTargets = true
        },
        procMacro = { enable = true },
        checkOnSave = { command = "clippy" },
        inlayHints = { enable = true }
      }
    },
  },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod" },
    settings = { gopls = { gofumpt = true, staticcheck = true, analyses = { unusedparams = true, shadow = true } } },
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

M.server_exists = function(name)
  return vim.fn.executable((M.servers[name] and M.servers[name].cmd and M.servers[name].cmd[1]) or name) == 1
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

    local server_cfg = vim.tbl_deep_extend("force", { capabilities = M.get_capabilities(), on_attach = on_attach }, cfg, { settings = settings })

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
  -- Mason setup for ensuring servers
  local ok, mason = pcall(require, "mason-lspconfig")
  if ok and mason and type(mason.setup) == "function" then
    mason.setup({ ensure_installed = { "lua_ls", "pyright", "gopls", "rust_analyzer", "ts_ls" }, automatic_installation = true })
  end
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "hrsh7th/cmp-nvim-lsp", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
  config = M.config,
  _module = M,
}
