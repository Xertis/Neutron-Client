local function prepare_app(app)
    local protect_app = {}

    for key, val in pairs(app) do
        protect_app[key] = function(...)
            if parse_path(debug.getinfo(2).source) == "client" then
                return val(...)
            end
        end
    end

    protect_app.reset_content = function()
        local unresetable = { "client" }

        if SHELL then
            unresetable = { "client", SHELL.prefix }
        end

        app.reset_content(unresetable)
    end

    _G["external_app"] = protect_app
end

local function prepare_pause(pause_menu)
    gui_util.add_page_dispatcher(function(name, args)
        if name == "pause" then
            name = pause_menu
        end

        return name, args
    end)
end

return function(app)
    local post_init = SHELL.module.init or function() end
    prepare_app(app)
    prepare_pause(SHELL.config.layouts.pause)

    table.insert_unique(CONTENT_PACKS, SHELL.prefix)

    local Client = require "client:multiplayer/client/client"

    local client = Client.new()

    _G["/$p"] = table.copy(package.loaded)

    session.reset_entry("neutron-client-env")
    local env_meta = {
        __index = PACK_ENV,
        __newindex = function(t, key, value)
            rawset(PACK_ENV, key, value)
        end
    }

    setmetatable(session.get_entry("neutron-client-env"), env_meta)

    post_init()

    local function main()
        while true do
            client:tick()
            external_app.tick()
        end
    end

    xpcall(main, function(error)
        print(debug.traceback(error, 2))
    end)
end
