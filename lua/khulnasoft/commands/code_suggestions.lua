local globals = require('khulnasoft.globals')
local statusline = require('khulnasoft.statusline')
local utils = require('khulnasoft.utils')
local notifier = require('khulnasoft.notifier')

local function lsp_user_data(item)
  local user_data = item and item.user_data
  if user_data then
    return user_data.nvim and user_data.nvim.lsp
  end
end

local function suggestion_data_from_completion_item(item)
  local lsp = lsp_user_data(item)
  if lsp and lsp.completion_item then
    return lsp.completion_item.data
  end
end

local CodeSuggestionsCommands = {}

--{{{[CodeSuggestionsCommands]
function CodeSuggestionsCommands.new(options)
  vim.validate({
    ['options.auth'] = { options.auth, 'table' },
    ['options.group'] = { options.group, 'number' },
    ['options.lsp_server'] = { options.lsp_server, 'table' },
    ['options.workspace'] = { options.workspace, 'table' },
  })

  local instance = vim.deepcopy(options)
  setmetatable(instance, {
    __index = CodeSuggestionsCommands,
  })
  return instance
end

-- Install the @khulnasoft/khulnasoft-lsp npm package along with any other dependencies.
-- This project's package.json and package-lock.json files which can be used to
-- enforce version constraints and perform security scans.
--
-- This function may modify package.json/package-lock.json if the environment differs.
function CodeSuggestionsCommands:install_language_server()
  local ok = self.lsp_server:is_installed()
  if ok then
    notifier.notify('@khulnasoft/khulnasoft-lsp already installed.')
    statusline.update_status_line(globals.GCS_INSTALLED)
  end

  if vim.fn.exepath('npm') == '' then
    notifier.notify(
      'khulnasoft.vim: Unsatisfied dependency "npm". Unable to find "npm" in PATH.',
      vim.log.levels.ERROR
    )
    return
  end

  local lsp_path = require('khulnasoft').plugin_root()
  notifier.notify(
    'khulnasoft.vim: Installing @khulnasoft/khulnasoft-lsp under ' .. lsp_path .. '',
    vim.lsp.log_levels.DEBUG
  )
  local job_opts = { cwd = lsp_path }
  local cmd = {
    'npm',
    'install',
  }

  local job_id = utils.exec_cmd(cmd, job_opts, function(result)
    if result.exit_code == 0 then
      statusline.update_status_line(globals.GCS_UPDATED)
      notifier.notify(
        'khulnasoft.vim: Successfully installed @khulnasoft/khulnasoft-lsp',
        vim.lsp.log_levels.DEBUG
      )
      return
    end

    notifier.notify(
      'khulnasoft.vim: Unable to install @khulnasoft/khulnasoft-lsp please install it manually before continuing.',
      vim.log.levels.WARN
    )
  end)

  if job_id > 0 then
    local status = vim.fn.jobwait({ job_id }, 10000)[1]
    if status == 0 then
      statusline.update_status_line(globals.GCS_AVAILABLE_BUT_DISABLED)
      return
    end
  end
end

local auth
function CodeSuggestionsCommands:start(options)
  vim.validate({
    ['options.prompt_user'] = { options.prompt_user, 'boolean' },
  })
  statusline.update_status_line(globals.GCS_CHECKING)

  if not self.lsp_server:is_installed() then
    statusline.update_status_line(globals.GCS_UNAVAILABLE)
    notifier.notify(
      'Run :KhulnaSoftCodeSuggestionsInstallLanguageServer to install the required binary.',
      vim.log.levels.WARN
    )
    return
  end

  if not auth then
    auth = self.auth.resolve({ prompt_user = options.prompt_user })
  end
  if not auth or not auth:token_set() then
    statusline.update_status_line(globals.GCS_UNAVAILABLE)
    -- Invoke :redraw before notifier.notify to ensure users will see the warning.
    vim.cmd.redraw()
    notifier.notify(
      'khulnasoft.vim: Run :KhulnaSoftCodeSuggestionsStart to interactively authenticate the LSP.',
      vim.log.levels.WARN
    )
    return
  end

  self.lsp_client = require('khulnasoft.lsp.client').start({
    auth = auth,
    cmd = self.lsp_server:cmd({ args = { '--stdio' } }),
    handlers = require('khulnasoft.lsp.handlers'),
    workspace = self.workspace,
  })

  if self.lsp_client then
    statusline.update_status_line(globals.GCS_AVAILABLE_AND_ENABLED)
    notifier.notify_once(
      'khulnasoft.vim: Started Code Suggestions LSP integration.',
      vim.lsp.log_levels.DEBUG
    )
  else
    notifier.notify(
      'khulnasoft.vim: Unable to start LSP try using :KhulnaSoftConfigure before reattempting.',
      vim.lsp.log_levels.WARN
    )
  end
end

function CodeSuggestionsCommands:stop()
  if self.lsp_client then
    self.lsp_client.stop()
    self.lsp_client = nil
  else
    notifier.notify('khulnasoft.vim: No active client found.', vim.lsp.log_levels.DEBUG)
  end

  statusline.update_status_line(globals.GCS_AVAILABLE_BUT_DISABLED)
end

function CodeSuggestionsCommands:toggle()
  if self.lsp_client then
    notifier.notify(
      'khulnasoft.vim: Toggling Code Suggestions LSP client integration off.',
      vim.lsp.log_levels.INFO
    )
    self:stop()
  else
    notifier.notify(
      'khulnasoft.vim: Toggling Code Suggestions LSP client integration on.',
      vim.lsp.log_levels.INFO
    )
    self:start({ prompt_user = true })
  end
end
--}}}

