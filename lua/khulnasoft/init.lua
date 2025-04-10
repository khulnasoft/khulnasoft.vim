if RunningApp ~= nil then
    pcall(CLOSE)
end

local plenary = require("plenary.reload")
plenary.reload_module("khulnasoft")

local TCP = require("khulnasoft.tcp").TCP
local App = require("khulnasoft.app")

---@type VWMApp | nil
RunningApp = nil

assert(RunningApp == nil, "client already started")

local conn = TCP:new()
conn:start(function()
    local function handle_commands(cmd)
        print("handled command", vim.inspect(cmd))
    end
    RunningApp = App:new(conn):on_cmd_received(handle_commands)
end)

function CLOSE()
    assert(RunningApp ~= nil, "app not started")
    RunningApp:close()
end
