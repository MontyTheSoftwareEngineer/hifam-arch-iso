return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    config = function()
        require('render-markdown').setup()

        -- Keybinding to toggle markdown preview
        vim.api.nvim_set_keymap('n', '<leader>me', ':RenderMarkdown enable<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>md', ':RenderMarkdown disable<CR>', { noremap = true, silent = true })
    end,
}

