return {
  "https://github.com/nvim-treesitter/nvim-treesitter",
  branch = "main",
  config = function()
    require("nvim-treesitter").setup()

    -- 自動ハイライトの有効化
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
