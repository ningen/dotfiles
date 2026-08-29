vim.diagnostic.config({
  virtual_text = true,
})

local lsp_augroup = vim.api.nvim_create_augroup('lsp-attach', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_augroup,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, {
        buffer = args.buf,
        desc = desc,
      })
    end

    -- 移動
    map('gd', vim.lsp.buf.definition, '定義へ')
    map('gD', vim.lsp.buf.declaration, '宣言へ')
    map('gr', vim.lsp.buf.references, '参照一覧')
    map('gi', vim.lsp.buf.implementation, '実装へ')

    -- 情報表示
    map('K', vim.lsp.buf.hover, 'ホバー情報')
    map('<C-k>', vim.lsp.buf.signature_help, 'シグネチャ')

    -- コード操作
    map('<leader>cr', vim.lsp.buf.rename, 'リネーム')
    map('<leader>ca', vim.lsp.buf.code_action, 'アクション')
    map('<leader>cf', vim.lsp.buf.format, 'フォーマット')

    -- 診断
    map('[d', vim.diagnostic.goto_prev, '前の診断')
    map(']d', vim.diagnostic.goto_next, '次の診断')
    map('<leader>cd', vim.diagnostic.open_float, '診断を表示')

    map('<leader>ft', function()
      vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
    end, 'Format buffer')
  end,
})

vim.lsp.config('*', {
  root_markers = { '.git' },
})

local lua_ls_opts = require('lsp.lua_ls')

vim.lsp.config('lua_ls', lua_ls_opts)
vim.lsp.enable('lua_ls')
