local rest = require('khulnasoft.api.rest')

local enforce_khulnasoft = {}

local function instance_version()
  local khulnasoft_metadata, err = rest.metadata()
  if err then
    return nil, err
  end

  if not khulnasoft_metadata or not khulnasoft_metadata.version then
    return nil,
      string.format(
        'unexpected response checking KhulnaSoft version: %s',
        vim.fn.json_encode(khulnasoft_metadata)
      )
  end

  return vim.version.parse(khulnasoft_metadata.version)
end

function enforce_khulnasoft.at_least(min)
  local expected = vim.version.parse(min)
  local actual, err = instance_version()
  if err then
    return nil, err
  end

  if actual < expected then
    return false
  end

  return true
end

return enforce_khulnasoft
