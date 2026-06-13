return {
  dir = "~/ghq/github.com/ningen/memo.nvim", -- GitHubにpushしたものをローカルで参照
  config = function()
    require("memo").setup()
  end,
  dependencies = {
    "nvim-lua/plenary.nvim"
  }
}
