local M = {}

function M.setup()
  local lazypath = vim.fn.stdpath('data') .. '/site/pack/plugin_managers/opt/lazy.nvim'
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/folke/lazy.nvim.git',
      '--branch=stable', -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  local plugins = {
  }

  if vim.env.LSP_INSTALLER == 'mason' then
    table.insert(plugins, {
     'williamboman/mason.nvim'
   })
  end

  table.insert(plugins, {
    'https://github.com/khulnasoft/khulnasoft.vim.git',
    branch = vim.env.KHULNASOFT_VIM_BRANCH or 'main',
    config = function()
      require('khulnasoft').setup({})

      if vim.env.LSP_INSTALLER == 'khulnasoft.vim' then
        vim.cmd.KhulnaSoftCodeSuggestionsInstallLanguageServer()
      end
    end,
  })

  require('lazy').setup(plugins)
end

return M
