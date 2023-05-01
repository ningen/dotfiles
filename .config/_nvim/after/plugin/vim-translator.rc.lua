vim.cmd([[
  " normal mode
  let g:translator_target_lang = 'ja'
  let g:translator_default_engines =  ['google']
  " visual mode 
  let g:vtm_target_lang = 'ja'
  let g:vtm_default_engines = ['google']
]])

local keymap = vim.keymap
keymap.set('n', '<Leader>t', '<Plug>Translate')
keymap.set('v', '<Leader>t', '<Plug>TranslateV')
