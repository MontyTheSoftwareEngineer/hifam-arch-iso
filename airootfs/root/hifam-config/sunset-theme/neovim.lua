return {
  {
    "tahayvr/sunset-drive.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("sunsetdrive").colorscheme()
    end,
  },
}

