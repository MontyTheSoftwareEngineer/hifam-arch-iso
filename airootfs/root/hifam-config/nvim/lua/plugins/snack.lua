-- snacks.lua

return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        enabled = true, -- disable generic indent rendering
        scope = {
          enabled = true,
          only_current = true, -- only highlight current scope
          underline = true,
          priority = 200,
          char = "│",
          hl = "SnacksIndentScope",
        },
        chunk = {
          enabled = false,
        },
        animate = {
          enabled = false,
        },
        filter = function(buf)
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
        end,
      },
    },
  },
}

