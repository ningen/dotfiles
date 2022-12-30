local opt    = vim.opt
local keymap = vim.keymap

vim.g.mapleader = ','

opt.number = true

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.signcolumn = 'yes'

opt.clipboard:prepend { "unnamed", "unnamedplus" }

keymap.set('n', '<Tab>', ':tabNext<CR>')
keymap.set('n', '<S-Tab>', ':tabprevious<CR>')
