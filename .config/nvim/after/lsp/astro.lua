return {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = {
    "astro.config.mjs",
    "astro.config.js",
    "astro.config.ts",
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
}
