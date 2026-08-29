local function nix_typescript_sdk_path()
  local tsserver = vim.fn.exepath('tsserver')
  if tsserver == '' then
    return nil
  end

  local realpath = vim.uv.fs_realpath(tsserver) or tsserver
  local tsdk = vim.fs.dirname(vim.fs.dirname(realpath)) .. '/lib/node_modules/typescript/lib'
  return vim.uv.fs_stat(tsdk) and tsdk or nil
end

local function project_typescript_sdk_path(root_dir)
  local current = root_dir
  while current do
    local tsdk = current .. '/node_modules/typescript/lib'
    if vim.uv.fs_stat(tsdk) then
      return tsdk
    end

    local parent = vim.fs.dirname(current)
    if parent == current then
      break
    end
    current = parent
  end
end

return {
  cmd = { 'astro-ls', '--stdio' },
  filetypes = { 'astro' },
  root_markers = {
    'astro.config.mjs',
    'astro.config.js',
    'astro.config.ts',
    'package.json',
    'tsconfig.json',
    'jsconfig.json',
    '.git',
  },
  init_options = {
    typescript = {},
  },
  before_init = function(_, config)
    local tsdk = project_typescript_sdk_path(config.root_dir) or nix_typescript_sdk_path()
    if not tsdk then
      return
    end

    config.init_options = config.init_options or {}
    config.init_options.typescript = config.init_options.typescript or {}
    config.init_options.typescript.tsdk = tsdk
  end,
}
