local events = import "api/v1/events"
local bson = import "lib/data/bson"
local db = import "lib/io/bit_buffer"

local module = {
    emitter = {},
    handler = {}
}

function module.emitter.create_send(pack, event)
    return function(...)
        local buffer = db:new()
        bson.encode(buffer, { ... })

        events.send(pack, event, buffer.bytes)
    end
end

return module
