return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    require("bufferline").setup {
      options = {
        numbers = "ordinal",
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    }

    vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local prev = vim.fn.bufnr("#") -- previous buffer

    if prev == -1 or not vim.api.nvim_buf_is_valid(prev) then
      return
    end

    -- Skip special buffers
    if vim.bo[prev].buftype ~= "" then
      return
    end

    -- Skip modified buffers
    if vim.bo[prev].modified then
      return
    end

    -- Skip if still visible in any window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == prev then
        return
      end
    end

    -- Delete safely
    vim.schedule(function()
      pcall(vim.api.nvim_buf_delete, prev, {})
    end)
  end,
})
  end,
}
