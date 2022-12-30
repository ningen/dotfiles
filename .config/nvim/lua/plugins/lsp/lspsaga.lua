local status, saga = pcall(require, 'lspsaga')

if (not status) then return end

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
