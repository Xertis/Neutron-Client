local Pipeline = require "lib/common/pipeline"
local protocol = require "multiplayer/protocol-kernel/protocol"
local sandbox = require "multiplayer/client/sandbox"

local ServerPipe = Pipeline.new()

--А мы вообще норм?
ServerPipe:add_middleware(function(server)
    if not CACHED_DATA.over then return end
    return server
end)

--Отправляем позицию региона
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.region then
        server:push_packet(protocol.ClientMsg.PlayerRegion, CLIENT_PLAYER.region.x, CLIENT_PLAYER.region.z)
        CLIENT_PLAYER.changed_flags.region = false
    end
    return server
end)

--Отправляем позицию игрока
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.pos then
        server:push_packet(protocol.ClientMsg.PlayerPosition, {CLIENT_PLAYER.pos.x, CLIENT_PLAYER.pos.y, CLIENT_PLAYER.pos.z})
        CLIENT_PLAYER.changed_flags.pos = false
    end
    return server
end)

--Отправляем наши блоки
ServerPipe:add_middleware(function(server)
    server:queue_response(sandbox.get_bytes())
    sandbox.reset_buffer()

    return server
end)

--Отправляем поворот
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.rot then
        server:push_packet(protocol.ClientMsg.PlayerRotation, CLIENT_PLAYER.rot.yaw, CLIENT_PLAYER.rot.pitch)
        CLIENT_PLAYER.changed_flags.rot = false
    end
    return server
end)

--Отправляем читы
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.cheats then
        server:push_packet(protocol.ClientMsg.PlayerCheats, CLIENT_PLAYER.cheats.noclip, CLIENT_PLAYER.cheats.flight)
        CLIENT_PLAYER.changed_flags.cheats = false
    end
    return server
end)

--Отправляем инвентарь
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.inv then
        server:push_packet(protocol.ClientMsg.PlayerInventory, CLIENT_PLAYER.inv)
        CLIENT_PLAYER.changed_flags.inv = false
    end
    return server
end)

--Отправляем выбранный слот
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.slot then
        server:push_packet(protocol.ClientMsg.PlayerHandSlot, CLIENT_PLAYER.slot)
        CLIENT_PLAYER.changed_flags.slot = false
    end
    return server
end)

--Отправляем чексуммы
local last_upd = time.uptime()
ServerPipe:add_middleware(function(server)
    if time.uptime() - last_upd < 5 or true then
        return server
    end

    last_upd = time.uptime()

    local players = {}
    local checksums = {}
    local client_x, client_y, client_z = player.get_pos(CLIENT_PLAYER.pid)

    local render_distance = CHUNK_LOADING_DISTANCE*16

    for pid, _ in pairs(PLAYER_LIST) do
        local x, y, z = player.get_pos(pid)

        if math.euclidian3D(client_x, client_y, client_z, x, y, z) < render_distance then
            table.insert(players, pid)
            table.insert(checksums, vec3.checksum(math.round(x, 1), math.round(y, 1), math.round(z, 1)))
        end
    end

    if #players == 0 then return server end

    server:push_packet(protocol.ClientMsg.PlayerPositionChecksum, players, checksums)

    return server
end)

return ServerPipe