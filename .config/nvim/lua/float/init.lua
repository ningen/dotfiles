local function open_float()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Hello, Float!" })

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    -- relative = "cursor",
    -- row = 1,
    -- col = 0,
    -- width = 15,
    -- height = 1,
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].winblend = 20

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, desc = "Close window" })
end

vim.api.nvim_create_user_command("FloatOpen", open_float, {
  desc = "Open a floating window",
})
