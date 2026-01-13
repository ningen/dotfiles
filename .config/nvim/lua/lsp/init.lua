vim.diagnostic.config({
  virtual_text = true,
})

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup("lsp/init.lua", {})

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- ========================================
    -- LSP - "g" = Go to, "K" = 情報
    -- ========================================

    -- 移動系 (Go to)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "定義へ" })
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "宣言へ" })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "参照一覧" })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "実装へ" })

    -- 情報表示 (K = Knowledge)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "ホバー情報" })
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "シグネチャ" })

    -- コード操作 (<leader>c = Code)
    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "リネーム" })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "アクション" })
    vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "フォーマット" })

    -- 診断 ([/] = 前後移動の慣習)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "前の診断" })
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "次の診断" })
    vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "診断を表示" })

    vim.keymap.set("n", "<leader>ft", function()
      vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
    end, { buffer = args.buf, desc = "Format buffer" })
  end,
})

vim.lsp.config("*", {
  root_markers = { ".git" },
})

vim.lsp.enable("lua_ls")
vim.lsp.enable("tsserver")
vim.lsp.enable("pyright")
vim.lsp.enable("nil_ls")
vim.lsp.enable("hls")
vim.lsp.enable("gopls")
vim.lsp.enable("gleam")
