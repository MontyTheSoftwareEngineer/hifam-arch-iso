return {
    'fedepujol/move.nvim',
    config = function()
        -- Plugin setup with default options
        require('move').setup({
            line = {
                enable = true,  -- Enables line movement
                indent = true   -- Toggles indentation during movement
            },
            block = {
                enable = true,  -- Enables block movement
                indent = true   -- Toggles indentation during movement
            },
            word = {
                enable = true   -- Enables word movement
            },
            char = {
                enable = false  -- Enables character movement (disabled by default)
            }
        })

        -- Key mappings for normal and visual modes
        local opts = { noremap = true, silent = true }

        -- Normal-mode mappings for moving lines, words, and characters
        vim.keymap.set('n', 'K', ':MoveLine(-1)<CR>', opts)
        vim.keymap.set('n', 'J', ':MoveLine(1)<CR>', opts)

        vim.keymap.set('v', 'K', ':MoveBlock(-1)<CR>', opts)
        vim.keymap.set('v', 'J', ':MoveBlock(1)<CR>', opts)
    end
}

