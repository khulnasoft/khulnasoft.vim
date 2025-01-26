local M = {}

function M.create()
  local autocmd_groups = {
    code_suggestions = vim.api.nvim_create_augroup('KhulnaSoftCodeSuggestions', { clear = true }),
  }
  local auth = require('khulnasoft.authentication').default_resolver()
  local workspace = require('khulnasoft.lsp.workspace').new()

  require('khulnasoft.commands.api').create()
  require('khulnasoft.commands.code_suggestions').create({
    auth = auth,
    group = autocmd_groups.code_suggestions,
    workspace = workspace,
  })
  require('khulnasoft.commands.configure').create({
    auth = auth,
    workspace = workspace,
  })
end

return M
