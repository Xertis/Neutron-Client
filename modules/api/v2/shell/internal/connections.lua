local protocol = import "net/protocol/protocol"

local self = Module()
local shared = self.shared
local remote = self.remote
local single = self.single

function shared.get_count()
    return table.count_pairs(CLIENT.servers)
end

function shared.get_status(ip, id, name, on_status, on_disconnect, friends_list)
    local address, port = string.split_ip(ip)
    friends_list = friends_list or {}

    CLIENT:connect(address, port, name, nil, id, {
        on_status = on_status,
        on_disconnect = on_disconnect,
        friends_list = friends_list
    })
end

function remote.join(ip, id, identity, username, on_connect, on_disconnect)
    local address, port = string.split_ip(ip)
    CLIENT:connect(address, port, "main", protocol.States.Login, id, {
        on_connect = function(server)
            on_connect(server)
            local buffer = protocol.create_databuffer()

            local major, minor = external_app.get_version()
            local engine_version = string.format("%s.%s.0", major, minor)

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, {
                protocol_reference = "Neutron",
                protocol_version = protocol.Version,

                engine_version = engine_version,
                api_version = API_VERSION,
                friends_list = {},
                next_state = protocol.States.Login
            }))

            identity = SHELL.module.states.get_identity() or identity
            username = SHELL.module.states.get_username() or username

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, {
                username = username,
                identity = identity
            }))
            server.socket:send(buffer.bytes)
        end,

        on_disconnect = on_disconnect
    })
end

function single.join(ip, id, identity, username, on_connect, on_disconnect)
    local address, port = string.split_ip(ip)
    CLIENT:virtual_connect(address, port, "main", protocol.States.Login, id, {
        on_connect = function(server)
            on_connect(server)
            local buffer = protocol.create_databuffer()

            local major, minor = 0, 31
            local engine_version = string.format("%s.%s.0", major, minor)

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, {
                protocol_reference = "Neutron",
                protocol_version = protocol.Version,

                engine_version = engine_version,
                api_version = API_VERSION,
                friends_list = {},
                next_state = protocol.States.Login
            }))

            identity = SHELL.module.states.get_identity() or identity
            username = SHELL.module.states.get_username() or username

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, {
                username = username,
                identity = identity
            }))
            server.socket:send(buffer.bytes)
        end,

        on_disconnect = on_disconnect
    })
end

function shared.disconnect(server, on_disconnect)
    on_disconnect = on_disconnect or function() end

    if server then
        local socket = server.socket
        server:push_packet(protocol.ClientMsg.Disconnect, {})

        if server.active then
            server.active = false
        end

        if socket and socket:is_alive() then
            socket:close()
        end
    else
        CLIENT:disconnect()
    end

    on_disconnect()
end

return self:build()
