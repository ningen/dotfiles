local status, mason = pcall(require, 'mason')
local status2, mason_lspconfig = pcall(require, 'mason-lspconfig')

if (not status) then return end
if (not status2) then return end

mason.setup({

})

mason_lspconfig.setup {
  ensure_installed = { 'sumneko_lua', 'tsserver' }
}
