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
    local Client = require "client:multiplayer/client/client"

    local client = Client.new()

    session.reset_entry("neutron-client-env")
    local env_meta = {
        __index = PACK_ENV,
        __newindex = function(t, key, value)
            rawset(PACK_ENV, key, value)
        end
    }

    setmetatable(session.get_entry("neutron-client-env"), env_meta)

    events.on("client:.worldtick", function()
        client:tick()
    end)

    IS_REMOTE = false
    return create_stub()
end
