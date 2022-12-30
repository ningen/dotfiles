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
  use {
    'hrsh7th/nvim-cmp', -- complementj
    requires = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/vim-vsnip',},
    }
  }
  use {
    'nvim-telescope/telescope.nvim', -- fuzzy finder
    requires = {
      { 'nvim-lua/plenary.nvim' }
    }
  }
  use {
    'nvim-telescope/telescope-file-browser.nvim', -- filer
  }
  use {
    'EdenEast/nightfox.nvim' -- colorscheme
  }
end)

require('plugins.lsp')
require('plugins.colorscheme')
require('plugins.telescope')
