-- Tests for plugins/telescope.lua
local spec_helper = require("spec_helper")

describe("plugins.telescope", function()
  local spec

  local function make_telescope_mock()
    local mock = { _setup_opts = nil }
    mock.setup = function(opts) mock._setup_opts = opts end
    return mock
  end

  local function make_actions_mock()
    return { close = function() end }
  end

  local telescope_mock, actions_mock

  before_each(function()
    spec_helper.reset_vim_mock()
    package.loaded["plugins.telescope"] = nil

    telescope_mock = make_telescope_mock()
    actions_mock = make_actions_mock()

    package.loaded["telescope"] = telescope_mock
    package.loaded["telescope.actions"] = actions_mock

    spec = require("plugins.telescope")
  end)

  after_each(function()
    package.loaded["plugins.telescope"] = nil
    package.loaded["telescope"] = nil
    package.loaded["telescope.actions"] = nil
  end)

  --------------------------------------------------------------------------
  -- Plugin spec structure
  --------------------------------------------------------------------------

  describe("plugin spec", function()
    it("should return a valid lazy.nvim spec", function()
      assert.is_table(spec)
      assert.equals("nvim-telescope/telescope.nvim", spec[1])
    end)

    it("should depend on plenary.nvim", function()
      assert.is_true(vim.tbl_contains(spec.dependencies, "nvim-lua/plenary.nvim"))
    end)

    it("should lazy-load on Telescope command", function()
      assert.equals("Telescope", spec.cmd)
    end)

    it("should have config function", function()
      assert.is_function(spec.config)
    end)
  end)

  --------------------------------------------------------------------------
  -- Keybindings
  --------------------------------------------------------------------------

  describe("keys", function()
    it("should define keys table", function()
      assert.is_table(spec.keys)
    end)

    local expected_keys = {
      { lhs = "<leader>ff", desc = "Find Files" },
      { lhs = "<leader>fg", desc = "Live Grep" },
      { lhs = "<leader>fb", desc = "Buffers" },
      { lhs = "<leader>fh", desc = "Help" },
      { lhs = "<leader>fr", desc = "Recent Files" },
      { lhs = "<leader>fc", desc = "Commands" },
      { lhs = "<leader>fk", desc = "Keymaps" },
    }

    for _, expected in ipairs(expected_keys) do
      it("should define keymap " .. expected.lhs .. " (" .. expected.desc .. ")", function()
        local found = false
        for _, k in ipairs(spec.keys) do
          if k[1] == expected.lhs then
            found = true
            assert.equals(expected.desc, k.desc)
            break
          end
        end
        assert.is_true(found, expected.lhs .. " not found in keys")
      end)
    end

    it("should have exactly 7 keymaps", function()
      assert.equals(7, #spec.keys)
    end)

    it("all keys should have an lhs string", function()
      for _, k in ipairs(spec.keys) do
        assert.is_string(k[1])
      end
    end)

    it("all keys should have a desc string", function()
      for _, k in ipairs(spec.keys) do
        assert.is_string(k.desc)
      end
    end)
  end)

  --------------------------------------------------------------------------
  -- config function
  --------------------------------------------------------------------------

  describe("config function", function()
    it("should run without error", function()
      assert.has_no.errors(function() spec.config() end)
    end)

    it("should call telescope.setup", function()
      spec.config()
      assert.is_not_nil(telescope_mock._setup_opts)
    end)

    it("should configure insert mode mappings", function()
      spec.config()
      local i_maps = telescope_mock._setup_opts.defaults.mappings.i
      assert.is_not_nil(i_maps)
    end)

    it("should disable <C-u> in insert mode", function()
      spec.config()
      local i_maps = telescope_mock._setup_opts.defaults.mappings.i
      assert.is_false(i_maps["<C-u>"])
    end)

    it("should disable <C-d> in insert mode", function()
      spec.config()
      local i_maps = telescope_mock._setup_opts.defaults.mappings.i
      assert.is_false(i_maps["<C-d>"])
    end)

    it("should bind <esc> to actions.close", function()
      spec.config()
      local i_maps = telescope_mock._setup_opts.defaults.mappings.i
      assert.equals(actions_mock.close, i_maps["<esc>"])
    end)
  end)

  --------------------------------------------------------------------------
  -- Color customization (matching kitty cursor #d65d0e)
  --------------------------------------------------------------------------

  describe("color customization", function()
    it("should set TelescopeSelection to orange (#d65d0e)", function()
      spec.config()
      local hl = vim.api.nvim_get_hl(0, { name = "TelescopeSelection" })
      assert.equals("#d65d0e", string.format("#%06x", hl.fg))
      assert.equals("#2a2a2a", string.format("#%06x", hl.bg))
      assert.equals(true, hl.bold)
    end)

    it("should set TelescopeSelectionCaret to orange (#d65d0e)", function()
      spec.config()
      local hl = vim.api.nvim_get_hl(0, { name = "TelescopeSelectionCaret" })
      assert.equals("#d65d0e", string.format("#%06x", hl.fg))
    end)
  end)
end)
