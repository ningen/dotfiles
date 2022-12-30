-- lsp server management
require('mason').setup()

local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup {
  ensure_installed = { 'sumneko_lua', 'tsserver' }
}

mason_lspconfig.setup_handlers({function(server)
  local opt = {
    -- サーバ起動後に実行される関数
    capabilities = require('cmp_nvim_lsp').default_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )
  }
  require('lspconfig')[server].setup(opt)
end })

-- lsp keymaps
vim.keymap.set('n', 'K',  '<cmd>lua vim.lsp.buf.hover()<CR>') -- カーソル下の変数の情報を表示
vim.keymap.set('n', 'gf', '<cmd>lua vim.lsp.buf.formatting()<CR>') -- ファイルのフォーマットを行う
vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>') -- コード内で参照されている箇所を一覧表示
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>') -- 定義されている場所にジャンプする
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>') -- 宣言元にジャンプ(declaretionでいい) 
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>') -- 実装している場所にジャンプ
vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>') -- 型情報へジャンプ
vim.keymap.set('n', 'gn', '<cmd>lua vim.lsp.buf.rename()<CR>') -- 名前変更
vim.keymap.set('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')  -- Error, Warning, Hintが出ている場所で実行可能な修正の候補を表示
vim.keymap.set('n', 'ge', '<cmd>lua vim.diagnostic.open_float()<CR>')
vim.keymap.set('n', 'g]', '<cmd>lua vim.diagnostic.goto_next()<CR>') -- 次の警告にジャンプ?
vim.keymap.set('n', 'g[', '<cmd>lua vim.diagnostic.goto_prev()<CR>') -- 前の警告にジャンプ?

-- LSP handlers
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false }
)
-- Reference highlight
vim.cmd [[
set updatetime=500
highlight LspReferenceText  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
highlight LspReferenceRead  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
highlight LspReferenceWrite cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
augroup lsp_document_highlight
  autocmd!
  autocmd CursorHold,CursorHoldI * lua vim.lsp.buf.document_highlight()
  autocmd CursorMoved,CursorMovedI * lua vim.lsp.buf.clear_references()
augroup END
]]

-- 3. completion (hrsh7th/nvim-cmp)
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    -- { name = "buffer" },
    -- { name = "path" },
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ['<C-l>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm { select = true },
  }),
  experimental = {
    ghost_text = true,
  },
})
-- cmp.setup.cmdline('/', {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = 'buffer' }
--   }
-- })
-- cmp.setup.cmdline(":", {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = "path" },
--     { name = "cmdline" },
--   },
-- })
