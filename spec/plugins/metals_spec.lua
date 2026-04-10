-- Tests for plugins/metals.lua
local spec_helper = require("spec_helper")

describe("plugins.metals", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.metals"] = nil
    package.loaded["metals"] = nil

    -- Mock metals before requiring the plugin
    local metals_mock = {
      bare_config = function()
        return { settings = {}, init_options = {} }
      end,
      initialize_or_attach = function() end,
    }
    package.loaded["metals"] = metals_mock

    -- Mock cmp_nvim_lsp
    package.loaded["cmp_nvim_lsp"] = { default_capabilities = function() return {} end }

    spec = require("plugins.metals")
  end)

  after_each(function()
    package.loaded["plugins.metals"] = nil
    package.loaded["metals"] = nil
    package.loaded["cmp_nvim_lsp"] = nil
  end)

  describe("plugin spec", function()
    it("should return a valid lazy.nvim spec", function()
      assert.is_table(spec)
      assert.equals("scalameta/nvim-metals", spec[1])
    end)

    it("should depend on plenary.nvim", function()
      assert.is_true(vim.tbl_contains(spec.dependencies, "nvim-lua/plenary.nvim"))
    end)

    it("should load for scala, sbt, java filetypes", function()
      assert.is_table(spec.ft)
      assert.is_true(vim.tbl_contains(spec.ft, "scala"))
      assert.is_true(vim.tbl_contains(spec.ft, "sbt"))
    end)

    it("should have config function", function()
      assert.is_function(spec.config)
    end)

    it("should expose _module", function()
      assert.is_table(spec._module)
    end)
  end)

  describe("config function", function()
    it("should run without error", function()
      assert.has_no.errors(function() spec.config() end)
    end)
  end)
end)