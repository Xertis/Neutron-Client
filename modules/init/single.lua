local function create_stub()
    local module = {
        states = {},
        handlers = {
            game = {}
        }
    }

    function module.init() end

    function module.states.get_identity()
        return "player"
    end

    function module.states.get_username()
        return "player"
    end

    function module.handlers.game.join(server, client_player) end

    function module.handlers.game.on_disconnect(server, packet) end

    return module
end

return function()
    IS_REMOTE = false
    local Client = import "net/client/client"

    local client = Client.new()

    session.reset("neutron-client-env")
    local env_meta = {
        __index = PACK_ENV,
        __newindex = function(t, key, value)
            rawset(PACK_ENV, key, value)
        end
    }

    setmetatable(session.get("neutron-client-env"), env_meta)

    events.on("server:content_loaded", function()
        events.on("server:main_tick", function()
            client:tick()
        end)
    end)

    return create_stub()
end
