local function prepare_app(app)
    local protect_app = {}

    for key, val in pairs(app) do
        protect_app[key] = function (...)
            if parse_path(debug.getinfo(2).source) == "client" then
                return val(...)
            end
        end
    end

    protect_app.reset_content = function ()
        local unresetable = {"client"}

        if LAUNCHER_PACK then
            unresetable = {"client", LAUNCHER_PACK}
        end

        app.reset_content(unresetable)
    end

    _G["external_app"] = protect_app
end

return function(app, after_init)
    after_init = after_init or function () end
    prepare_app(app)

    require "client:constants"
    require "client:globals"
    require "client:std/stdboot"
    require "client:std/stdmin"
    local Client = require "client:multiplayer/client/client"

    local client = Client.new()

    _G["/$p"] = table.copy(package.loaded)

    after_init()

    local function main()
        while true do
            client:tick()
            external_app.tick()
        end
    end

    xpcall(main, function (error)
        print(debug.traceback(error, 2))
    end)
end