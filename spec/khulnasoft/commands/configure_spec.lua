describe('khulnasoft.commands.configure', function()
  local configure_command = require('khulnasoft.commands.configure')
  local match = require('luassert.match')
  local mock = require('luassert.mock')
  local stub = require('luassert.stub')

  local snapshot
  before_each(function()
    snapshot = assert:snapshot()
  end)

  after_each(function()
    snapshot:revert()
  end)

  describe('create', function()
    before_each(function()
      stub(vim.api, 'nvim_create_user_command')
    end)

    it('registers vim command', function()
      configure_command.create({
        auth = mock(require('khulnasoft.authentication.provider.env')),
        workspace = mock(require('khulnasoft.lsp.workspace')),
      })
      assert
        .stub(vim.api.nvim_create_user_command).was
        .called_with('KhulnaSoftConfigure', match._, match._)
    end)
  end)
end)
