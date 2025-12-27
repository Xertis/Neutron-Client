local protocol = require "multiplayer/protocol-kernel/protocol"

local module = {}
local handlers = {}

function module.send(pack, event, bytes)
    SERVER:push_packet(protocol.ClientMsg.PackEvent, {
        pack = pack,
        event = event,
        bytes = bytes
    })
end

function module.on(pack, event, func)
    local pack_handlers = table.set_default(handlers, pack, {})
    local pack_handler_events = table.set_default(pack_handlers, event, {})

    table.insert(pack_handler_events, func)
end

function module.__emit__(pack, event, bytes)
    table.set_default(handlers, pack, {})
    table.set_default(handlers[pack], event, {})

    for _, func in ipairs(handlers[pack][event]) do
        func(bytes)
    end
end

return module
