local notifier = require('khulnasoft.notifier')
local globals = require('khulnasoft.globals')
local statusline = require('khulnasoft.statusline')
local lsp = require('khulnasoft.lsp.health')

-- Lua module: khulnasoft.lsp.handlers
return {
  ['$/khulnasoft/token/check'] = function(_err, result, _ctx, _config)
    local message
    if result and result.message then
      message = 'khulnasoft.vim: ' .. result.message
    else
      message = 'khulnasoft.vim: Unexpected error from LSP server: ' .. vim.inspect(result)
    end

    notifier.notify_once(message, vim.log.levels.ERROR, {
      title = 'LSP method: $/khulnasoft/token/check',
    })
    statusline.update_status_line(globals.GCS_UNAVAILABLE)
  end,
  ['$/khulnasoft/featureStateChange'] = function(_err, result)
    local checks_passed = true
    local feature_states = result and result[1]
    for _, feature_state in ipairs(feature_states) do
      lsp.refresh_feature(feature_state.featureId, feature_state)
      if feature_state.engagedChecks and #feature_state.engagedChecks > 0 then
        checks_passed = false
      end
    end

    if checks_passed then
      statusline.update_status_line(globals.GCS_AVAILABLE)
    else
      statusline.update_status_line(globals.GCS_UNAVAILABLE)
    end
  end,
}
