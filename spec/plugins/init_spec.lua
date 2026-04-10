-- Tests for plugins/init.lua
local spec_helper = require("spec_helper")

describe("plugins.init", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.init"] = nil
    spec = require("plugins.init")
  end)

  it("should return a table of plugin specs", function()
    assert.is_table(spec)
  end)

  it("should include colorscheme plugin", function()
    local found = false
    for _, p in ipairs(spec) do
      if p[1] == "sjl/badwolf" then
        found = true
        break
      end
    end
    assert.is_true(found, "colorscheme plugin not found")
  end)

  it("should include telescope plugin", function()
    local found = false
    for _, p in ipairs(spec) do
      if p[1] == "nvim-telescope/telescope.nvim" then
        found = true
        break
      end
    end
    assert.is_true(found, "telescope plugin not found")
  end)

  it("should include nvimtree plugin", function()
    local found = false
    for _, p in ipairs(spec) do
      if p[1] == "nvim-tree/nvim-tree.lua" then
        found = true
        break
      end
    end
    assert.is_true(found, "nvimtree plugin not found")
  end)
end)