local mock = require('luassert.mock')
local config = require('khulnasoft.config')

describe('khulnasoft.resource_helper', function()
  local resource_helper = require('khulnasoft.resource_helper')
  local config_mock

  before_each(function()
    config_mock = mock(config, true)
    config_mock.current.returns({ khulnasoft_url = 'https://khulnasoft.example.com' })
  end)

  describe('resource_url_to_api_url', function()
    it('returns an error string for an invalid resource type', function()
      local result, err = resource_helper.resource_url_to_api_url(
        'https://khulnasoft.example.com/khulnasoft/khulnasoft/-/invalid_resource_type/1'
      )

      assert.equal(nil, result)
      assert.not_equal(nil, err)
    end)

    it('returns an error string for an invalid url', function()
      local result, err = resource_helper.resource_url_to_api_url('https://example.com/')

      assert.equal(nil, result)
      assert.not_equal(nil, err)
    end)

    it('matches an issue url', function()
      local result, err = resource_helper.resource_url_to_api_url(
        'https://khulnasoft.example.com/khulnasoft/khulnasoft/-/issues/1'
      )

      assert.equal(nil, err)
      assert.equal(
        'https://khulnasoft.example.com/api/v4/projects/khulnasoft%2Fkhulnasoft/issues/1',
        result
      )
    end)

    it('matches a merge request url', function()
      local result, err = resource_helper.resource_url_to_api_url(
        'https://khulnasoft.example.com/khulnasoft/khulnasoft/-/merge_requests/1'
      )

      assert.equal(nil, err)
      assert.equal(
        'https://khulnasoft.example.com/api/v4/projects/khulnasoft%2Fkhulnasoft/merge_requests/1',
        result
      )
    end)

    it('matches an epic url', function()
      local result, err = resource_helper.resource_url_to_api_url(
        'https://khulnasoft.example.com/groups/khulnasoft/a-subgroup/-/epics/1'
      )

      assert.equal(nil, err)
      assert.equal(
        'https://khulnasoft.example.com/api/v4/groups/khulnasoft%2Fa-subgroup/epics/1',
        result
      )
    end)

    it('works when khulnasoft_url includes a relative url and ends in slash', function()
      config_mock.current.returns({ khulnasoft_url = 'https://khulnasoft.example.com/my/relative-url/' })

      local result, err = resource_helper.resource_url_to_api_url(
        'https://khulnasoft.example.com/my/relative-url/groups/khulnasoft/a-subgroup/-/epics/1'
      )

      assert.equal(nil, err)
      assert.equal(
        'https://khulnasoft.example.com/my/relative-url/api/v4/groups/khulnasoft%2Fa-subgroup/epics/1',
        result
      )
    end)
  end)
end)
