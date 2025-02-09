local mock = require('luassert.mock')
local spy = require('luassert.spy')
local match = require('luassert.match')

assert:register('matcher', 'has_property', function(_state, arguments)
  return function(value)
    if value == nil then
      return false
    end

    local actual = value[arguments[1]]
    local expected = arguments[2]

    return actual == expected
  end
end)

describe('khulnasoft.utils', function()
  local utils = require('khulnasoft.utils')

  describe('formatted_line_for_print', function()
    it('prints a formatted line', function()
      assert.equal('[khulnasoft.vim] test', utils.formatted_line_for_print('test'))
    end)
  end)

  describe('current_os', function()
    it('returns the current OS, downcased', function()
      local loop = mock(vim.loop, true)
      loop.os_uname.returns({
        sysname = 'fakeOS',
        machine = 'fakeArch',
      })

      assert.equal('fakeos', utils.current_os())

      mock.revert(loop)
    end)
  end)

  describe('current_arch', function()
    it('returns the current CPU architecture, downcased', function()
      local loop = mock(vim.loop, true)
      loop.os_uname.returns({
        sysname = 'fakeOS',
        machine = 'fakeArch',
      })

      assert.equal('fakearch', utils.current_arch())
      mock.revert(loop)
    end)
  end)

  describe('exec_cmd', function()
    it('calls jobstart with the _right_ arguments', function()
      local job = "echo -n 'true'"

      spy.on(vim.fn, 'jobstart')

      utils.exec_cmd(job, {}, function() end)

      assert.spy(vim.fn.jobstart).was_called_with(job, match.is_table())
    end)

    it('calls jobstart with the _right_ current working directory', function()
      local job = "echo -n 'true'"

      spy.on(vim.fn, 'jobstart')

      local expected_cwd = debug.getinfo(1).source:match('@?(/.*/)utils_spec.lua')
      utils.exec_cmd(job, { cwd = expected_cwd }, function() end)

      assert.spy(vim.fn.jobstart).was_called_with(job, match.has_property('cwd', expected_cwd))
    end)
  end)

  describe('joinpaths', function()
    it('returns the empty string given no arguments', function()
      assert.equal('', utils.joinpath())
    end)

    it('returns the empty string given the empty string', function()
      assert.equal('', utils.joinpath(''))
    end)

    it('returns / given /', function()
      assert.equal('/', utils.joinpath('/'))
    end)

    it('returns one path segment as-is', function()
      assert.equal('foo', utils.joinpath('foo'))
    end)

    it('joins path segments with a /', function()
      assert.equal('foo/bar/baz', utils.joinpath('foo', 'bar', 'baz'))
    end)

    it('merges consecutive / characters', function()
      -- From https://github.com/neovim/neovim/blob/v0.10.0/test/functional/lua/fs_spec.lua#L318
      assert.equal('foo/bar/baz', utils.joinpath('foo', '/bar/', '/baz'))
    end)
  end)
end)
