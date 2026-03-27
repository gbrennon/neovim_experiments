local function normalize_path(path)
  return path:gsub("\\", "/")
end

local function normalize_cwd()
  return normalize_path(vim.loop.cwd()) .. "/"
end

local function is_subdirectory(cwd, path)
  return string.lower(path:sub(1, #cwd)) == string.lower(cwd)
end

local function split_filepath(path)
  local normalized_path = normalize_path(path)
  local normalized_cwd = normalize_cwd()
  local filename = normalized_path:match("[^/]+$")

  if is_subdirectory(normalized_cwd, normalized_path) then
    local stripped_path = normalized_path:sub(#normalized_cwd + 1, -(#filename + 1))
    return stripped_path, filename
  else
    local stripped_path = normalized_path:sub(1, -(#filename + 1))
    return stripped_path, filename
  end
end

local function path_display(_, path)
  local stripped_path, filename = split_filepath(path)
  if filename == stripped_path or stripped_path == "" then
    return filename
  end
  return string.format("%s ~ %s", filename, stripped_path)
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  cmd = "Telescope",

  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
    { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
  },

  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = path_display,
        mappings = {
          i = {
            ["<C-u>"] = false,
            ["<C-d>"] = false,
            ["<esc>"] = actions.close,
          },
        },
        file_ignore_patterns = {
          "%.git/",
          "node_modules",
          "dist",
          "build",
          "target",
          "vendor",
          "%.lock",
          "%.log",
          "%.cache",
          "__pycache__",
          ".env",
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          no_ignore = true
        },
        live_grep = {
          theme = "dropdown",
          additional_args = { "--hidden" },
        },
        buffers = {
          theme = "dropdown",
          previewer = false,
        },
        help_tags = {
          theme = "dropdown",
        },
        oldfiles = {
          theme = "dropdown",
        },
        commands = {
          theme = "dropdown",
        },
        keymaps = {
          theme = "dropdown",
        },
      },
    })
  end,
}
