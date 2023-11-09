function set_options(obj, configs)
  for key, value in pairs(configs) do
    obj[key] = value
  end
end

vim.g.mapleader = '<Space>'
vim.keymap.set('i', 'jj', '<ESC>')

vim.opt.clipboard:append({ 'unnamedplus' })
if vim.fn.has('wsl') == 1 then
  vim.opt.clipboard:append({
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf"
    },
    paste = {
      ["+"] = "win32yank.exe -o --crlf",
      ["*"] = "win32yank.exe -o --crlf"
    },
    cache_enable = 0,
  })
end

local vim_opt = {
  number = true,
  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,
  signcolumn = 'yes'
}


set_options(vim.opt, vim_opt)

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    'EdenEast/nightfox.nvim',
    config = function()
      require('nightfox').setup({})
    end
  }                                 -- colorscheme

  use 'nvim-tree/nvim-web-devicons' -- icon

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({})
    end
  }

  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  use {
    'nvimdev/lspsaga.nvim'
  }

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/vim-vsnip'
end)


-- 1. LSP Server management
require('mason').setup()
require('mason-lspconfig').setup_handlers({
  function(server)
    local lspconfigs = {
      lua_ls = {
        on_attach = function(client, bufnr)
          local opts = { nnoremap = true, slient = true }
          vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
          vim.cmd [[
            autocmd BufWritePre * lua vim.lsp.buf.formatting_sync(nil, 1000)
          ]]
        end,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT'
            },
            diagnostics = { globals = 'vim' },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) }
          }
        }
      },
      hls = {},
      denols = {},
      tsserver = {},
      marksman = {},
      clangd = {}
    }

    local using_config = lspconfigs[server]
    require('lspconfig')[server].setup(using_config)
  end
})
require('lspsaga').setup({
  border_style = "single",
  symbol_in_winbar = {
    enable = true,
  },
  code_action_lightbulb = {
    enable = true,
  },
  show_outline = {
    win_width = 50,
    auto_preview = false,
  },
})

vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
-- vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>')
vim.keymap.set('n', 'gf', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>')
vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
-- vim.keymap.set('n', 'gr', '<cmd>Lspsaga finder<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
-- vim.keymap.set('n', 'gd', '<cmd>Lspsaga peek_definitation<CR>')
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
vim.keymap.set('n', 'gn', '<cmd>lua vim.lsp.buf.rename()<CR>')
-- vim.keymap.set('n', 'gn', '<cmd>Lspsaga rename<CR>')
vim.keymap.set('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')
-- vim.keymap.set('n', 'ga', '<cmd>Lspsaga code_action<CR>')
vim.keymap.set('n', 'ge', '<cmd>lua vim.diagnostic.open_float()<CR>')
-- vim.keymap.set('n', 'ge', '<cmd>Lspsaga show_line_diagnostics<CR>')
vim.keymap.set('n', 'g]', '<cmd>lua vim.diagnostic.goto_next()<CR>')
vim.keymap.set('n', 'g[', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
-- vim.keymap.set('n', 'g]', '<cmd>Lspsaga diagnostic_jump_next<CR>')
-- vim.keymap.set('n', 'g[', '<cmd>Lspsaga diagnostic_jump_prev<CR>')



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
    { name = "buffer" },
    { name = "path" },
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

vim.cmd([[ colorscheme nightfox ]])
vim.cmd([[
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermbg=NONE guibg=NONE
highlight Folded ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE
]])

