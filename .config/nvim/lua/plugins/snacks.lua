return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      enabled = true,
      sources = {
        files = {
          hidden = true, -- . から始まるファイルなども表示する
        },
      },
    },
    indent = { enabled = true },
  },
  keys = {
    {
      "<leader>fp",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Command Palette",
    },
    {
      "<leader>ff",
      function()
        local _ = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error == 0 then
          -- Gitリポジトリ内ならgit_files
          Snacks.picker.git_files({ hidden = true })
        else
          -- Gitリポジトリ外ならfiles
          Snacks.picker.files({ hidden = true })
        end
      end,
      desc = "Find files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live grep",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep cursor string",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "show git status",
    },
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "show git branches",
    },
    {
      "<leader>gc",
      function()
        Snacks.picker.git_log()
      end,
      desc = "show git commits",
    },
  },
}
