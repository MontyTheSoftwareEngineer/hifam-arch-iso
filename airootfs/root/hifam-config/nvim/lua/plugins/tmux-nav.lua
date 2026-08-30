return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<CR>" },
      { "<C-j>", "<cmd><C-U>TmuxNavigateDown<CR>" },
      { "<C-k>", "<cmd><C-U>TmuxNavigateUp<CR>" },
      { "<C-l>", "<cmd><C-U>TmuxNavigateRight<CR>" },
      { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<CR>" },
      { "<C-h>", "<C-\\><C-n><cmd><C-U>TmuxNavigateLeft<CR>", mode = "t" },
      { "<C-j>", "<C-\\><C-n><cmd><C-U>TmuxNavigateDown<CR>", mode = "t" },
      { "<C-k>", "<C-\\><C-n><cmd><C-U>TmuxNavigateUp<CR>", mode = "t" },
      { "<C-l>", "<C-\\><C-n><cmd><C-U>TmuxNavigateRight<CR>", mode = "t" },
      { "<C-\\>", "<C-\\><C-n><cmd><C-U>TmuxNavigatePrevious<CR>", mode = "t" },
    },
  },
}
