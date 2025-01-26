local M = {}

local function can_notify(level)
  level = level or 0
  local config = require('khulnasoft.config').current().minimal_message_level or vim.lsp.log_levels.INFO

  return level >= config
end

---Notifies if messages above the minimal required by users on config.minimal_message_level
---@param msg string message to notify
---@param level number|nil same as |vim.lsp.log_levels|
---@param opts table|nil same options from |vim.notify|
function M.notify(msg, level, opts)
  opts = opts or {}
  if can_notify(level) and msg then
    vim.notify(msg, level, opts)
  end
end

---Notifies only once if messages above the minimal required by users on config.minimal_message_level
---@param msg string message to notify
---@param level number|nil same as |vim.lsp.log_levels|
---@param opts table|nil same options from |vim.notify|
function M.notify_once(msg, level, opts)
  opts = opts or {}
  if can_notify(level) and msg then
    vim.notify_once(msg, level, opts)
  end
end

return M
