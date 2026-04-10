-- Tests for plugins/cmp.lua
local spec_helper = require("spec_helper")

describe("plugins.cmp", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.cmp"] = nil

    -- Mock cmp before requiring the plugin
    local function make_callable_mapping(tbl)
      return setmetatable(tbl, { __call = function(_, opts) 
        local result = {}
        for k, v in pairs(tbl) do result[k] = v end
        if opts then for k, v in pairs(opts) do result[k] = v end end
        return result
      end })
    end
    local cmdline_mapping = make_callable_mapping({ ["<CR>"] = function() end })
    local insert_mapping = make_callable_mapping({ ["<Tab>"] = function() end, ["<S-Tab>"] = function() end })
    local preset_mock = {
      insert = function() return insert_mapping end,
      cmdline = function() return cmdline_mapping end,
    }
    local mapping_mock = make_callable_mapping(preset_mock)
    local cmp_mock = {
      setup = function() end,
      mapping = mapping_mock,
      config = { sources = function(...) return { ... } end },
    }
    package.loaded["cmp"] = cmp_mock

    local luasnip_mock = { lsp_expand = function() end }
    package.loaded["luasnip"] = luasnip_mock

    local loader_mock = { lazy_load = function() end }
    package.loaded["luasnip.loaders"] = { from_vscode = loader_mock }
    package.loaded["luasnip.loaders.from_vscode"] = loader_mock

    spec = require("plugins.cmp")
  end)

  after_each(function()
    package.loaded["plugins.cmp"] = nil
    package.loaded["cmp"] = nil
    package.loaded["luasnip"] = nil
    package.loaded["luasnip.loaders"] = nil
    package.loaded["luasnip.loaders.from_vscode"] = nil
  end)

  describe("plugin spec", function()
    it("should return a valid lazy.nvim spec", function()
      assert.is_table(spec)
      assert.equals("hrsh7th/nvim-cmp", spec[1])
    end)

    it("should depend on required plugins", function()
      assert.is_table(spec.dependencies)
      local deps = spec.dependencies
      assert.is_true(vim.tbl_contains(deps, "hrsh7th/cmp-nvim-lsp"))
      assert.is_true(vim.tbl_contains(deps, "L3MON4D3/LuaSnip"))
    end)

    it("should load on InsertEnter and CmdlineEnter events", function()
      assert.is_table(spec.event)
      assert.is_true(vim.tbl_contains(spec.event, "InsertEnter"))
      assert.is_true(vim.tbl_contains(spec.event, "CmdlineEnter"))
    end)

    it("should have config function", function()
      assert.is_function(spec.config)
    end)

    it("should expose _module", function()
      assert.is_table(spec._module)
    end)
  end)

  describe("_module.config", function()
    it("should exist", function()
      assert.is_function(spec._module.config)
    end)
  end)
end)