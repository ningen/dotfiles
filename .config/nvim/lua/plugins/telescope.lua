return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<D-S-p>",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Command Palette",
    },
    {
      "<M-S-p>",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Command Palette",
    },
    {
      "<D-p>",
      function()
        require("telescope.builtin").find_files({ hidden = true })
      end,
      desc = "Find files",
    },
    {
      "<M-p>",
      function()
        require("telescope.builtin").find_files({ hidden = true })
      end,
      desc = "Find files",
    },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
        },
      },
      pickers = {
        find_files = {
          find_command = { "git", "ls-files" }, -- Git管理ファイルのみ
        },
      },
    })
  end,
}
