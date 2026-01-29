local protocol = start_require "multiplayer/protocol-kernel/protocol"
local data = require "api/v2/launcher/data"

local module = {}

local launcher_handlers = {}

--[[
join_success - при подключении к серверу (в мир)
]]
function module.set_handlers(handlers)
    table.merge(launcher_handlers, handlers)
end

function module.get_count()
    return table.count_pairs(CLIENT.servers)
end

function module.get_status(ip, id, on_get_info, on_disconnect)
    local address, port = string.split_ip(ip)

    CLIENT:connect(address, port, nil, id, {
        on_get_info = on_get_info,
        on_disconnect = on_disconnect
    })
end

function module.join(ip, id, username, on_connect, on_disconnect)
    local address, port = string.split_ip(ip)
    CLIENT:connect(address, port, protocol.States.Login, id, {
        on_connect = function (server)
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

            local identity = data.get_identity(username) or username

            buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.JoinGame, {
                username = username,
                identity = identity
            }))
            server.network:send(buffer.bytes)
        end,

        on_disconnect = on_disconnect
    })
end

function module.disconnect(server)
    if server then
        local socket = server.network.socket
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
end

function module.__join_success(server)
    launcher_handlers.join_success(server)
end

return module