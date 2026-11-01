local protocol = import "net/protocol/protocol"
local hash = import "lib/crypto/hash"
local content_loader = import "init/content_loader"

local module = {}
local content_sources = {}

module[protocol.ServerMsg.StatusResponse] = function(server, packet)
    server.meta.max_online = packet.max
    server.meta.on_status(server, packet)
end

module[protocol.ServerMsg.Disconnect] = function(server, packet)
    SHELL.module.handlers.game.on_disconnect(server, packet)
    CLIENT:disconnect()
end

module[protocol.ServerMsg.PacksList] = function(server, packet)
    local packs = packet.packs

    local packs_all = table.unique(table.merge(pack.get_available(), pack.get_installed()))
    local cached_packs = {}
    local hashes = {}
    content_sources = {}

    if (file.isdir(PACKS_CACHE_PATH) == true) then
        cached_packs = file.list(PACKS_CACHE_PATH)
        table.filter(cached_packs, function(_, path)
            return file.isdir(path)
        end)
        table.sort(cached_packs)
    end

    local function add_pack_source(pack_id, source)
        if (content_sources[pack_id] == nil) then
            content_sources[pack_id] = {}
        end
        table.insert(content_sources[pack_id], source)
    end

    for _, pack_id in ipairs(packs) do
        if (table.has(packs_all, pack_id)) then
            add_pack_source(pack_id, "")
            table.insert_unique(CONTENT_PACKS, pack_id)
            table.insert(hashes, {
                pack = pack_id,
                hash = hash.hash_pack(pack_id)
            })
        end
        for _, path in ipairs(cached_packs) do
            local id, directory_hash = unpack(string.split(file.name(path), "#"))
            if (pack_id ~= id or directory_hash ~= hash.hash_directory(path)) then
                goto continue
            end

            add_pack_source(pack_id, path)
            table.insert_unique(CONTENT_PACKS, pack_id)
            table.insert(hashes, {
                pack = pack_id,
                hash = directory_hash
            })

            ::continue::
        end
    end

    local buffer = protocol.create_databuffer()

    buffer:put_packet(protocol.build_packet("client", protocol.ClientMsg.PackHashes, { hashes = hashes }))
    server.socket:send(buffer.bytes)
end

module[protocol.ServerMsg.JoinSuccess] = function(server, packet)
    server.meta.pending_join = packet
end

function module.finish_join(server, packet)
    external_app.reset_content()

    local sources = external_app.get_content_sources()

    local content_hash_indexes = json.parse(packet.content_hash_indexes)
    for pack_id, index in pairs(content_hash_indexes) do
        local source = content_sources[pack_id][index]
        if (#source ~= 0) then
            table.insert(sources, 1, source)
        end
    end

    external_app.set_content_sources(sources)
    external_app.config_packs(CONTENT_PACKS)

    SERVER = server
    CHUNK_LOADING_DISTANCE = packet.max_view_distance
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

    external_app.tick()

    world.set_chunk_data(math.floor(pos.x / 16), math.floor(pos.z / 16), packet.spawn_chunk)

    player.set_rot(CLIENT_PID, rot.x, rot.y, rot.z)
    player.set_noclip(CLIENT_PID, cheats.noclip)
    player.set_flight(CLIENT_PID, cheats.flight)

    player.set_infinite_items(CLIENT_PID, player_data.infinite_items)
    player.set_instant_destruction(CLIENT_PID, player_data.instant_destruction)
    player.set_interaction_distance(CLIENT_PID, player_data.interaction_distance)

    server.active = true
    server.state = protocol.States.Active
end

module[protocol.ServerMsg.ContentData] = function(server, packet)
    if (packet.next_state == 1) then
        content_loader.finish(server.ip)
        return
    end
    content_loader.feed(server.ip, packet.bytes)

    server:push_packet(protocol.ClientMsg.ContentRequest, {
        content_list = {},
        next_state = 1
    })
end

return module
