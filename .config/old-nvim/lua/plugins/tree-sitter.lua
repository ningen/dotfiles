return {
  "https://github.com/nvim-treesitter/nvim-treesitter",
  branch = "main",
  config = function()
    require("nvim-treesitter").setup()

    require("nvim-treesitter").install({
      "astro",
      "css",
      "html",
      "javascript",
      "typescript",
      "tsx",
    })

    -- 自動ハイライトの有効化
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
