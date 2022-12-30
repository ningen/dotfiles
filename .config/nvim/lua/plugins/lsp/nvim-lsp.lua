local status, nvim_lsp = pcall(require, 'lspconfig')

if (not status) then return end

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
