-- Tests for core/keymaps.lua
local spec_helper = require("spec_helper")

describe("core.keymaps", function()
  local keymaps
  
  before_each(function()
    -- Reset mock before each test
    spec_helper.reset_vim_mock()
    -- Clear require cache to get fresh module
    package.loaded["core.keymaps"] = nil
    keymaps = require("core.keymaps")
  end)
  
  describe("setup function", function()
    it("should exist", function()
      assert.is_function(keymaps.setup)
    end)
    
    it("should set leader keys", function()
      keymaps.setup()
      assert.equals(",", vim.g.mapleader)
      assert.equals(",", vim.g.maplocalleader)
    end)
    
    it("should set general keymaps", function()
      keymaps.setup()
      
      -- Check that keymaps were set
      local expected_maps = {
        { mode = "n", lhs = "<leader>w", rhs = ":w<CR>" },
        { mode = "n", lhs = "<leader>q", rhs = ":q<CR>" },
        { mode = "n", lhs = "<leader>W", rhs = ":wa<CR>" },
        { mode = "n", lhs = "<leader>Q", rhs = ":qa!<CR>" },
        { mode = "n", lhs = "<leader><Space>", rhs = ":nohlsearch<CR>" },
      }
      
      for _, map in ipairs(expected_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "Keymap " .. map.lhs .. " should be set")
        if type(keymap.rhs) == "string" then
          assert.equals(map.rhs, keymap.rhs, "Keymap " .. map.lhs .. " should have correct rhs")
        end
      end
    end)
    
    it("should set buffer navigation keymaps", function()
      keymaps.setup()
      
      local expected_maps = {
        { mode = "n", lhs = "<leader>n", rhs = ":bnext<CR>" },
        { mode = "n", lhs = "<leader>N", rhs = ":bprevious<CR>" },
        { mode = "n", lhs = "<leader>bd", rhs = ":bdelete<CR>" },
      }
      
      for _, map in ipairs(expected_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "Buffer keymap " .. map.lhs .. " should be set")
      end
    end)
    
    it("should set window navigation keymaps", function()
      keymaps.setup()
      
      local expected_maps = {
        { mode = "n", lhs = "<C-h>", rhs = "<C-w>h" },
        { mode = "n", lhs = "<C-j>", rhs = "<C-w>j" },
        { mode = "n", lhs = "<C-k>", rhs = "<C-w>k" },
        { mode = "n", lhs = "<C-l>", rhs = "<C-w>l" },
      }
      
      for _, map in ipairs(expected_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "Window keymap " .. map.lhs .. " should be set")
      end
    end)
    
    it("should set file explorer keymaps", function()
      keymaps.setup()
      
      local expected_maps = {
        { mode = "n", lhs = "<F3>" },
        { mode = "n", lhs = "<leader>e" },
        { mode = "n", lhs = "<leader>fe" },
      }
      
      for _, map in ipairs(expected_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "File explorer keymap " .. map.lhs .. " should be set")
      end
    end)
    
    it("should set telescope keymaps", function()
      keymaps.setup()
      
      local telescope_maps = {
        "<leader>ff", "<leader>fg", "<leader>fb", "<leader>fh",
        "<leader>fr", "<leader>fc", "<leader>fk"
      }
      
      for _, lhs in ipairs(telescope_maps) do
        local keymap = vim.keymap._get_keymap("n", lhs)
        assert.is_not_nil(keymap, "Telescope keymap " .. lhs .. " should be set")
      end
    end)
    
    it("should set visual mode keymaps", function()
      keymaps.setup()
      
      local visual_maps = {
        { mode = "v", lhs = "<" },
        { mode = "v", lhs = ">" },
        { mode = "v", lhs = "J" },
        { mode = "v", lhs = "K" },
      }
      
      for _, map in ipairs(visual_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "Visual keymap " .. map.lhs .. " should be set")
      end
    end)
    
    it("should set navigation improvement keymaps", function()
      keymaps.setup()
      
      local nav_maps = {
        { mode = "n", lhs = "<C-d>" },
        { mode = "n", lhs = "<C-u>" },
        { mode = "n", lhs = "n" },
        { mode = "n", lhs = "N" },
        { mode = "i", lhs = "jk" },
        { mode = "i", lhs = "<Tab>" },
        { mode = "i", lhs = "<S-Tab>" },
        { mode = "n", lhs = "<C-a>" },
      }
      
      for _, map in ipairs(nav_maps) do
        local keymap = vim.keymap._get_keymap(map.mode, map.lhs)
        assert.is_not_nil(keymap, "Navigation keymap " .. map.lhs .. " should be set")
      end
    end)
  end)
  
  describe("lsp_on_attach function", function()
    it("should exist", function()
      assert.is_function(keymaps.lsp_on_attach)
    end)
    
    it("should set LSP keymaps for buffer", function()
      local bufnr = 1
      keymaps.lsp_on_attach(bufnr)
      
      local lsp_maps = {
        "gd", "gD", "gi", "gr", "K", "<leader>rn",
        "<leader>ca", "[d", "]d", "<leader>dl",
        "<leader>qf", "<leader>f"
      }
      
      for _, lhs in ipairs(lsp_maps) do
        local keymap = vim.keymap._get_keymap("n", lhs)
        assert.is_not_nil(keymap, "LSP keymap " .. lhs .. " should be set")
        -- Check that the keymap is buffer-specific
        assert.equals(bufnr, keymap.buffer, "LSP keymap " .. lhs .. " should be buffer-specific")
      end
    end)
  end)
  
  describe("nvimtree_on_attach function", function()
    it("should exist", function()
      assert.is_function(keymaps.nvimtree_on_attach)
    end)
    
    it("should set nvim-tree keymaps for buffer", function()
      -- Mock nvim-tree.api
      package.loaded["nvim-tree.api"] = {
        config = { mappings = { default_on_attach = function() end } },
        fs = {
          create = function() end,
          remove = function() end,
          rename = function() end,
          rename_sub = function() end,
          cut = function() end,
          paste = function() end,
        },
        node = {
          open = {
            edit = function() end,
            vertical = function() end,
            horizontal = function() end,
          }
        },
        live_filter = {
          start = function() end,
          clear = function() end,
        }
      }
      
      local bufnr = 1
      keymaps.nvimtree_on_attach(bufnr)
      
      local tree_maps = {
        "a", "d", "r", "m", "x", "p", "v", "s",
        "<CR>", "o", "/", "f"
      }
      
      for _, lhs in ipairs(tree_maps) do
        local keymap = vim.keymap._get_keymap("n", lhs)
        assert.is_not_nil(keymap, "nvim-tree keymap " .. lhs .. " should be set")
      end
    end)
  end)
  
  it("should auto-run setup when loaded", function()
    -- This test verifies that setup() is called automatically
    assert.equals(",", vim.g.mapleader)
  end)
end)