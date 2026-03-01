local events = start_require "api/v2/events"
local bson = require "lib/files/bson"

local module = {
    emitter = {},
    handler = {}
}

function module.emitter.create_send(pack, event)
    return function(...)
        local bytes = compression.encode(bson.serialize({ ... }))

        events.send(pack, event, bytes)
    end
end

function module.handler.on(pack, event, handler)
    events.on(pack, event, function(bytes)
        local data = bson.deserialize(compression.decode(bytes))
        handler(unpack(data))
    end)
end

return module
