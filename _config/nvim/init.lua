require('vim._core.ui2').enable()

vim.g.mapleader = ' '

vim.o.number = true
vim.o.relativenumber = true

-- 基本設定
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.keymap.set('i', 'jj', '<ESC>')

-- クリップボード連携。WSL では Windows 側のコマンドを使う。
vim.opt.clipboard = 'unnamedplus'
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'Windows clipboard',
    copy = { ['+'] = 'win-copy', ['*'] = 'win-copy' },
    paste = { ['+'] = 'win-paste', ['*'] = 'win-paste' },
    cache_enabled = 0,
  }
end

vim.filetype.add({
  extension = {
    astro = 'astro',
  },
})

local config_augroup = vim.api.nvim_create_augroup('nvim-config', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = config_augroup,
  pattern = { 'go', 'make', 'gitconfig' },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = config_augroup,
  pattern = 'python',
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

vim.cmd('colorscheme catppuccin')

require('plugins')
require('lsp')
