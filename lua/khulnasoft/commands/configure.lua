local notifier = require('khulnasoft.notifier')
local M = {}

function M.create(options)
  vim.api.nvim_create_user_command('KhulnaSoftConfigure', function()
    vim.validate({
      ['options.auth'] = { options.auth, 'table' },
      ['options.workspace'] = { options.workspace, 'table' },
    })

    local auth, err = options.auth.resolve({
      force = true,
    })
    if err or not auth then
      notifier.notify('khulnasoft.vim: Error resolving authentication.', vim.lsp.log_levels.ERROR)
      return
    end

    options.workspace:change_configuration({
      baseUrl = auth.url(),
      token = auth.token(),
    })
  end, { desc = 'Configure KhulnaSoft client and LSP settings.' })
end

return M
