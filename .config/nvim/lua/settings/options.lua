local opt  = vim.opt
local keymap = vim.keymap

opt.number = true

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2

opt.clipboard:prepend { "unnamed", "unnamedplus" }

keymap.set('n', '<Tab>', ':tabNext<CR>')
keymap.set('n', '<S-Tab>', ':tabprevious<CR>')
