return {
  "nvim-telescope/telescope.nvim",
  enabled = false,
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>fp",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Command Palette",
    },
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files({ hidden = true })
      end,
      desc = "Find files",
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep({ hidden = true })
      end,
      desc = "Live grep",
    },
    {
      "<leader>fw",
      function()
        require("telescope.builtin").grep_string({ hidden = true })
      end,
      desc = "Grep cursor string",
    },
    {
      "<leader>gs",
      function()
        require("telescope.builtin").git_status()
      end,
      desc = "show git status",
    },
    {
      "<leader>gb",
      function()
        require("telescope.builtin").git_branches()
      end,
      desc = "show git branches",
    },
    {
      "<leader>gc",
      function()
        require("telescope.builtin").git_commits()
      end,
      desc = "show git commmits",
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
