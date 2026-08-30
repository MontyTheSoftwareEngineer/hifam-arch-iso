return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>z",
        function()
          require("yazi").yazi()
        end,
        desc = "Open Yazi file manager",
      },
    },
    opts = {
      open_for_directories = false,
    },
  },
}
