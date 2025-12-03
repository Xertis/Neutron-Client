require "quartz:constants"
require "quartz:globals"
require "quartz:std/stdboot"
require "quartz:init/client"
local Client = require "quartz:multiplayer/client/client"

local client = Client.new()

menu.page = "servers"

_G["/$p"] = table.copy(package.loaded)

local function main()
    while true do
        client:tick()
        external_app.tick()
    end
end

xpcall(main, function (error)
    print(debug.traceback(error, 2))
end)