local Network = require "lib/network/network"
local socketlib = require "lib/network/socketlib"
local Server = require "multiplayer/classes/server"
local Client_pipe = require "multiplayer/client/client_pipe"

local Client = {}
Client.__index = Client

function Client.new()
    local self = setmetatable({}, Client)

    self.servers = {}
    self.socket = nil
    self.main_server = nil
    self.pid = 0

    CLIENT = self

    return self
end

function Client:connect(address, port, name, state, id, handlers)
    local server = Server.new(false, nil, address, port, name)
    self.socket = socketlib.connect(address, tonumber(port), function (socket)
        local network = Network.new(socket)
        server:set("network", network)
        server.connecting = false
        server.state = state or -1
        socket:set_nodelay(true)

        if handlers.on_connect then
            handlers.on_connect(server)
        end
    end, function ()
        server.connecting = false
    end)

    server.handlers = handlers
    server.network = {}
    server.id = id

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
    if world.is_open() then
        external_app.close_world()
    end

    for i=#self.servers, 1, -1 do
        local server = self.servers[i]
        local socket = server.network.socket
        if socket and socket:is_alive() then
            if server.active then
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
    for index, server in ipairs(self.servers) do
        local socket = server.network.socket
        if not ((socket and socket:is_alive()) or (server.connecting and not self.main_server) or (self.main_server == server)) then
            if server.active then
                server.active = false
            end

            local global_server = SERVER or {}
            if server.id == global_server.id then
                if world.is_open() then
                    leave_to_menu()
                end
            end

            if socket and socket:is_alive() then
                socket:close()
            end

            if server.handlers.on_disconnect then
                server.handlers.on_disconnect(server)
            end

            table.remove_value(self.servers, server)
        end

        if socket and socket:is_alive() then
            Client_pipe:process(server)
        end
    end
end

return Client