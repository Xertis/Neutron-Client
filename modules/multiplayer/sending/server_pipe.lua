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
        server:push_packet(protocol.ClientMsg.PlayerRegion, {
            x = CLIENT_PLAYER.region.x,
            z = CLIENT_PLAYER.region.z
        })
        CLIENT_PLAYER.changed_flags.region = false
    end
    return server
end)

--Отправляем позицию игрока
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.pos then
        server:push_packet(protocol.ClientMsg.PlayerPosition, {
            pos = {
                CLIENT_PLAYER.pos.x,
                CLIENT_PLAYER.pos.y,
                CLIENT_PLAYER.pos.z
            }
        })
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
        server:push_packet(protocol.ClientMsg.PlayerRotation, {
            x = CLIENT_PLAYER.rot.x,
            y = CLIENT_PLAYER.rot.y,
            z = CLIENT_PLAYER.rot.z
        })
        CLIENT_PLAYER.changed_flags.rot = false
    end
    return server
end)

--Отправляем читы
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.cheats then
        server:push_packet(protocol.ClientMsg.PlayerCheats, {
            noclip = CLIENT_PLAYER.cheats.noclip,
            flight = CLIENT_PLAYER.cheats.flight
        })
        CLIENT_PLAYER.changed_flags.cheats = false
    end
    return server
end)

--Отправляем инвентарь
-- ServerPipe:add_middleware(function(server)
--     if CLIENT_PLAYER.changed_flags.inv then
--         server:push_packet(protocol.ClientMsg.PlayerInventory, { CLIENT_PLAYER.inv })
--         CLIENT_PLAYER.changed_flags.inv = false
--     end
--     return server
-- end)

--Отправляем выбранный слот
ServerPipe:add_middleware(function(server)
    if CLIENT_PLAYER.changed_flags.slot then
        server:push_packet(protocol.ClientMsg.PlayerHandSlot, { CLIENT_PLAYER.slot })
        CLIENT_PLAYER.changed_flags.slot = false
    end
    return server
end)

return ServerPipe
