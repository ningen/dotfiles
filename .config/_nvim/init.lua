local opt    = vim.opt
local keymap = vim.keymap

vim.g.mapleader = ','


local configs = {
  number = true,
  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,
  signcolumn = 'yes'
}

for key, value in pairs(configs) do
  opt[key] = value
end

opt.clipboard:prepend { "unnamed", "unnamedplus" }

keymap.set('n', '<Tab>', ':tabNext<CR>')
keymap.set('n', '<S-Tab>', ':tabprevious<CR>')

keymap.set('i', 'jj', '<Esc>')

local status, packer = pcall(require, "packer")
if (not status) then
  print("Packer is not installed")
  return
end


vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'neovim/nvim-lspconfig' -- lsp
  use {
    'williamboman/mason.nvim', -- lsp server management
    requires = {
      { 'williamboman/mason-lspconfig.nvim' }
    }
  }
  use {
    'glepnir/lspsaga.nvim',
    branch = 'main',
    requires = {
      { 'neovim/nvim-lspconfig' }
    }
  }

  -- 補完関係
  use {
    'hrsh7th/nvim-cmp', -- complementj
    requires = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/vim-vsnip', },
    }
  }
  use 'onsails/lspkind.nvim'
  use 'L3MON4D3/LuaSnip'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'

  use {
    'nvim-telescope/telescope.nvim', -- fuzzy finder
    requires = {
      { 'nvim-lua/plenary.nvim' }
    }
  }

  use 'nvim-telescope/telescope-file-browser.nvim' -- filer
  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      { 'nvim-tree/nvim-web-devicons' }
    },
  }
  use 'dinhhuy258/git.nvim' --git

  use 'EdenEast/nightfox.nvim' -- colorscheme
  use 'nvim-tree/nvim-web-devicons' -- icon

  use 'voldikss/vim-translator' -- translator(auto -> jp)
end)
