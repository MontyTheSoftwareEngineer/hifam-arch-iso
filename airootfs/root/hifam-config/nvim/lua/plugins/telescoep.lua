return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    require("telescope").setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            width = 0.98,
            preview_width = 0.55,
          },
        },
      },
    })

    local builtin = require("telescope.builtin")

    -- File & search
    vim.keymap.set("n", "<leader>k", builtin.find_files, { desc = "Find Files" })
    vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Live Grep" })
    vim.keymap.set("n", "<leader>s", builtin.current_buffer_fuzzy_find, { desc = "Search Current Buffer" })

    -- LSP
    vim.keymap.set("n", "<leader>r", builtin.lsp_references, { desc = "LSP References" })
    vim.keymap.set("n", "<leader>o", function()
      builtin.lsp_document_symbols({
        truncate = false,
        symbol_width = 80,
        symbol_type_width = 10,
      })
    end, { desc = "Document Symbols" })
  end,
}
