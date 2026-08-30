vim.opt.nu = true
vim.opt.number = true
--vim.opt.relativenumber = true
vim.cmd("set expandtab")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "
vim.opt.autoread = true

vim.keymap.set("n", "j", "jzz", { noremap = true })
vim.keymap.set("n", "k", "kzz", { noremap = true })

vim.keymap.set('n', '<leader>p', ':Neotree toggle<CR>', {})
vim.keymap.set('n', '<leader>o', ':SymbolsOutline<CR>', { noremap = true, silent = true, desc = 'Toggle Symbols Outline' })
vim.keymap.set({'n','v'}, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Copy to clipboard' })

vim.keymap.set("n", "<leader>bl", ":BufferLinePick<CR>", { noremap = true, silent = true }) -- Pick a buffer
vim.keymap.set("n", "<leader>bd", ":BufferLinePickClose<CR>", { noremap = true, silent = true }) -- Delete buffer

-- Map the ">" key to indent the selected lines in visual mode
vim.api.nvim_set_keymap('x', '>', '>gv', { noremap = true, silent = true })
-- Optionally, map "<" for un-indenting if you want the same behavior
vim.api.nvim_set_keymap('x', '<', '<gv', { noremap = true, silent = true })

-- Resize splits with Alt + h/j/k/l
vim.keymap.set("n", "<A-h>", "<cmd>vertical resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-l>", "<cmd>vertical resize +2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-j>", "<cmd>resize +1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", "<cmd>resize -1<CR>", { noremap = true, silent = true })

vim.opt.timeoutlen = 300 -- 300ms to trigger 'jk' as escape
vim.keymap.set({'i', 'v', 'n'}, 'jk', '<Esc>', { noremap = true, silent = true })


vim.g.wiki_root = '~/Documents/HiFam/'
-- Auto-delete hidden buffers (no swaps, no prompts)
vim.api.nvim_create_autocmd("BufLeave", {
  callback = function(args)
    local buf = args.buf

    -- Skip special buffers (terminal, help, etc.)
    if vim.bo[buf].buftype ~= "" then
      return
    end

    -- Skip modified buffers
    if vim.bo[buf].modified then
      return
    end

    -- Check if buffer is still visible in any window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return -- still visible somewhere (like another split)
      end
    end

    -- Delete safely (scheduled to avoid timing issues)
    vim.schedule(function()
      pcall(vim.api.nvim_buf_delete, buf, { force = false })
    end)
  end,
})
-- Enhanced file watching and auto-reload settings
     vim.opt.autoread = true          -- Auto read file when changed outside vim
     vim.opt.updatetime = 300         -- Faster update time (default 4000ms)
     vim.opt.swapfile = false         -- Disable swapfiles to avoid conflicts
     vim.opt.backup = false           -- Don't create backup files
     vim.opt.writebackup = false      -- Don't create backup while editing

-- Auto-reload files when they change externally
     vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
       pattern = "*",
       callback = function()
         if vim.fn.mode() ~= 'c' then
           vim.cmd('checktime')
         end
       end,
     })


 -- Notification when file is auto-reloaded
     vim.api.nvim_create_autocmd("FileChangedShellPost", {
       pattern = "*",
       callback = function()
         vim.notify("File reloaded: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
       end,
     })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end


local opts = {}

-- vim.o.background = "dark"
vim.o.termguicolors = true
vim.opt.rtp:prepend(lazypath)
--require ("black_green")
require("lazy").setup("plugins")

-- Colorscheme is set by the mapledark plugin

-- Active/inactive window highlighting
vim.api.nvim_create_autocmd({"WinEnter", "BufWinEnter"}, {
  callback = function()
    vim.wo.winhl = "Normal:Normal,EndOfBuffer:Normal,SignColumn:Normal"
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    vim.wo.winhl = "Normal:NormalNC,EndOfBuffer:NormalNC,SignColumn:NormalNC"
  end,
})

-- Set up the inactive window highlight group
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Set active pane to light grey background
    vim.api.nvim_set_hl(0, "Normal", { bg = "#2a2a2a" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#2a2a2a" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "#2a2a2a" })
    -- Set inactive panes to solid black background
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
  end,
})

-- Apply the colors immediately
vim.api.nvim_set_hl(0, "Normal", { bg = "#2a2a2a" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#2a2a2a" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#2a2a2a" })
