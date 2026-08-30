return {
  {
    "dstein64/nvim-scrollview",
    config = function()
      require("scrollview").setup({
        signs_on_startup = { "all" },
        current_only = true, -- Only show scrollbar in the active window
        winblend = 75, -- Transparency (0 = opaque, 100 = fully transparent)
        base = "right", -- Scrollbar position
        column = 1, -- Distance from the right edge
        excluded_filetypes = { "NvimTree", "neo-tree", "alpha", "packer" },
      })

    end,
  }
}
