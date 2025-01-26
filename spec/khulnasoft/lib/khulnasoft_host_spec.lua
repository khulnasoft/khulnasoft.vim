describe('khulnasoft.lib.khulnasoft_host', function()
  local khulnasoft_host = require('khulnasoft.lib.khulnasoft_host')

  describe('parse', function()
    local tests = {
      { 'https://khulnasoft.com', { protocol = 'https', hostname = 'khulnasoft.com' } },
      { 'https://khulnasoft.com/', { protocol = 'https', hostname = 'khulnasoft.com' } },
      { 'http://khulnasoft.example.com', { protocol = 'http', hostname = 'khulnasoft.example.com' } },
      { 'http://khulnasoft.example.com/', { protocol = 'http', hostname = 'khulnasoft.example.com' } },
      { 'http://example.com/khulnasoft', { protocol = 'http', hostname = 'example.com' } },
      { 'http://example.com/khulnasoft/', { protocol = 'http', hostname = 'example.com' } },
    }
    for _, test in ipairs(tests) do
      local url, expected = test[1], test[2]
      it(url, function()
        assert.has.same(expected, khulnasoft_host.parse_http_url(url))
      end)
    end
  end)
end)
