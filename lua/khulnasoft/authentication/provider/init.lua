-- Lua module: khulnasoft.authentication.provider
local env = require('khulnasoft.authentication.provider.env')
local prompt = require('khulnasoft.authentication.provider.prompt')

local M = {}

function M.env(keys, defaults)
  return env.new({
    keys = keys,
    defaults = defaults,
  })
end

function M.prompt(khulnasoft_url)
  return prompt.new({
    khulnasoft_url = khulnasoft_url,
  })
end

return M
