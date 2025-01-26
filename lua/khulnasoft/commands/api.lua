local rest = require('khulnasoft.api.rest')
local notifier = require('khulnasoft.notifier')

local function khulnasoft_metadata()
  local response, err = rest.metadata()

  if err then
    notifier.notify(err, vim.log.levels.ERROR)
  else
    notifier.notify(
      response.version .. ' (revision: ' .. response.revision .. ')',
      vim.log.levels.INFO,
      { title = 'KhulnaSoft version' }
    )
  end
end

return {
  create = function()
    vim.api.nvim_create_user_command('KhulnaSoftVersion', khulnasoft_metadata, {
      desc = 'Starts the Code Suggestions LSP client integration.',
    })
  end,
}
