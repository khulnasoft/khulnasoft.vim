local git_remote = require('khulnasoft.lib.git_remote')
local jobs = require('khulnasoft.lib.jobs')
local stub = require('luassert.stub')

describe('khulnasoft.lib.git_remote', function()
  local snapshot

  before_each(function()
    snapshot = assert:snapshot()
  end)

  after_each(function()
    snapshot:revert()
  end)

  it('includes the origin remote', function()
    stub(jobs, 'start_wait').returns({
      exit_code = 0,
      stderr = '',
      stdout = vim.fn.join({
        'origin\tgit@github.com:khulnasoft/khulnasoft.vim.git (fetch)',
        'origin\tgit@github.com:khulnasoft/khulnasoft.vim.git (push)',
      }, '\n'),
    }, nil)

    local expected = {
      origin = 'git@github.com:khulnasoft/khulnasoft.vim.git',
    }

    assert.is.same(expected, git_remote.remotes())
  end)

  it('includes all remotes', function()
    stub(jobs, 'start_wait').returns({
      exit_code = 0,
      stderr = '',
      stdout = vim.fn.join({
        'community\tgit@khulnasoft.com:khulnasoft-community/khulnasoft-vscode-extension (fetch)',
        'community\tgit@khulnasoft.com:khulnasoft-community/khulnasoft-vscode-extension (push)',
        'khulnasoft-renovate-fork\tgit@khulnasoft.com:khulnasoft-renovate-forks/khulnasoft-vscode-extension.git (fetch)',
        'khulnasoft-renovate-fork\tgit@khulnasoft.com:khulnasoft-renovate-forks/khulnasoft-vscode-extension.git (push)',
        'origin\tgit@khulnasoft.com:khulnasoft/khulnasoft-vscode-extension (fetch)',
        'origin\tgit@khulnasoft.com:khulnasoft/khulnasoft-vscode-extension (push)',
      }, '\n'),
    }, nil)

    local expected = {
      community = 'git@khulnasoft.com:khulnasoft-community/khulnasoft-vscode-extension',
      origin = 'git@khulnasoft.com:khulnasoft/khulnasoft-vscode-extension',
      ['khulnasoft-renovate-fork'] = 'git@khulnasoft.com:khulnasoft-renovate-forks/khulnasoft-vscode-extension.git',
    }

    assert.is.same(expected, git_remote.remotes())
  end)
end)
