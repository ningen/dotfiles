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
      "<D-b>",
      function()
        vim.cmd("Neotree toggle")
	vim.cmd("wincmd p")
      end,
      desc = "Toggle filer"
    },
    { "<leader>e", ":Neotree focus<CR>", desc = "Focus Neotree" },
  },
  config = function()
    local neotree = require('neo-tree')
    neotree.setup({
      close_if_last_window = true,
      popup_border_style = "rounded",

      window = {
        mappings = {
          ["y"] = "copy_to_clipboard",    -- y でコピー（vim風）
          ["p"] = "paste_from_clipboard", -- p でペースト（vim風）
          ["x"] = "cut_to_clipboard",     -- x でカット（vim風）
          ["d"] = "delete",               -- d で削除（vim風）
        }
      }
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- ファイルが指定されていない場合のみ開く
        if vim.fn.argc() == 0 then
          vim.cmd("Neotree show")
        else
          -- ファイルが指定されている場合は、そのファイルを表示してからneo-treeを開く
          vim.cmd("Neotree show")
          vim.cmd("wincmd p") -- 元のウィンドウにフォーカスを戻す
        end
      end
    })
  end
}
