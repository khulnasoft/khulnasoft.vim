local khulnasoft = require('khulnasoft')
local jobs = require('khulnasoft.lib.jobs')

return function(...)
  local cmd = vim.tbl_flatten({ 'npm', ... })
  local cwd = khulnasoft.plugin_root()

  return {
    cmd = cmd,
    cwd = cwd,
    exec = function()
      return jobs.start_wait(cmd, { cwd = cwd })
    end,
  }
end
