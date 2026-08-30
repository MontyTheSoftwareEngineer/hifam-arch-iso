return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local function on_attach(client, bufnr)
        local function buf_set_keymap(...) 
          vim.api.nvim_buf_set_keymap(bufnr, ...) 
        end
        local opts = { noremap=true, silent=true }

        -- Setup keybindings for LSP features
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)  -- Go to Definition
        buf_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)   -- Show References
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)  -- Go to Declaration
        buf_set_keymap('n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts)  -- Go to Implementation
        buf_set_keymap('n', 'gn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)  -- Rename Symbol

        -- Optionally, setup completion with nvim-cmp
        require'cmp'.setup.buffer { enabled = true }
      end

      -- Setup clangd LSP for C++
      vim.lsp.config.clangd = {
        cmd = { 'clangd' },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
        on_attach = on_attach,
      }

      -- Setup rust_analyzer LSP for Rust
      vim.lsp.config.rust_analyzer = {
        cmd = { 'rust-analyzer' },
        filetypes = { 'rust' },
        on_attach = on_attach,
      }

      -- Setup marksman LSP for Markdown
      vim.lsp.config.marksman = {
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown', 'markdown.mdx' },
        on_attach = on_attach,
      }

      -- Setup lua_ls for Lua (fixes undefined 'vim' warnings)
      vim.lsp.config.lua_ls = {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      }

      -- Setup qmlls LSP for QML
      vim.lsp.config.qmlls = {
        cmd = { 'qmlls' },
        filetypes = { 'qml', 'qmljs' },
        on_attach = on_attach,
      }

      -- Diagnostics configuration (optional, disable virtual text)
      vim.diagnostic.config({ virtual_text = true })
    end,
  }
}

