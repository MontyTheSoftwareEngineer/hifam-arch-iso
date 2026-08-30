return {
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "*", -- all filetypes
      }, {
        RGB = true,      -- #RGB
        RRGGBB = true,   -- #RRGGBB
        names = true,   -- "red" etc (optional)
        RRGGBBAA = true, -- #RRGGBBAA
        rgb_fn = true,   -- rgb(255,0,0)
        hsl_fn = true,   -- hsl(150, 50%, 40%)
      })
    end,
  },
}
