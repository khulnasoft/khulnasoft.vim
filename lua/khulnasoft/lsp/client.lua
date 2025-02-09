local notifier = require('khulnasoft.notifier')
local lspconfig = require('khulnasoft.lspconfig')
local validate = require('khulnasoft.config.validate')

-- Lua module: khulnasoft.lsp.client
local M = {}

function M.start(options)
  vim.validate({
    ['options.auth'] = { options.auth, 'table' },
    ['options.cmd'] = { options.cmd, validate.is_string_list },
    ['options.handlers'] = { options.handlers, validate.is_dict_of('function') },
    ['options.workspace'] = { options.workspace, 'table' },
  })

  local config = require('khulnasoft.config').current()
  local settings = vim.tbl_extend(
    'keep',
    options.workspace.configuration,
    config.language_server.workspace_settings
  )
  settings = vim.tbl_extend('force', settings, {
    baseUrl = options.auth.url(),
    token = options.auth.token(),
  })
  local client_id = lspconfig.setup({
    cmd = options.cmd,
    handlers = options.handlers,
    name = 'khulnasoft_code_suggestions',
    root_dir = vim.fn.getcwd(),
    settings = settings,
    on_init = function(client, _initialize_result)
      client.offset_encoding = config.code_suggestions.offset_encoding

      options.workspace.subscribe_client(client.id)
      options.workspace:change_configuration(settings)
    end,
  })

  return {
    client_id = client_id,
    stop = function()
      notifier.notify(
        'khulnasoft.vim: Stopping KhulnaSoft LSP client ' .. client_id .. '...',
        vim.lsp.log_levels.DEBUG
      )
      vim.lsp.stop_client(client_id)
    end,
    notify = function(self, ...)
      local client = vim.lsp.get_client_by_id(self.client_id)
      return client and client.notify(...)
    end,
    workspace = options.workspace,
  }
end

return M
