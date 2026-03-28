local protocol = import "net/protocol/protocol"
local Player = import "net/classes/player"

local api_events = import "api/v2/events"
local api_entities = import "api/v2/entities"
local api_env = import "api/v2/env"
local api_particles = import "managers/particles"
local api_audio = import "managers/audio"
local api_text3d = import "managers/text3d"
local api_wraps = import "managers/wraps"

local inventory_manager = import "managers/inventory"

local self = Module({
    [protocol.ServerMsg.SynchronizePlayer] = function() end,
    [protocol.ServerMsg.ChunkData] = function() end,
    [protocol.ServerMsg.ChunksData] = function() end
})
local shared = self.shared
local remote = self.remote
local single = self.single

shared[protocol.ServerMsg.Disconnect] = function(server, packet)
    SHELL.module.handlers.game.on_disconnect(server, packet)
    CLIENT_PLAYER:set_slot(packet.slot, false)
    CLIENT:disconnect()
end

local function set_player_spawn_pos()
    CLIENT_PLAYER:set_pos(CACHED_DATA.pos, false)
    CLIENT_PLAYER:set_rot(CACHED_DATA.rot, false)
    CLIENT_PLAYER:set_cheats(CACHED_DATA.cheats, false)
    CLIENT_PLAYER:set_inventory(CACHED_DATA.inv, false)
    CLIENT_PLAYER:set_slot(CACHED_DATA.slot, false)
end

remote[protocol.ServerMsg.ChunkData] = function(server, packet)
    local chunk = packet.chunk

    world.set_chunk_data(chunk.x, chunk.z, chunk.data)
    local pos = CACHED_DATA.pos
    if not CACHED_DATA.over and pos then return end

    if math.floor(pos.x / 16) == chunk.x and math.floor(pos.z / 16) == chunk.z then
        CACHED_DATA.over = true
        set_player_spawn_pos()
    end
end

remote[protocol.ServerMsg.ChunksData] = function(server, packet)
    for _, chunk in ipairs(packet.list) do
        world.set_chunk_data(chunk.x, chunk.z, chunk.data)
        local pos = CACHED_DATA.pos
        if pos and not CACHED_DATA.over then
            if math.floor(pos.x / 16) == chunk.x and math.floor(pos.z / 16) == chunk.z then
                CACHED_DATA.over = true
                set_player_spawn_pos()
            end
        end
    end
end

shared[protocol.ServerMsg.BlockChanged] = function(server, packet)
    local pid = packet.pid
    local block_data = packet.block
    local block_pos = block_data.pos

    local old_id = block.get(block_pos.x, block_pos.y, block_pos.z)
    local new_id = block_data.id

    if old_id == -1 then return end

    if pid ~= -1 and pid ~= CLIENT_PLAYER.pid then
        if old_id ~= 0 and new_id == 0 then
            block.destruct(block_pos.x, block_pos.y, block_pos.z, pid)
            return
        elseif old_id == 0 and new_id ~= 0 then
            block.place(block_pos.x, block_pos.y, block_pos.z, new_id, block_data.state, pid)
            return
        end
    end
    block.set(block_pos.x, block_pos.y, block_pos.z, new_id, block_data.state, pid)
end

shared[protocol.ServerMsg.TimeUpdate] = function(server, packet)
    world.set_day_time(packet.game_time)
end

shared[protocol.ServerMsg.ChatMessage] = function(server, packet)
    console.chat(packet.message)
end

remote[protocol.ServerMsg.SynchronizePlayer] = function(server, packet)
    local player_data = packet.data

    CLIENT_PLAYER:set_pos(player_data.pos, false)
    CLIENT_PLAYER:set_rot(player_data.rot, false)
    CLIENT_PLAYER:set_cheats(player_data.cheats, false)
    CLIENT_PLAYER:set_infinite_items(player_data.infinite_items, false)
    CLIENT_PLAYER:set_instant_destruction(player_data.instant_destruction, false)
    CLIENT_PLAYER:set_interaction_distance(player_data.interaction_distance, false)

    if not CACHED_DATA.over then
        CACHED_DATA.pos = player_data.pos
        CACHED_DATA.rot = player_data.rot
        CACHED_DATA.cheats = player_data.cheats
        CACHED_DATA.infinite_items = player_data.infinite_items
        CACHED_DATA.instant_destruction = player_data.instant_destruction
        CACHED_DATA.interaction_distance = player_data.interaction_distance
    end
end

shared[protocol.ServerMsg.PlayerList] = function(server, packet)
    for _, _player in ipairs(packet.list) do
        local pid = _player.pid
        local name = _player.username
        if CLIENT_PLAYER.pid ~= pid then
            player.create(name, pid)
            player.set_loading_chunks(pid, false)
            PLAYER_LIST[pid] = Player.new(pid, name)
        end
    end
end

shared[protocol.ServerMsg.PlayerListRemove] = function(server, packet)
    local player = PLAYER_LIST[packet.data.pid]
    if player then
        player:despawn()
        PLAYER_LIST[packet.data.pid] = nil
    end
end

shared[protocol.ServerMsg.PlayerListAdd] = function(server, packet)
    local pid = packet.data.pid
    local name = packet.data.username

    if CLIENT_PLAYER.pid ~= pid and not PLAYER_LIST[pid] then
        player.create(name, pid)
        player.set_loading_chunks(pid, false)
        PLAYER_LIST[pid] = Player.new(pid, name)

        local data = TEMP_PLAYERS[pid]
        if data then
            TEMP_PLAYERS[pid] = nil
            self[protocol.ServerMsg.PlayerMoved](server, {
                pid = pid,
                data = data
            })
        end
    end
