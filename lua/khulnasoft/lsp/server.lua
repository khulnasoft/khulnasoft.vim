local utils = require('khulnasoft.utils')

local M = {}

local function resolve_exepath()
  local path = vim.env.KHULNASOFT_VIM_LSP_BINARY_PATH

  if not path then
    local config = require('khulnasoft.config').current()
    path = config.code_suggestions.lsp_binary_path
  end

  if not path then
    path = 'node'
  end

  return vim.fn.exepath(path)
end

local function resolve_node_main_script()
  local lsp_package_dir =
    utils.joinpath(require('khulnasoft').plugin_root(), 'node_modules', '@khulnasoft', 'khulnasoft-lsp')

  local package_json = io.open(utils.joinpath(lsp_package_dir, 'package.json'), 'r')

  if not package_json then
    return ''
  end

  local json = package_json:read('*a')
  package_json:close()

  return utils.joinpath(lsp_package_dir, vim.json.decode(json)['bin']['khulnasoft-lsp'])
end

function M.new()
  local exepath = resolve_exepath()
  local node_main_script = resolve_node_main_script()

  return {
    cmd = function(self, opts)
      opts = opts or {}
      local args = vim.deepcopy(opts.args) or {}
      if self.is_node() then
        table.insert(args, 1, node_main_script)
      end

      return vim.tbl_flatten({ exepath, args })
    end,
    is_executable = function()
      return exepath ~= ''
    end,
    is_installed = function(self)
      if not self.is_executable() then
        return false
      end

      if self.is_node() then
        return node_main_script ~= '' and vim.loop.fs_stat(node_main_script)
      end

      return true
    end,
    is_node = function()
      return exepath:match('/node$')
    end,
  }
end

return M
