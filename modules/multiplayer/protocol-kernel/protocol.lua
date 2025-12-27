
local bit_buffer = require "lib/files/bit_buffer"
local kernel = require "multiplayer/protocol-kernel/kernel"
local protocol = {}

logger.log("Initializing protocol...")
kernel.__init()
logger.log("Protocol initialized")

function protocol.create_databuffer(bytes)
    local buf = bit_buffer:new(bytes, "BE")

    function buf.ownDb:put_packet(packet)
        self:put_bytes(packet)
    end

    function buf.ownDb:set_be()
        self:set_order("BE")
    end

    function buf.ownDb:set_le()
        self:set_order("LE")
    end

    return buf
end

function protocol.build_packet(client_or_server, packet_type, data)
    local buffer = protocol.create_databuffer()
    buffer:put_byte(packet_type)

    local state, res = pcall(kernel.write, buffer, client_or_server, kernel[client_or_server].ids[packet_type], data)

    if not state then
        logger.log("Packet encoding crash, additional information in server.log", 'E')

        logger.log("Error: " .. res, 'E', true)

        logger.log("Traceback:", 'E', true)
        logger.log(debug.traceback(), 'E', true)

        logger.log("Packet:", 'E', true)
        logger.log(table.tostring({client_or_server, packet_type}), 'E', true)

        logger.log("Data:", 'E', true)
        logger.log(json.tostring(data), 'E', true)
        return {}
    end
    buffer:flush()
    return buffer.bytes
end

function protocol.parse_packet(client_or_server, data)
    local result = {}
    local buffer = nil

    if type(data) ~= "function" then
        buffer = protocol.create_databuffer()
        buffer:put_bytes(data)
        buffer:reset()
    else
        buffer = protocol.create_databuffer()
        buffer.receive_func = data
    end

    local packet_type = buffer:get_byte()

    local state, res = pcall(kernel.read, buffer, client_or_server, kernel[client_or_server].ids[packet_type])

    if not state then
        logger.log("Packet parsing crash, additional information in server.log", 'E')

        logger.log("Error: " .. res, 'E', true)

        logger.log("Traceback:", 'E', true)
        logger.log(debug.traceback(), 'E', true)

        logger.log("Packet:", 'E', true)
        logger.log(table.tostring({client_or_server, packet_type}), 'E', true)

        logger.log("Data:", 'E', true)
        logger.log(table.tostring(data), 'E', true)
        return {}
    end

    table.merge(result, res)
    result.packet_type = packet_type

    return result
end

protocol.ClientMsg = kernel.client.ids
protocol.ServerMsg = kernel.server.ids
protocol.States = PROTOCOL_STATES

protocol.Version = PROTOCOL_VERSION

return protocol