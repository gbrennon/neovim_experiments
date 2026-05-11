return {
  "sjl/badwolf",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("badwolf")
    vim.api.nvim_set_hl(0, "CursorLine", { fg = "#d65d0e", bg = "#2a2a2a", bold = true })
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#d65d0e", bold = true })
    vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { fg = "#d65d0e", bg = "#2a2a2a", bold = true })
    vim.api.nvim_set_hl(0, "StatusLine", { fg = "#000000", bg = "#d65d0e" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#ffffff", bg = "#45413b" })
  end,
}
