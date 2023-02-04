local status, mason = pcall(require, 'mason')
local status2, mason_lspconfig = pcall(require, 'mason-lspconfig')

if (not status) then return end
if (not status2) then return end

mason.setup({

})

mason_lspconfig.setup {
  ensure_installed = { 'sumneko_lua', 'denols', 'tsserver', 'marksman', 'hls' },
  automatic_installation = true
}


local status3, nvim_lsp = pcall(require, 'lspconfig')
vim.lsp.set_log_level('debug')

if (not status3) then return end

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

vim.lsp.protocol.CompletionItemKind = {
  '', -- Text
  '', -- Method
  '', -- Function
  '', -- Constructor
  '', -- Field
  '', -- Variable
  '', -- Class
  'ﰮ', -- Interface
  '', -- Module
  '', -- Property
  '', -- Unit
  '', -- Value
  '', -- Enum
  '', -- Keyword
  '﬌', -- Snippet
  '', -- Color
  '', -- File
  '', -- Reference
  '', -- Folder
  '', -- EnumMember
  '', -- Constant
  '', -- Struct
  '', -- Event
  'ﬦ', -- Operator
  '', -- TypeParameter
}

mason_lspconfig.setup_handlers({
  function(server_name)
    local node_root_dir = nvim_lsp.util.root_pattern('package.json')
    local is_node_repo = node_root_dir(vim.api.nvim_buf_get_name(0)) ~= nil

    local opts = {}

    if server_name == 'tsserver' then
      if not is_node_repo then return end
    end

    if server_name == 'denols' then
      if is_node_repo then return end
    end


    if server_name == 'sumneko_lua' then
      opts = {
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          enable_format_on_save(client, bufnr)
        end,
        settings = {
          Lua = {
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
    end

    if server_name == 'tsserver' then
      opts = {
        root_dir = nvim_lsp.util.root_pattern('package.json'),
        on_attach = on_attach,
        init_options = {
          hostinfo = 'neovim'
        },
        cmd = { 'typescript-language-server', '--stdio' },
        capabilities = capabilities,
      }
    end

    if server_name == 'denols' then
      opts = {
        cmd = { 'deno', 'lsp' },
        init_options = {
          lint = true,
          unstable = true,
          suggest = {
            imports = {
              ["https://deno.land"] = true,
              ["https://cdn.nest.land"] = true,
              ["https://crux.land"] = true,
            }
          }
        },
      }
    end

    if server_name == 'marksman' then
      opts = {
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown' },
        root_dir = nvim_lsp.util.root_pattern('.git', '.marksman.toml'),
        single_file_support = true,
      }
    end

    if server_name == 'hls' then
      opts = {
        cmd = { "haskell-language-server-wrapper", "--lsp" },
        filetypes = { 'haskell', 'lhaskell' },
        root_dir = function(filepath)
          return (
              nvim_lsp.util.root_pattern('hie.yaml', 'stack.yaml', 'cabal.project')(filepath)
                  or nvim_lsp.util.root_pattern('*.cabal', 'package.yaml')(filepath)
              )
        end,
        settings = {
          haskell = {
            cabelFormattingProvider = 'cabelfmt',
            formattingProvider = 'ormolu',
          }
        },
        single_file_support = true,
      }
    end

    nvim_lsp[server_name].setup(opts)
  end
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 4, prefix = "●" },
  severity_sort = true,
}
)
-- Diagnostic symbols in the sign column (gutter)
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.diagnostic.config({
  virtual_text = {
    prefix = '●'
  },
  update_in_insert = true,
  float = {
    source = "always", -- Or "if_many"
  },
})
