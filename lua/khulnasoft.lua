local khulnasoft = {}

function khulnasoft.plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':p:h:h')
end

function khulnasoft.setup(user_config)
  require('khulnasoft.config').setup(user_config)
  require('khulnasoft.resource_editing')
end

return khulnasoft
