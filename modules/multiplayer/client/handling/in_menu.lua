local Player = require "multiplayer/classes/player"
local protocol = require "multiplayer/protocol-kernel/protocol"
local hash = require "lib/common/hash"

local handlers = {}

handlers["handshake"] = function (server)
    if server.state == 0  then
        local major, minor = external_app.get_version()
        local engine_version = string.format("%s.%s.0", major, minor)

        local buffer = protocol.create_databuffer()
        buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, engine_version, "Neutron", protocol.data.version, CONFIG.Account.friends, protocol.States.Status))
        buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.StatusRequest))
        server.network:send(buffer.bytes)

        server.state = protocol.States.Status
    end
end

handlers[protocol.ServerMsg.StatusResponse] = function (server, packet)
    server.meta.max_online = packet.max
    server.handlers.on_change_info(server, packet)
end

handlers[protocol.ServerMsg.Disconnect] = function (server, packet)
    menu:reset()
    menu.page = "quartz_connection"
    local document = Document.new("quartz:pages/quartz_connection")
    document.info.text = packet.reason
    CLIENT:disconnect()
end

handlers[protocol.ServerMsg.PacksList] = function (server, packet)
    local packs = packet.packs

    local packs_all = table.unique(table.merge(pack.get_available(), pack.get_installed()))
    local hashes = {}

    table.filter(packs, function (_, val)
        return table.has(packs_all, val)
    end)

    for i=1, #packs do
        table.insert_unique(CONTENT_PACKS, packs[i])
    end

    local events_handlers = table.copy(events.handlers)

    external_app.reset_content()
    external_app.config_packs(CONTENT_PACKS)
    external_app.load_content()

    events.handlers = events_handlers

    for i, pack in ipairs(packs) do
        table.insert(hashes, pack)
        table.insert(hashes, hash.hash_mods({ pack }))
    end

    local buffer = protocol.create_databuffer()

    buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.PacksHashes, hashes))
    server.network:send(buffer.bytes)
end

handlers[protocol.ServerMsg.JoinSuccess] = function (server, packet)
    server.state = protocol.States.Active

    SERVER = server

    external_app.new_world("", "41530140565755", PACK_ID .. ":void", packet.entity_id)
    CLIENT.pid = packet.entity_id

    CHUNK_LOADING_DISTANCE = packet.chunks_loading_distance

    for _, rule in ipairs(packet.rules) do
        rules.set(rule[1], rule[2])
    end

    CLIENT_PLAYER = Player.new(hud.get_player(), CONFIG.Account.name)
end

return handlers