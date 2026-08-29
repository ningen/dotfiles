
-- neovim 0.12 で 導入された、標準plugin manager を使用する
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },
  {
    src = "https://github.com/Saghen/blink.cmp",
    version = vim.version.range("1"),
  },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  {
    src = "https://github.com/stevearc/oil.nvim",
    name = "oil",
  },
  {
    src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
    version = vim.version.range("3"),
  },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

require("mini.icons").setup({})

require("blink.cmp").setup({
  keymap = { preset = "enter" },
  appearance = { nerd_font_variant = "mono" },
  completion = { documentation = { auto_show = true } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.keymap.set("", "<leader>f", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

local treesitter = require("nvim-treesitter")
treesitter.setup()
treesitter.install({
  "astro",
  "css",
  "html",
  "javascript",
  "typescript",
  "tsx",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("vim-treesitter-start", { clear = true }),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

local oil = require("oil")
oil.setup({})

-- Oil accepts preview options for each open call. Make preview the default while
-- preserving an explicit choice from the caller.
local function open_with_preview(open)
  return function(dir, opts, cb)
    if not opts or opts.preview == nil then
      opts = vim.tbl_extend("keep", opts or {}, { preview = {} })
    end
    return open(dir, opts, cb)
  end
end

oil.open = open_with_preview(oil.open)
oil.open_float = open_with_preview(oil.open_float)

require("neo-tree").setup({
  close_if_last_window = true,
  popup_border_style = "rounded",
  filesystem = {
    filtered_items = {
      visible = true,
      hide_dotfiles = true,
      hide_gitignored = true,
    },
  },
  window = {
    mappings = {
      ["<CR>"] = "open",
      ["o"] = "open",
      ["s"] = "open_split",
      ["v"] = "open_vsplit",
      ["t"] = "open_tabnew",
      ["a"] = "add",
      ["d"] = "delete",
      ["r"] = "rename",
      ["y"] = "copy_to_clipboard",
      ["x"] = "cut_to_clipboard",
      ["p"] = "paste_from_clipboard",
      ["h"] = "close_node",
      ["l"] = "open",
      ["H"] = "toggle_hidden",
      ["R"] = "refresh",
      ["?"] = "show_help",
      ["q"] = "close_window",
    },
  },
})
