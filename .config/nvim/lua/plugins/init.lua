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
    'williamboman/mason-lspconfig.nvim',
  }
  use {
    'hrsh7th/nvim-cmp', -- complement
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/vim-vsnip',
  }

end)

require('plugins.lsp')
