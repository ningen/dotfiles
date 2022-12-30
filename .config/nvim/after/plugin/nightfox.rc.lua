local status, nightfox = pcall(require, 'nightfox')

if (not status) then
  print('nightfox is not installed')
  return
end

nightfox.setup({
  -- setup
})

vim.cmd('colorscheme nightfox')
