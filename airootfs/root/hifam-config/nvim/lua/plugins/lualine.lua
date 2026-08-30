return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- For icons in the statusline
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto", -- Uses the current colorscheme
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {},
          always_divide_middle = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { { "filename", path = 1 } },
          lualine_c = {},
          lualine_x = { 
            {
              "diagnostics",
              symbols = { error = " ", warn = " ", info = " ", hint = " " }
            }
          },
          lualine_y = { 
            {
              "diff",
              symbols = { added = " ", modified = " ", removed = " " }
            },
            "branch"
          },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = { { "filename", path = 1 } },
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { "location" },
        },
        tabline = {},
        extensions = { "nvim-tree", "quickfix", "fugitive", "neo-tree" },
      })
    end,
  }
}
