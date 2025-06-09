return {
  {
    'nvim-telescope/telescope-ui-select.nvim'
  },
  {
    'nvim-telescope/telescope-file-browser.nvim',
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          },
          file_browser = {
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
              ["i"] = {
                -- your custom insert mode mappings
              },
              ["n"] = {
                -- your custom normal mode mappings
              },
            },
          },
        }
      }
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
      vim.keymap.set('n', '<leader>fo', builtin.current_buffer_fuzzy_find, { desc = 'Telescope buffer fuzzy find' })
      vim.keymap.set("n", "<leader>fl", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

      local telescope = require('telescope')
      telescope.load_extension('ui-select')
      telescope.load_extension('file_browser')
    end
  }
}