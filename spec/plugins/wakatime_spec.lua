-- Tests for plugins/wakatime.lua
local spec_helper = require("spec_helper")

describe("plugins.wakatime", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.wakatime"] = nil
    spec = require("plugins.wakatime")
  end)

  it("should return a valid lazy.nvim spec", function()
    assert.is_table(spec)
    assert.equals("wakatime/vim-wakatime", spec[1])
  end)

  it("should be lazy-loaded", function()
    assert.is_false(spec.lazy)
  end)
end)