local M = {}

local function ensure_packer()
  local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end

  return false
end

function M.setup()
  local packer_bootstrap = ensure_packer()
  return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
    if vim.env.LSP_INSTALLER == 'mason' then
      use 'williamboman/mason.nvim'
    end

    use {
      'https://github.com/khulnasoft/khulnasoft.vim.git',
      branch = vim.env.KHULNASOFT_VIM_BRANCH or 'main',
      config = function()
        require('khulnasoft').setup({})

        if vim.env.LSP_INSTALLER == 'khulnasoft.vim' then
          vim.cmd.KhulnaSoftCodeSuggestionsInstallLanguageServer()
        end
      end,
    }

    if packer_bootstrap then
      require('packer').sync()
    end
  end)
end

return M
