local khulnasoft_lsp = require('khulnasoft.lspconfig.server_configurations.khulnasoft_lsp')

local M = {}

function M.setup(user_config)
  local cfg = vim.tbl_deep_extend('keep', user_config, khulnasoft_lsp.default_config)
  return vim.lsp.start(cfg)
end

return M
