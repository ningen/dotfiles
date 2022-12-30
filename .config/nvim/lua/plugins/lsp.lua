local status, nvim_lsp = pcall(require, 'lspconfig')
local status2, mason = pcall(require, 'mason')
local status3, mason_lspconfig = pcall(require, 'mason-lspconfig')
local status4, saga = pcall(require, 'lspsaga')

if (not status) then return end
if (not status2) then return end
if (not status3) then return end
if (not status4) then return end

local augroup_format = vim.api.nvim_create_augroup('Format', { clear = true })
local enable_format_on_save = function(_, bufnr)
  vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = augroup_format,
    buffer = bufnr,
    callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
  })
end

local on_attach = function(_, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  local opts = { noremap = true, silent = true }

  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

nvim_lsp.tsserver.setup {
  on_attach = on_attach,
  filetypes = { 'typescript', 'typescriptreact', 'typescript.tsx' },
  cmd = { 'typescript-language-server', '--stdio' },
  capabilities = capabilities
}

nvim_lsp.sumneko_lua.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    enable_format_on_save(client, bufnr)
  end,
  settings = {
    lua = {
      diagnostics = {
        globals = { 'vim' }
      },

      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      }
    },
  },
}

mason.setup({

})

mason_lspconfig.setup {
  ensure_installed = { 'sumneko_lua', 'tsserver' }
}

saga.init_lsp_saga {
  server_filetype_map = {
    typescript = 'typescript',
    lua = 'lua'
  },
  border_style = 'single',
  code_action_lightbulb = {
    enable = true,
  },
  symbol_in_winbar = {
    enable = true,
  },
  show_outline = {
    win_width = 50,
    auto_preview = false,
  }
}

local saga_opts = { silent = true }
vim.keymap.set('n', '<C-j>', '<Cmd>Lspsaga diagnostic_jump_next<CR>', saga_opts) -- 次の警告にジャンプ
vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', saga_opts) -- 選択中のもののドキュメントを表示
vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', saga_opts) -- 宣言元や使用されている場所を表示
vim.keymap.set('n', '<leader>ca', '<Cmd>Lspsaga code_action<CR>', saga_opts)
vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', saga_opts) -- rename
vim.keymap.set('n', '<C-s>', '<Cmd>Lspsaga open_floaterm<CR>', saga_opts) -- ターミナルを開く
vim.keymap.set('t', '<C-q>', [[ <C-\><C-n><cmd>Lspsaga close_floaterm<CR>]], saga_opts) -- ターミナルを閉じる