return {
  create = function(options)
    local code_suggestions_commands = CodeSuggestionsCommands.new({
      auth = options.auth,
      group = options.group,
      lsp_server = require('khulnasoft.lsp.server').new(),
      workspace = options.workspace,
    })
    local suggestion_events = {}

    --{{{[Automatic commands]
    vim.api.nvim_create_autocmd({ 'CompleteDonePre' }, {
      callback = function()
        local config = require('khulnasoft.config').current()
        if config.language_server.workspace_settings.telemetry.enabled then
          -- complete_info() is only available before CompleteDonePre is complete.
          -- Save the results here since context for rejected suggestions may not make it to
          -- further automatic commands.
          local complete_info = vim.fn.complete_info()
          local items = complete_info and complete_info.items or {}
          local suggestion = suggestion_data_from_completion_item(items[1])
          if suggestion and suggestion.trackingId then
            -- Suggestion selected = 0 or the completion item's zero-based index.
            -- No item selected = -1
            --
            -- See also :help complete_info() since the initial state depends on user configuration.
            if complete_info.selected == 0 or complete_info.selected == -1 then
              suggestion_events[suggestion.trackingId] = {
                action = 'suggestion_rejected',
              }
            end
          end
        end
      end,
      group = options.group,
      desc = 'Process completed KhulnaSoft Code Suggestions.',
    })

    vim.api.nvim_create_autocmd({ 'CompleteDone' }, {
      callback = function()
        local config = require('khulnasoft.config').current()
        if config.language_server.workspace_settings.telemetry.enabled then
          -- If v:completed_item event item was set it might be a code suggestion.
          local completed_item = vim.v.completed_item
          if completed_item then
            local suggestion = suggestion_data_from_completion_item(completed_item)
            if suggestion and suggestion.trackingId then
              suggestion_events[suggestion.trackingId] = {
                action = 'suggestion_accepted',
              }
            end
          end

          -- Flush suggestion telemetry events upon completion so we can rely on the shortlived
          -- lifecycle to avoid mixups due to strange user cancellation/unrelated completion in the
          -- middle of completing a code suggestion.
          for trackingId, event in pairs(suggestion_events) do
            suggestion_events[trackingId] = nil
            code_suggestions_commands.lsp_client:notify('$/khulnasoft/telemetry', {
              category = 'code_suggestions',
              action = event.action,
              context = {
                trackingId = trackingId,
              },
            })
          end
        end

        -- This happens outside of insert mode so should be done after we're done with v:completed_item
        if config.code_suggestions.fix_newlines then
          vim.cmd([[s/\%x00/\r/ge]])
        end
      end,
      group = options.group,
      desc = 'Process completed KhulnaSoft Code Suggestions.',
    })

    vim.api.nvim_create_autocmd({ 'FileType' }, {
      callback = function()
        local config = require('khulnasoft.config').current()
        if config.code_suggestions.enabled then
          code_suggestions_commands:start({ prompt_user = false })
        end
      end,
      desc = 'Start Code Suggestions LSP client integration automatically for filetype',
      group = options.group,
      pattern = require('khulnasoft.config').current().code_suggestions.auto_filetypes,
    })
    --}}}

    --{{{[User-defined commands]
    vim.api.nvim_create_user_command('KhulnaSoftCodeSuggestionsInstallLanguageServer', function()
      return code_suggestions_commands:install_language_server()
    end, {
      desc = 'Installs KhulnaSoft Language Server package.',
    })
    vim.api.nvim_create_user_command('KhulnaSoftCodeSuggestionsStart', function()
      return code_suggestions_commands:start({ prompt_user = true })
    end, {
      desc = 'Starts the Code Suggestions LSP client integration.',
    })
    vim.api.nvim_create_user_command('KhulnaSoftCodeSuggestionsStop', function()
      return code_suggestions_commands:stop()
    end, {
      desc = 'Stops the Code Suggestions LSP client integration.',
    })
    --}}}

    --{{{[Keymaps] Defined as <Plug> keymaps to allows users to decide sensible mappings.
    -- :nmap <C-g> <Plug>(KhulnaSoftToggleCodeSuggestions)
    vim.keymap.set('n', '<Plug>(KhulnaSoftToggleCodeSuggestions)', function()
      return code_suggestions_commands:toggle()
    end, {
      desc = 'Toggle Code Suggestions LSP client integration on/off.',
      noremap = false,
    })
    --}}}
  end,
}

-- vi: set fdm=marker :
