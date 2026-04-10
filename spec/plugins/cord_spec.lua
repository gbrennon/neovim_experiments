-- Tests for plugins/cord.lua
local spec_helper = require("spec_helper")

describe("plugins.cord", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.cord"] = nil
    spec = require("plugins.cord")
  end)

  it("should return a valid lazy.nvim spec", function()
    assert.is_table(spec)
    assert.equals("vyfor/cord.nvim", spec[1])
  end)

  it("should have opts with display theme", function()
    assert.is_table(spec.opts)
    assert.is_table(spec.opts.display)
    assert.equals("void", spec.opts.display.theme)
  end)
end)