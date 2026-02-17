local Network = require "lib/network/network"
local Server = require "multiplayer/classes/server"
local protocol = require "multiplayer/protocol-kernel/protocol"
local Client_pipe = require "multiplayer/client/client_pipe"

local Client = {}
Client.__index = Client

function Client.new()
    local self = setmetatable({}, Client)

    self.servers = {}
    self.socket = nil
    self.main_server = nil

    CLIENT = self

    return self
end

function Client:connect(address, port, name, state, id, meta)
    local server = Server.new(false, nil, address, port, name)
    self.socket = network.tcp_connect(address, tonumber(port), function (socket)

        local network = Network.new(socket)
        server:set("network", network)
        server.connecting = false
        server.state = state or -1
        socket:set_nodelay(true)

        if meta.on_connect then
            meta.on_connect(server)
        end
    end, function (_, err)
        server.connecting = false
        if meta.on_disconnect then
            meta.on_disconnect(server, err)
        end
    end)

    table.merge(server.meta, meta)
    server.network = {}

    if id then
        server.id = id
    end

    table.insert(self.servers, server)

    return server
end

function Client:queue_response(event)
    for index, server in ipairs(self.servers) do
        server:queue_response(event)
    end
end

function Client:stop()
    self.socket:close()
end

function Client:disconnect()
    for i=#self.servers, 1, -1 do
        local server = self.servers[i]
        local socket = server.network.socket
        server:push_packet(protocol.ClientMsg.Disconnect, {})
        if socket and socket:is_alive() then
            if server.active then
                SHELL.module.handlers.game.on_disconnect(server)
                server.active = false
            end

            if socket and socket:is_alive() then
                socket:close()
            end

            table.remove(self.servers, i)
        end
    end
end

function Client:tick()
    if SERVER and not SERVER.active then SERVER = nil end

    for index, server in ipairs(self.servers) do
        local socket = server.network.socket

        if not ((socket ~= nil and socket:is_alive()) or (server.connecting and not SERVER)) then
            if server.active then
                SHELL.module.handlers.game.on_disconnect(server)
                server.active = false
            end

            if socket and socket:is_alive() then
                socket:close()
            end

            table.remove_value(self.servers, server)
        end

        if socket and socket:is_alive() then
            Client_pipe:process(server)
        end
    end
end

return Client