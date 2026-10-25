local shell_packs = import "api/v2/shell/internal/packs"
local runtime = import "init/runtime"

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
            for _, id in ipairs(shell_packs.get_shell_packs()) do
                table.insert_unique(unresetable, id)
            end
        end

        app.reset_content(unresetable)
    end

    _G["external_app"] = protect_app
    return protect_app
end

return function(app)
    local post_init = SHELL.module.init or function() end

    session.get("neutron-runtime").external_app = prepare_app(app)
    runtime.attach()

    post_init()

    local app_tick = external_app.tick

    local function main()
        while true do
            runtime.tick()
            app_tick()
        end
    end

    xpcall(main, function(error)
        print(debug.traceback(error, 2))
    end)
end
