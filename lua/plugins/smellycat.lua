return {
  url = "https://codeberg.org/mraspaud/smellycat.nvim",
  enabled = true,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    local ok, smellycat = pcall(require, "smellycat")
    if ok and type(smellycat.setup) == "function" then
      smellycat.setup()
    end
  end,
}
