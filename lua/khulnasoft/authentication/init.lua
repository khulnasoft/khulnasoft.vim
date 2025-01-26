local provider = require('khulnasoft.authentication.provider')
local notifier = require('khulnasoft.notifier')

-- Lua module: khulnasoft.authentication
local M = {}

local function new_auth_resolver(options)
  vim.validate({
    khulnasoft_url = { options.khulnasoft_url, 'string' },
  })

  local resolved
  return {
    clear = function()
      resolved = nil
    end,
    resolve = function(opts)
      vim.validate({
        ['opts.force'] = { opts.force, 'boolean', true },
        ['opts.prompt_user'] = { opts.prompt_user, 'boolean', true },
      })

      if resolved then
        if opts and opts.force then
          resolved:resolve(opts)
        end

        return resolved, nil
      end

      local env_auth = provider.env(
        { khulnasoft_url = 'KHULNASOFT_VIM_URL', token = 'GITHUB_TOKEN' },
        { khulnasoft_url = options.khulnasoft_url }
      )
      if env_auth:resolve() then
        resolved = env_auth
        notifier.notify_once(
          'khulnasoft.vim: Resolved authentication details from environment.',
          vim.lsp.log_levels.DEBUG
        )
        return env_auth, nil
      end

      local prompt_auth = provider.prompt()
      if prompt_auth:resolve(opts) then
        resolved = prompt_auth
        notifier.notify_once(
          'khulnasoft.vim: Resolved authentication details from user input.',
          vim.lsp.log_levels.DEBUG
        )
        return prompt_auth, nil
      end

      return nil, 'Unable to resolve authentication details from environment.'
    end,
  }
end

function M.default_resolver()
  local config = require('khulnasoft.config').current()
  return new_auth_resolver({
    khulnasoft_url = config.khulnasoft_url,
  })
end

return M
