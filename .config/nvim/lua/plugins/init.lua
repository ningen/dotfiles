
-- neovim 0.12 で 導入された、標準plugin manager を使用する
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },
  {
    src = "https://github.com/stevearc/oil.nvim",
    name = "oil"
  }
})

require("mini.icons").setup({})
require("oil").setup({})
