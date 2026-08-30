return {
  {
    "karb94/neoscroll.nvim",
    config = function()
      -- Setup neoscroll with desired options
      require("neoscroll").setup({
        easing_function = "quadratic", -- smooth acceleration/deceleration
        hide_cursor = true,           -- hide cursor while scrolling
        time_step = 75,               -- speed of scrolling (lower = faster)
      })

      -- Define custom scroll mappings for Ctrl + F and Ctrl + B
      local mappings = {
        ["<C-f>"] = { "<cmd>lua require('neoscroll').scroll(vim.wo.scroll, {move_cursor=true, duration=150})<CR>" },  -- scroll down
        ["<C-b>"] = { "<cmd>lua require('neoscroll').scroll(-vim.wo.scroll, {move_cursor=true, duration=150})<CR>" }, -- scroll up
      }

      -- Set custom mappings using helper function
      for keys, cmd in pairs(mappings) do
        vim.api.nvim_set_keymap("n", keys, cmd[1], { noremap = true, silent = true })
      end
    end,
  }
}


