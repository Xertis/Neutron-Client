local protocol = import "net/protocol/protocol"

local module = {}

function module.get_count()
    return table.count_pairs(CLIENT.servers)
end

function module.get_status(ip, id, name, on_status, on_disconnect, friends_list)
    local address, port = string.split_ip(ip)
    friends_list = friends_list or {}

    CLIENT:connect(address, port, name, nil, id, {
        on_status = on_status,
        on_disconnect = on_disconnect,
        on_connect = function (server)
            server.socket:send({0})
        end,
        friends_list = friends_list
    })
end

function module.join(ip, id, identity, username, on_connect, on_disconnect, is_owned)
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

            identity = SHELL.module.players.get_main_identity() or identity
            username = SHELL.module.players.get_main_username() or username

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, {
                username = username,
                identity = identity
            }))
            server.socket:send({(is_owned and 1 or 0)})
            server.socket:send(buffer.bytes)

            if is_owned then
                server.owned = true
            end
        end,

        on_disconnect = on_disconnect
    })
end

function module.disconnect(server, on_disconnect)
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

local function single_connect(port, id, identity, username, on_connect)
    module.join("127.0.0.1:" .. port, id, identity, username, on_connect, function()
        single_connect(port, id, identity, username, on_connect)
    end, true)
end

function module.run_single(name, id, identity, username, on_connect)
    local packinfo = pack.get_info("server")
    local path = packinfo.path

    local port = network.find_free_port()
    external_app.start_background_instance(path .. "/scripts/main.lua", "export:background.log", {
        server_port = port,
        world_name = name,
        standalone = "true"
    })

    single_connect(port, id, identity, username, on_connect)
end

return module
