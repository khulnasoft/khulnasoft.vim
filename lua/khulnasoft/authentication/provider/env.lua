-- Lua module: khulnasoft.authentication.provider.env
local validate = require('khulnasoft.config.validate')
local M = {}

M.prototype = {
  token_set = function(self)
    return self.token() ~= nil
  end,
  url_set = function(self)
    return self.url() ~= nil
  end,
  resolve = function(self)
    if self:token_set() and self:url_set() then
      return self
    end
  end,
}

function M.new(options)
  vim.validate({
    ['options'] = { options, 'table' },
  })

  vim.validate({
    ['options.defaults'] = { options.defaults, validate.is_dict_of('string') },
    ['options.keys'] = { options.keys, validate.is_dict_of('string') },
  })

  vim.validate({
    ['options.defaults.khulnasoft_url'] = { options.defaults.khulnasoft_url, 'string' },
    ['options.keys.khulnasoft_url'] = { options.keys.khulnasoft_url, 'string' },
    ['options.keys.token'] = { options.keys.token, 'string' },
  })

  local env = {
    token = function()
      return vim.env[options.keys.token]
    end,
    url = function()
      return vim.env[options.keys.khulnasoft_url] or options.defaults.khulnasoft_url
    end,
  }
  setmetatable(env, {
    __index = M.prototype,
  })

  return env
end

return M
