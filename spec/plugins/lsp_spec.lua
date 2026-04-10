-- Tests for plugins/lsp.lua
local spec_helper = require("spec_helper")

describe("plugins.lsp", function()
  before_each(function()
    spec_helper.reset_vim_mock()
    -- Mock dependencies
    package.loaded["cmp_nvim_lsp"] = {
      default_capabilities = function(caps)
        return vim.tbl_deep_extend("force", caps or {}, { completion = true })
      end,
    }
    package.loaded["core.keymaps"] = {
      lsp_on_attach = function() end,
    }
    -- Mock core.diagnostics module
    package.loaded["core.diagnostics"] = {
      setup_display = function()
        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })
      end,
      apply_workspace_settings = function(server_name, settings)
        -- Apply workspace settings for testing
        if server_name == "pyright" then
          settings = settings or {}
          settings.python = settings.python or {}
          settings.python.analysis = settings.python.analysis or {}
          settings.python.analysis.diagnosticMode = "workspace"
        elseif server_name == "ts_ls" then
          settings = settings or {}
          settings.typescript = settings.typescript or {}
          settings.typescript.diagnosticMode = "workspace"
          settings.javascript = settings.javascript or {}
          settings.javascript.diagnosticMode = "workspace"
        end
        return settings
      end,
    }
  end)

  after_each(function()
    package.loaded["cmp_nvim_lsp"] = nil
    package.loaded["core.keymaps"] = nil
    package.loaded["core.diagnostics"] = nil
  end)

  describe("plugin spec", function()
    it("should return a valid lazy.nvim plugin spec", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec)
      assert.equals("neovim/nvim-lspconfig", spec[1])
    end)

    it("should have event trigger", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec.event)
    end)

    it("should trigger on BufReadPre", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec.event, "BufReadPre"))
    end)

    it("should trigger on BufNewFile", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec.event, "BufNewFile"))
    end)

    it("should have dependencies", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec.dependencies)
    end)

    it("should depend on cmp-nvim-lsp", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec.dependencies, "hrsh7th/cmp-nvim-lsp"))
    end)

    it("should have config function", function()
      local spec = require("plugins.lsp")
      assert.is_function(spec.config)
    end)

    it("should expose _module for testing", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec._module)
    end)
  end)

  describe("_module.servers", function()
    it("should define servers table", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec._module.servers)
    end)

    it("should have lua_ls server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.lua_ls)
    end)

    it("should have pyright server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.pyright)
    end)

    it("should have gopls server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.gopls)
    end)

    it("should have rust_analyzer server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.rust_analyzer)
    end)

    it("should have metals server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.metals)
    end)

    it("should have ts_ls server", function()
      local spec = require("plugins.lsp")
      assert.is_not_nil(spec._module.servers.ts_ls)
    end)
  end)

  describe("server configurations", function()
    it("lua_ls should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("lua-language-server", spec._module.servers.lua_ls.cmd[1])
    end)

    it("lua_ls should have lua filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.lua_ls.filetypes, "lua"))
    end)

    it("pyright should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("pyright-langserver", spec._module.servers.pyright.cmd[1])
    end)

    it("pyright should have python filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.pyright.filetypes, "python"))
    end)

    it("gopls should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("gopls", spec._module.servers.gopls.cmd[1])
    end)

    it("gopls should have go filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.gopls.filetypes, "go"))
    end)

    it("gopls should have gomod filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.gopls.filetypes, "gomod"))
    end)

    it("rust_analyzer should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("rust-analyzer", spec._module.servers.rust_analyzer.cmd[1])
    end)

    it("rust_analyzer should have rust filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.rust_analyzer.filetypes, "rust"))
    end)

    it("metals should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("metals", spec._module.servers.metals.cmd[1])
    end)

    it("metals should have scala filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.metals.filetypes, "scala"))
    end)

    it("metals should have sbt filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.metals.filetypes, "sbt"))
    end)

    it("gopls should enable gofumpt", function()
      local spec = require("plugins.lsp")
      assert.is_true(spec._module.servers.gopls.settings.gopls.gofumpt)
    end)

    it("gopls should enable staticcheck", function()
      local spec = require("plugins.lsp")
      assert.is_true(spec._module.servers.gopls.settings.gopls.staticcheck)
    end)

    it("gopls should enable unusedparams analysis", function()
      local spec = require("plugins.lsp")
      assert.is_true(spec._module.servers.gopls.settings.gopls.analyses.unusedparams)
    end)

    it("gopls should enable shadow analysis", function()
      local spec = require("plugins.lsp")
      assert.is_true(spec._module.servers.gopls.settings.gopls.analyses.shadow)
    end)

    it("ts_ls should have typescript settings", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec._module.servers.ts_ls.settings.typescript)
    end)

    it("ts_ls should have javascript settings", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec._module.servers.ts_ls.settings.javascript)
    end)

    it("ts_ls should set typescript import preference to relative", function()
      local spec = require("plugins.lsp")
      assert.equals("relative", spec._module.servers.ts_ls.settings.typescript.preferences.importModuleSpecifierPreference)
    end)

    it("ts_ls should set javascript import preference to relative", function()
      local spec = require("plugins.lsp")
      assert.equals("relative", spec._module.servers.ts_ls.settings.javascript.preferences.importModuleSpecifierPreference)
    end)

    it("ts_ls should have typescript filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.ts_ls.filetypes, "typescript"))
    end)

    it("ts_ls should have typescriptreact filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.ts_ls.filetypes, "typescriptreact"))
    end)

    it("ts_ls should have javascript filetype", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.ts_ls.filetypes, "javascript"))
    end)

    it("jsonls should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("vscode-json-language-server", spec._module.servers.jsonls.cmd[1])
    end)

    it("yamlls should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("yaml-language-server", spec._module.servers.yamlls.cmd[1])
    end)

    it("html should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("vscode-html-language-server", spec._module.servers.html.cmd[1])
    end)

    it("cssls should have correct cmd", function()
      local spec = require("plugins.lsp")
      assert.equals("vscode-css-language-server", spec._module.servers.cssls.cmd[1])
    end)

    it("rust_analyzer should enable clippy on save", function()
      local spec = require("plugins.lsp")
      assert.equals("clippy", spec._module.servers.rust_analyzer.settings["rust-analyzer"].cargo.checkOnSave.command)
    end)

    it("lua_ls should suppress vim global diagnostic", function()
      local spec = require("plugins.lsp")
      assert.is_true(vim.tbl_contains(spec._module.servers.lua_ls.settings.Lua.diagnostics.globals, "vim"))
    end)

    it("lua_ls should have workspace library configuration", function()
      local spec = require("plugins.lsp")
      assert.is_table(spec._module.servers.lua_ls.settings.Lua.workspace.library)
    end)
  end)

  describe("_module.server_exists", function()
    it("should be a function", function()
      local spec = require("plugins.lsp")
      assert.is_function(spec._module.server_exists)
    end)

    it("should return true for known executables", function()
      local spec = require("plugins.lsp")
      assert.is_true(spec._module.server_exists("gopls"))
    end)

    it("should return false for unknown executables", function()
      local spec = require("plugins.lsp")
      assert.is_false(spec._module.server_exists("nonexistent-server"))
    end)
  end)

  describe("_module.get_capabilities", function()
    it("should be a function", function()
      local spec = require("plugins.lsp")
      assert.is_function(spec._module.get_capabilities)
    end)

    it("should return capabilities table", function()
      local spec = require("plugins.lsp")
      local caps = spec._module.get_capabilities()
      assert.is_table(caps)
    end)
  end)

  describe("_module.setup_servers", function()
    it("should be a function", function()
      local spec = require("plugins.lsp")
      assert.is_function(spec._module.setup_servers)
    end)

    it("should configure LSP servers", function()
      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)
      local state = spec_helper.vim_mock.get_state()
      assert.is_not_nil(state.lsp_configs.pyright)
      assert.is_not_nil(state.lsp_configs.gopls)
    end)

    it("should enable LSP servers", function()
      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)
      local state = spec_helper.vim_mock.get_state()
      assert.is_true(state.lsp_enabled.pyright)
      assert.is_true(state.lsp_enabled.gopls)
    end)

    it("should add capabilities to servers", function()
      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)
      local state = spec_helper.vim_mock.get_state()
      assert.is_not_nil(state.lsp_configs.pyright.capabilities)
    end)

    it("should add on_attach to servers", function()
      local spec = require("plugins.lsp")
      local on_attach = function() end
      spec._module.setup_servers(on_attach)
      local state = spec_helper.vim_mock.get_state()
      assert.is_not_nil(state.lsp_configs.pyright.on_attach)
    end)

    it("should apply workspace diagnostics settings via core.diagnostics", function()
      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)
      local state = spec_helper.vim_mock.get_state()
      -- Verify that diagnosticMode was set to "workspace" for pyright
      assert.equals("workspace", state.lsp_configs.pyright.settings.python.analysis.diagnosticMode)
    end)

    it("should apply workspace diagnostics settings for ts_ls", function()
      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)
      local state = spec_helper.vim_mock.get_state()
      -- Verify that diagnosticMode was set to "workspace" for ts_ls
      assert.equals("workspace", state.lsp_configs.ts_ls.settings.typescript.diagnosticMode)
      assert.equals("workspace", state.lsp_configs.ts_ls.settings.javascript.diagnosticMode)
    end)
  end)

  describe("config function", function()
    it("should run without error", function()
      local spec = require("plugins.lsp")
      assert.has_no.errors(function()
        spec.config()
      end)
    end)

    it("should call diagnostics.setup_display", function()
      local setup_display_called = false
      package.loaded["core.diagnostics"] = {
        setup_display = function()
          setup_display_called = true
          vim.diagnostic.config({ virtual_text = true })
        end,
        apply_workspace_settings = function(_, settings)
          return settings
        end,
      }

      local spec = require("plugins.lsp")
      spec.config()
      assert.is_true(setup_display_called)
    end)

    it("should setup diagnostics via core.diagnostics module", function()
      local spec = require("plugins.lsp")
      spec.config()
      local state = spec_helper.vim_mock.get_state()
      assert.is_not_nil(state.diagnostic_config)
    end)

    it("should setup servers", function()
      local spec = require("plugins.lsp")
      spec.config()
      local state = spec_helper.vim_mock.get_state()
      assert.is_true(#vim.tbl_keys(state.lsp_configs) > 0)
    end)
  end)

  describe("integration with core.diagnostics", function()
    it("should delegate diagnostic setup to core.diagnostics", function()
      local diagnostics_setup_called = false
      package.loaded["core.diagnostics"] = {
        setup_display = function()
          diagnostics_setup_called = true
        end,
        apply_workspace_settings = function(_, settings)
          return settings
        end,
      }

      local spec = require("plugins.lsp")
      spec.config()
      assert.is_true(diagnostics_setup_called)
    end)

    it("should use core.diagnostics for workspace settings", function()
      local apply_called_for_pyright = false
      local apply_called_for_ts_ls = false

      package.loaded["core.diagnostics"] = {
        setup_display = function() end,
        apply_workspace_settings = function(server_name, settings)
          if server_name == "pyright" then
            apply_called_for_pyright = true
          elseif server_name == "ts_ls" then
            apply_called_for_ts_ls = true
          end
          return settings
        end,
      }

      local spec = require("plugins.lsp")
      spec._module.setup_servers(function() end)

      assert.is_true(apply_called_for_pyright)
      assert.is_true(apply_called_for_ts_ls)
    end)
  end)
end)

-- Helper
function vim.tbl_keys(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end
