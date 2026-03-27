return {
  url = "https://codeberg.org/mraspaud/smellycat.nvim",
  enabled = true,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("smellycat").setup()
  end,
}
