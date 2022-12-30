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

end)
