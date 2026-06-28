local function nix_typescript_sdk_path()
  local tsserver = vim.fn.exepath("tsserver")
  if tsserver == "" then
    return nil
  end

  local tsdk = vim.fs.dirname(vim.fs.dirname(vim.uv.fs_realpath(tsserver) or tsserver))
    .. "/lib/node_modules/typescript/lib"
  return vim.uv.fs_stat(tsdk) and tsdk or nil
end

local function typescript_sdk_path(root_dir)
  local project_tsdk = require("lspconfig.util").get_typescript_server_path(root_dir)
  if project_tsdk ~= "" then
    return project_tsdk
  end

  return nix_typescript_sdk_path()
end

return {
  root_markers = {
    "astro.config.mjs",
    "astro.config.js",
    "astro.config.ts",
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
  init_options = {
    typescript = {},
  },
  before_init = function(_, config)
    config.init_options = config.init_options or {}
    config.init_options.typescript = config.init_options.typescript or {}
    config.init_options.typescript.tsdk = typescript_sdk_path(config.root_dir)
  end,
}
