require('vim._core.ui2').enable()

vim.o.number = true
vim.o.relativenumber = true

vim.keymap.set('i', 'jj', '<ESC>')
vim.cmd('colorscheme catppuccin')


vim.opt.clipboard = "unnamedplus"

require('plugins')
require('lsp')


