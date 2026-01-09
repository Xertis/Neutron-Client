local events = start_require "api/v2/events"
local bson = require "lib/files/bson"
local db = require "lib/files/bit_buffer"

local module = {
    emitter = {},
    handler = {}
}

function module.emitter.create_send(pack, event)
    return function (...)
        local buffer = db:new()
        bson.encode(buffer, {...})

        events.send(pack, event, buffer.bytes)
    end
end

function module.handler.on(pack, event, handler)
    events.on(pack, event, function (bytes)
        local data = bson.deserialize(bytes)
        handler(unpack(data))
    end)
end

return module