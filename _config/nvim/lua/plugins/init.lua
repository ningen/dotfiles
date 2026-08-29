
-- neovim 0.12 で 導入された、標準plugin manager を使用する
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },
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
require("oil").setup({})

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
