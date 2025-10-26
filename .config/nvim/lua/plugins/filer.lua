return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  lazy = false, -- neo-tree will lazily load itself
  keys = {
    {
      "<leader>e",
      function()
        vim.cmd("Neotree toggle")
        vim.cmd("wincmd p")
      end,
      desc = "Toggle filer",
    },
    { "<leader>E", ":Neotree focus<CR>", desc = "Focus Neotree" },
  },
  config = function()
    local neotree = require("neo-tree")
    neotree.setup({
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = true,
          hide_gitignored = true,
        },
      },
      close_if_last_window = true,
      popup_border_style = "rounded",

      window = {
        mappings = {
          -- 基本操作（覚えやすい単語の頭文字）
          ["<CR>"] = "open",
          ["o"] = "open",
          ["s"] = "open_split", -- split
          ["v"] = "open_vsplit", -- vertical
          ["t"] = "open_tabnew", -- tab

          -- ファイル操作
          ["a"] = "add", -- add (新規作成)
          ["d"] = "delete", -- delete
          ["r"] = "rename", -- rename
          ["y"] = "copy", -- yank (コピー)
          ["x"] = "cut_to_clipboard", -- cut
          ["p"] = "paste_from_clipboard", -- paste

          -- 移動
          ["h"] = "close_node", -- 親へ（左）
          ["l"] = "open", -- 子へ（右）

          -- 表示
          ["H"] = "toggle_hidden", -- Hidden files
          ["R"] = "refresh", -- Refresh
          ["?"] = "show_help", -- help

          -- 終了
          ["q"] = "close_window", -- quit
        },
      },
    })
    -- vim.api.nvim_create_autocmd("VimEnter", {
    --   callback = function()
    --     -- ファイルが指定されていない場合のみ開く
    --     if vim.fn.argc() == 0 then
    --       vim.cmd("Neotree show")
    --     else
    --       -- ファイルが指定されている場合は、そのファイルを表示してからneo-treeを開く
    --       vim.cmd("Neotree show")
    --       vim.cmd("wincmd p") -- 元のウィンドウにフォーカスを戻す
    --     end
    --   end,
    -- })
  end,
}
