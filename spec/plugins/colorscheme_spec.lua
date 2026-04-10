-- Tests for plugins/colorscheme.lua
local spec_helper = require("spec_helper")

describe("plugins.colorscheme", function()
  local colorscheme_config
  
  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.colorscheme"] = nil
    colorscheme_config = require("plugins.colorscheme")
  end)
  
  it("should return a valid lazy.nvim plugin spec", function()
    assert.is_table(colorscheme_config)
    assert.equals("sjl/badwolf", colorscheme_config[1])
  end)
  
  it("should set lazy to false", function()
    assert.is_false(colorscheme_config.lazy)
  end)
  
  it("should have high priority", function()
    assert.equals(1000, colorscheme_config.priority)
  end)
  
  it("should have a config function", function()
    assert.is_function(colorscheme_config.config)
  end)
  
  describe("config function", function()
    it("should set badwolf colorscheme", function()
      local cmd_called = false
      local cmd_arg = nil
      
      -- Mock vim.cmd.colorscheme
      vim.cmd.colorscheme = function(scheme)
        cmd_called = true
        cmd_arg = scheme
      end
      
      colorscheme_config.config()
      
      assert.is_true(cmd_called, "vim.cmd.colorscheme should be called")
      assert.equals("badwolf", cmd_arg)
    end)

    it("should set CursorLine to orange (#d65d0e)", function()
      colorscheme_config.config()
      local hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
      assert.equals("#d65d0e", string.format("#%06x", hl.fg))
    end)

    it("should set CursorLineNr to orange (#d65d0e)", function()
      colorscheme_config.config()
      local hl = vim.api.nvim_get_hl(0, { name = "CursorLineNr" })
      assert.equals("#d65d0e", string.format("#%06x", hl.fg))
    end)

    it("should set NvimTreeCursorLine to orange (#d65d0e)", function()
      colorscheme_config.config()
      local hl = vim.api.nvim_get_hl(0, { name = "NvimTreeCursorLine" })
      assert.equals("#d65d0e", string.format("#%06x", hl.fg))
    end)

    it("should set StatusLine to orange (#d65d0e)", function()
      colorscheme_config.config()
      local hl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
      assert.equals("#d65d0e", string.format("#%06x", hl.bg))
    end)

    it("should set StatusLineNC to gray (#45413b)", function()
      colorscheme_config.config()
      local hl = vim.api.nvim_get_hl(0, { name = "StatusLineNC" })
      assert.equals("#45413b", string.format("#%06x", hl.bg))
    end)
  end)
end)