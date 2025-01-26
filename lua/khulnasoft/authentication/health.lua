-- Lua module: khulnasoft.authentication.health
local M = {}

local function check_auth_status(auth, err)
  local config = require('khulnasoft.config').current()
  local url = auth and auth.url() or config.khulnasoft_url
  local host = require('khulnasoft.lib.khulnasoft_host').parse_http_url(url)

  vim.health.start(string.format('%s (%s)', host.hostname, host.protocol))
  vim.health.info('KhulnaSoft URL: ' .. config.khulnasoft_url)

  if auth and auth:token_set() then
    vim.health.ok('Personal access token configured.')
    return true
  else
    vim.health.error(err, {
      'Use :KhulnaSoftConfigure to interactively update your KhulnaSoft connection settings.',
    })
    return false
  end
end

local function check_khulnasoft_metadata()
  local rest = require('khulnasoft.api.rest')
  local metadata, err = rest.metadata()
  if not err then
    vim.health.info(
      'KhulnaSoft version: ' .. metadata.version .. ' (revision: ' .. metadata.revision .. ')'
    )
    if metadata.enterprise then
      vim.health.info('Edition: Enterprise Edition (EE)')
    elseif metadata.enterprise == false then
      vim.health.info('Edition: Community Edition (CE)')
    end
  else
    vim.health.error(err, {
      'This healthcheck uses the Metadata API: https://docs.khulnasoft.com/ee/api/metadata.html',
      'Configure a Personal Access Token with the `read_api` scope to enable automatic version detection.',
    })
    return
  end
end

M.check = function()
  local auth, err = require('khulnasoft.authentication').default_resolver():resolve()
  local auth_ok = check_auth_status(auth, err)
  if not auth_ok then
    vim.health.warn('Skipping authenticated health checks.')
    return
  end

  check_khulnasoft_metadata()
end

return M
