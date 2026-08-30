return {
  url = "https://codeberg.org/andyg/leap.nvim",
  config = function()
    local leap = require('leap')
    -- Sneak-style mappings
    vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap-forward)')
    vim.keymap.set({'n', 'x', 'o'}, 'S', '<Plug>(leap-backward)')
    vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
    leap.opts.smart_case = true
  end,
}
