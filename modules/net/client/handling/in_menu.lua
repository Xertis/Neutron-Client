local protocol = import "net/protocol/protocol"
local hash = import "lib/crypto/hash"
local Player = require "net/classes/player"

local self = Module()
local shared = self.shared
local remote = self.remote
local single = self.single

shared["handshake"] = function(server)
    if server.state == -1 then
        local major, minor = external_app.get_version()
        local engine_version = string.format("%s.%s.0", major, minor)

        local buffer = protocol.create_databuffer()
        buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.HandShake, {
            protocol_reference = "Neutron",
            protocol_version = protocol.Version,
            engine_version = engine_version,
            api_version = API_VERSION,
            friends_list = server.meta.friends_list,
            next_state = protocol.States.Status
        }))
        buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.StatusRequest, {}))

        server.socket:send(buffer.bytes)

        server.state = protocol.States.Status
    end
end

shared[protocol.ServerMsg.StatusResponse] = function(server, packet)
    server.meta.max_online = packet.max
    server.meta.on_status(server, packet)
end

shared[protocol.ServerMsg.Disconnect] = function(server, packet)
    SHELL.module.handlers.game.on_disconnect(server, packet)
    CLIENT:disconnect()
end

remote[protocol.ServerMsg.PacksList] = function(server, packet)
    local packs = packet.packs

    local packs_all = table.unique(table.merge(pack.get_available(), pack.get_installed()))
    local hashes = {}

    table.filter(packs, function(_, val)
        return table.has(packs_all, val)
    end)

    for i = 1, #packs do
        table.insert_unique(CONTENT_PACKS, packs[i])
    end

    local events_handlers = table.copy(events.handlers)

    external_app.reset_content()
    external_app.config_packs(CONTENT_PACKS)

    external_app.load_content()

    events.handlers = table.merge(events_handlers, events.handlers)

    for i, pack in ipairs(packs) do
        table.insert(hashes, {
            pack = pack,
            hash = hash.hash_mods({ pack })
        })
    end

    local buffer = protocol.create_databuffer()

    buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.PackHashes, { hashes }))
    server.socket:send(buffer.bytes)
end

single[protocol.ServerMsg.PacksList] = function(server, packet)
    local packs = packet.packs

    local packs_all = table.unique(table.merge(pack.get_available(), pack.get_installed()))
    local hashes = {}

    table.filter(packs, function(_, val)
        return table.has(packs_all, val)
    end)

    for i = 1, #packs do
        table.insert_unique(CONTENT_PACKS, packs[i])
    end

    for i, pack in ipairs(packs) do
        table.insert(hashes, {
            pack = pack,
            hash = hash.hash_mods({ pack })
        })
    end

    local buffer = protocol.create_databuffer()

    buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.PackHashes, { hashes }))
    server.socket:send(buffer.bytes)
end

remote[protocol.ServerMsg.JoinSuccess] = function(server, packet)
    server.state = protocol.States.Active

    server.active = true

    external_app.reset_content()
    external_app.config_packs(CONTENT_PACKS)

    SERVER = server
    CHUNK_LOADING_DISTANCE = packet.chunks_loading_distance
    CLIENT_PID = packet.pid

    external_app.new_world("", "41530140565755", PACK_ID .. ":void", CLIENT_PID)

    for _, rule in ipairs(packet.rules) do
        rules.set(rule[1], rule[2])
    end

    local player_data = packet.player
    local pos = player_data.pos
    local rot = player_data.rot
    local cheats = player_data.cheats
    player.set_spawnpoint(CLIENT_PID, pos.x, pos.y, pos.z)

    player.set_pos(CLIENT_PID, pos.x, pos.y, pos.z)
    player.set_rot(CLIENT_PID, rot.x, rot.y, rot.z)
    player.set_noclip(CLIENT_PID, cheats.noclip)
    player.set_noclip(CLIENT_PID, cheats.flight)

    player.set_infinite_items(CLIENT_PID, player_data.infinite_items)
    player.set_instant_destruction(CLIENT_PID, player_data.instant_destruction)
    player.set_interaction_distance(CLIENT_PID, player_data.interaction_distance)
    external_app.tick()
end

single[protocol.ServerMsg.JoinSuccess] = function(server, packet)
    server.state = protocol.States.Active

    server.active = true

    SERVER = server
    CHUNK_LOADING_DISTANCE = packet.chunks_loading_distance
    CLIENT_PID = packet.pid

    CLIENT_PLAYER = Player.new(CLIENT_PID, SHELL.module.states.get_username())

    for _, rule in ipairs(packet.rules) do
        rules.set(rule[1], rule[2])
    end
end

return self:build()
