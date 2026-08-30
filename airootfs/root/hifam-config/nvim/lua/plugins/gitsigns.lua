return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "" },
          change       = { text = "" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "" },
        },
        current_line_blame = false,
      })

      -- Keymap: preview hunk in a floating window
      vim.keymap.set("n", "<leader>hp", function()
        require("gitsigns").preview_hunk_inline()
      end, { desc = "Preview Git hunk" })
    end,
  },
}

