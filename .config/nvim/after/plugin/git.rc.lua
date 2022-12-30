local status, git = pcall(require, 'git')
if (not status) then return end

git.setup({
  default_mappings = false,
  target_branch = 'main',
  keymaps = {
    blame = '<Leader>gb',
    quit_blame = 'q',
    blame_commit = '<CR>',
    browse = '<Leader>go',
    diff = '<Leader>gd',
    diff_close = '<Leader>gD'
  }
})
