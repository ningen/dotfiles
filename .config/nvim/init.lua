local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 基本設定を書く
vim.opt.number = true
vim.g.mapleader = " "

vim.opt.shiftwidth = 2 -- インデント幅
vim.opt.tabstop = 2 -- タブ幅
vim.opt.smartindent = true -- スマートインデント
vim.opt.wrap = false -- 行折り返しなし
vim.opt.swapfile = false -- スワップファイル無効
vim.opt.backup = false -- バックアップ無効
vim.opt.undofile = true -- Undo履歴を保持
vim.opt.hlsearch = false -- 検索ハイライト無効
vim.opt.incsearch = true -- インクリメンタルサーチ
vim.opt.termguicolors = true -- True Color対応
vim.opt.scrolloff = 8 -- スクロール時の余白
vim.opt.updatetime = 50 -- 更新時間短縮

-- クリップボード連携
vim.opt.clipboard = "unnamedplus"

-- マウス有効化
vim.opt.mouse = "a"

-- 検索時の大文字小文字
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 分割ウィンドウの挙動
vim.opt.splitbelow = true -- 水平分割（horizontal split）時に、新しいウィンドウを下に配置
vim.opt.splitright = true -- 垂直分割（vertical split）時に、新しいウィンドウを右に配置

-- ウィンドウ操作のキーマップ
-- vim.keymap.set("n", "<leader>h", "<C-w>h", { desc = "Go to left window" })
-- vim.keymap.set("n", "<leader>j", "<C-w>j", { desc = "Go to lower window" })
-- vim.keymap.set("n", "<leader>k", "<C-w>k", { desc = "Go to upper window" })
-- vim.keymap.set("n", "<leader>l", "<C-w>l", { desc = "Go to right window" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- ウィンドウサイズ調整
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- utils
vim.keymap.set("i", "jj", "<ESC>")
vim.keymap.set("t", "<ESC>", "<C-\\><C-n>")
vim.keymap.set("t", "jj", "<C-\\><C-n>")

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "lua",
    "python",
    "javascript",
    "typescript",
    "typescriptreact",
    "json",
    "yaml",
    "html",
    "css",
  },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "go",
    "make",
    "gitconfig",
  },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

require("lazy").setup("plugins")
require("lsp")
