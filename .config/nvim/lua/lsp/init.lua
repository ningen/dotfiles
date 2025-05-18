vim.diagnostic.config({
  virtual_text = true
})

local augroup = vim.api.nvim_create_augroup("lsp/init.lua", {})

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method("textDocument/definition") then
      vim.keymap.set('n', 'grd', function()
        vim.lsp.buf.definition()
      end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })
    end

    if client:supports_method("textDocument/formatting") then
      vim.keymap.set('n', '<space>i', function()
        vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
      end, { buffer = args.buf, desc = 'Format buffer' })
    end
  end
})

vim.api.nvim_create_user_command("LspHealth", "checkhealth vim.lsp", { desc = "LSP health check" })

vim.lsp.config("*", {
  root_markers = { ".git" }
})


local dirname = vim.fn.stdpath("config") .. "/lua/lsp"

local lsp_names = {}

for file, ftype in vim.fs.dir(dirname) do
  if ftype ~= "file" or not vim.endswith(file, ".lua") or file == "init.lua" then
    goto continue
  end

  local lsp_name = file:sub(1, -5) -- fname without .lua
  local ok, result = pcall(require, "lsp." .. lsp_name)
  if ok then
    vim.lsp.config(lsp_name, result)
    table.insert(lsp_names, lsp_name)
  else
    vim.notify("Error loading LSP: " .. lsp_name .. "\n" .. result, vim.log.levels.ERROR)
  end

  ::continue::
end


vim.lsp.enable(lsp_names)
-- local lua_ls_opts = require("lsp.lua_ls")
-- vim.lsp.config("lua_ls", lua_ls_opts)
-- vim.lsp.enable("lua_ls")


-- local pyright_ops = require("lsp.pyright")
-- vim.lsp.config("pyright", pyright_ops)
-- vim.lsp.enable("pyright")
