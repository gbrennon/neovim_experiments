-- Colorizer (color preview in all files)

local M = {}

M.default_options = {
  RGB = true,
  RRGGBB = true,
  names = false,
  RRGGBBAA = true,
  AARRGGBB = true,
  rgb_fn = true,
  hsl_fn = true,
  css = true,
  css_fn = true,
  mode = "background",
  tailwind = false,
  sass = { enable = false },
  virtualtext = "â– ",
  always_update = false,
}

function M.config()
  require("colorizer").setup({
    filetypes = { "*" },
    user_default_options = M.default_options,
  })
end

-- Plugin spec for lazy.nvim
return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  config = M.config,
  _module = M,
}
