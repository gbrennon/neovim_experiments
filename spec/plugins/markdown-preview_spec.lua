-- Tests for plugins/markdown-preview.lua
local spec_helper = require("spec_helper")

describe("plugins.markdown-preview", function()
  local spec

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.markdown-preview"] = nil
    spec = require("plugins.markdown-preview")
  end)

  it("should return a valid lazy.nvim spec", function()
    assert.is_table(spec)
    assert.equals("iamcco/markdown-preview.nvim", spec[1])
  end)

  it("should lazy-load on markdown filetype", function()
    assert.is_table(spec.ft)
    assert.is_true(vim.tbl_contains(spec.ft, "markdown"))
  end)

  it("should define commands", function()
    assert.is_table(spec.cmd)
    assert.is_true(vim.tbl_contains(spec.cmd, "MarkdownPreviewToggle"))
  end)

  it("should set build command", function()
    assert.equals("cd app && yarn install", spec.build)
  end)
end)