local protocol = require "multiplayer/protocol-kernel/protocol"

local in_menu_handlers = require "multiplayer/client/handling/in_menu"
local in_game_handlers = nil

local server_pipe = require "multiplayer/sending/server_pipe"

local Pipeline = require "lib/common/pipeline"
local List = require "lib/common/list"

local receiver = require "multiplayer/protocol-kernel/receiver"

local ClientPipe = Pipeline.new()

ClientPipe:add_middleware(function(server)
    local meta = server.meta
    local co = meta.receive_co

    if not co then
        meta.buffer = receiver.create_buffer()
        co = coroutine.create(function()
            local buffer = meta.buffer

            while true do
                local success, packet = pcall(protocol.parse_packet, "server", buffer)

                if success and packet then
                    List.pushright(server.received_packets, packet)
                else
                    if not success then
                        logger.log("Error while parsing packet: " .. tostring(packet) .. '\nClient disconnected', 'E')
                        if CLIENT then CLIENT:disconnect() end
                    end

                    coroutine.yield()
                end
            end
        end)
        meta.receive_co = co
    end

    receiver.recv(meta.buffer, server)
    coroutine.resume(co)

    return server
end)

ClientPipe:add_middleware(function(server)
    if server.state == -1 then
        in_menu_handlers["handshake"](server)
    end

    while not List.is_empty(server.received_packets) do
        local packet = List.popleft(server.received_packets)

        local success, err = pcall(function()
            if server.state ~= protocol.States.Active then
                in_menu_handlers[packet.packet_type](server, packet)
            elseif server.state == protocol.States.Active then
                if not world.is_open() then return end
                if not in_game_handlers then in_game_handlers = require "multiplayer/client/handling/in_game" end
                in_game_handlers[packet.packet_type](server, packet)
            end
        end)

        if not success then
            logger.log("Error while reading packet: " .. err, 'E')
            logger.log("Packet type: " .. packet.packet_type, 'E')
            print(debug.traceback())
        end
    end

    return server
end)

ClientPipe:add_middleware(function(server)
    if server.state == protocol.States.Active then
        server_pipe:process(server)
    end

    local socket = server.socket
    while not List.is_empty(server.response_queue) do
        local packet = List.popleft(server.response_queue)
        local success, err = pcall(socket.send, socket, packet)
        if not success then
            break
        end
    end
    return server
end)

return ClientPipe