end

shared[protocol.ServerMsg.PlayerMoved] = function(server, packet)
    local player_obj = PLAYER_LIST[packet.pid]

    if not player_obj then
        TEMP_PLAYERS[packet.pid] = packet.data
        return
    end

    if packet.pid == CLIENT_PLAYER.pid then return end

    local data = packet.data

    if data.pos then
        player_obj:set_pos(data.pos)
    end

    player_obj:set_hand_item(data.hand_item)
    player_obj:set_rot(data.rot)
    player_obj:set_cheats(data.cheats)
end

shared[protocol.ServerMsg.KeepAlive] = function(server, packet)
    CLIENT_PLAYER.ping.last_upd = time.uptime()

    server:push_packet(protocol.ClientMsg.KeepAlive, { packet.challenge })
end

shared[protocol.ServerMsg.InventorySync] = function(server, packet)
    inventory_manager.sync(packet.inventory_id, packet.inventory)

    if packet.inventory_id == 1 then
        CACHED_DATA.inv = packet.inventory
    end
end

shared[protocol.ServerMsg.OpenBlockInventory] = function(server, packet)
    inventory_manager.open_block(packet.inventory_id, packet.pos)
end

shared[protocol.ServerMsg.OpenVirtualInventory] = function(server, packet)
    inventory_manager.open_virtual(packet.layout, packet.inventory_id, packet.disable_player_inventory)
end

shared[protocol.ClientMsg.InventoryClose] = function(server, packet)
    inventory_manager.close_inventory()
end

shared[protocol.ServerMsg.PlayerHandSlot] = function(server, packet)
    player.set_selected_slot(hud.get_player(), packet.slot)
    CACHED_DATA.slot = packet.slot
end

shared[protocol.ServerMsg.PlayerUsername] = function(server, packet)
    local player_obj = packet.pid ~= CLIENT_PLAYER.pid and PLAYER_LIST[packet.pid] or CLIENT_PLAYER

    player.set_name(packet.pid, packet.username)
    player_obj.name = packet.username
end

shared[protocol.ServerMsg.PackEvent] = function(server, packet)
    api_events.__emit__(packet.pack, packet.event, packet.bytes)
end

shared[protocol.ServerMsg.PackEnv] = function(server, packet)
    api_env.__env_update__(packet.pack, packet.env, packet.key, packet.value)
end

shared[protocol.ServerMsg.WeatherChanged] = function(server, packet)
    local name = packet.name
    if name == '' then
        name = nil
    end

    gfx.weather.change(
        packet.weather,
        packet.time,
        name
    )
end

shared[protocol.ServerMsg.PlayerFieldsUpdate] = function(server, packet)
    api_entities.__update_player__(packet.pid, packet.dirty)
end

shared[protocol.ServerMsg.EntityUpdate] = function(server, packet)
    api_entities.__emit__(packet.uid, packet.def, packet.dirty)
end

shared[protocol.ServerMsg.EntityDespawn] = function(server, packet)
    api_entities.__despawn__(packet.uid)
end

shared[protocol.ServerMsg.ParticleEmit] = function(server, packet)
    api_particles.emit(packet.particle)
end

shared[protocol.ServerMsg.ParticleStop] = function(server, packet)
    api_particles.stop(packet.pid)
end

shared[protocol.ServerMsg.ParticleOrigin] = function(server, packet)
    api_particles.set_origin(packet.origin)
end

shared[protocol.ServerMsg.AudioEmit] = function(server, packet)
    api_audio.emit(packet.audio)
end

shared[protocol.ServerMsg.AudioStop] = function(server, packet)
    api_audio.stop(packet.id)
end

shared[protocol.ServerMsg.AudioState] = function(server, packet)
    api_audio.apply(packet.state)
end

shared[protocol.ServerMsg.WrapShow] = function(server, packet)
    api_wraps.show(packet)
end

shared[protocol.ServerMsg.WrapHide] = function(server, packet)
    api_wraps.hide(packet.id)
end

shared[protocol.ServerMsg.WrapSetPos] = function(server, packet)
    api_wraps.set_pos(packet.id, packet.pos)
end

shared[protocol.ServerMsg.WrapSetTexture] = function(server, packet)
    api_wraps.set_texture(packet.id, packet.texture)
end

shared[protocol.ServerMsg.WrapSetFaces] = function(server, packet)
    api_wraps.set_faces(packet.id, packet.faces)
end

shared[protocol.ServerMsg.WrapSetTints] = function(server, packet)
    api_wraps.set_tints(packet.id, packet.faces)
end


shared[protocol.ServerMsg.Text3DShow] = function(server, packet)
    api_text3d.show(packet.data)
end

shared[protocol.ServerMsg.Text3DHide] = function(server, packet)
    api_text3d.hide(packet.id)
end

shared[protocol.ServerMsg.Text3DState] = function(server, packet)
    api_text3d.apply(packet.state)
end

shared[protocol.ServerMsg.Text3DAxis] = function(server, packet)
    local state = {
        id = packet.id
    }

    if packet.is_x then
        state.axisX = packet.axis
    else
        state.axisY = packet.axis
    end

    api_text3d.apply(state)
end

return self:build()
