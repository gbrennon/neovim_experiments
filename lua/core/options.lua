-- Neovim Options Configuration

local M = {}

function M.setup()
  local opt = vim.opt

  -- Line numbers
  opt.number = true
  opt.relativenumber = true

  -- Tabs & indentation
  opt.tabstop = 2
  opt.shiftwidth = 2
  opt.expandtab = true
  opt.autoindent = true
  opt.smartindent = true

  -- Line wrapping
  opt.wrap = false

  -- Search settings
  opt.ignorecase = true
  opt.smartcase = true
  opt.hlsearch = true
  opt.incsearch = true

  -- Cursor line - match kitty cursor color #d65d0e
  opt.cursorline = true
  opt.cursorlineopt = "screenline"

  -- Appearance
  opt.termguicolors = true
  opt.background = "dark"
  opt.signcolumn = "yes"

  -- Backspace
  opt.backspace = "indent,eol,start"

  -- Clipboard
  opt.clipboard = "unnamedplus"

  -- Split windows
  opt.splitright = true
  opt.splitbelow = true

  -- Disable swap and backup
  opt.swapfile = false
  opt.backup = false
  opt.writebackup = false

  -- Undo history
  opt.undofile = true

  -- Update time (faster for auto-refresh)
  opt.updatetime = 250  -- Trigger CursorHold events faster for auto-refresh
  opt.timeoutlen = 300

  -- Scroll offset
  opt.scrolloff = 8
  opt.sidescrolloff = 8

  -- Completion
  opt.completeopt = "menuone,noselect"

  -- Mouse
  opt.mouse = "a"

  -- Encoding
  opt.encoding = "utf-8"
  opt.fileencoding = "utf-8"

  -- Command line height
  opt.cmdheight = 1

  -- Show matching brackets
  opt.showmatch = true

  -- Disable netrw (using nvim-tree instead)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- Auto-read files when changed outside of Neovim
  opt.autoread = true

  -- Disable LSP logging in normal use (set to DEBUG only when troubleshooting)
  vim.lsp.set_log_level("OFF")
end

-- Auto-run setup when loaded
M.setup()

return M
