return {
    "numToStr/Comment.nvim",
    opts = {},
    config = function(_, opts)
        local api = require("Comment.api")
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

        require("Comment").setup(opts)

        vim.keymap.set("n", "<leader>/", api.locked("toggle.linewise.current"), {
            silent = true,
            desc = "Toggle comment",
        })

        vim.keymap.set("x", "<leader>/", function()
            vim.api.nvim_feedkeys(esc, "nx", false)
            api.locked("toggle.linewise")(vim.fn.visualmode())
        end, {
            silent = true,
            desc = "Toggle comment",
        })
    end,
}
