local protocol = require "multiplayer/protocol-kernel/protocol"
local List = require "lib/common/list"

local Server = {}
local max_id = 0
Server.__index = Server

function Server.new(active, network, address, port, name)
    local self = setmetatable({}, Server)

    self.active = false or active
    self.network = network
    self.address = address
    self.port = port
    self.name = name
    self.id = max_id
    self.state = -1
    self.connecting = true
    self.tries = 0
    self.ping = {ping = 0, last_upd = 0}
    self.meta = {max_online = 0}
    self.ip = address .. ':' .. port

    self.handlers = {
        on_connect = nil,
        on_status = nil,
        on_join = nil,
        on_leave = nil,
        on_disconnect = nil
    }

    self.response_queue = List.new()
    self.received_packets = List.new()

    max_id = max_id + 1

    return self
end

function Server:is_active()
    return self.active
end

function Server:set_active(new_value)
    self.active = new_value
end

function Server:set(key, val)
    self[key] = val
end

function Server:push_packet(packet_type, data)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(protocol.build_packet("client", packet_type, data))
    self:queue_response(buffer.bytes)
end

function Server:queue_response(event)
    List.pushright(self.response_queue, event)
end

return Server