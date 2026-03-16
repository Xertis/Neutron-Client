local protocol = require "multiplayer/protocol-kernel/protocol"
local buffer = protocol.create_databuffer()
local module = {}


local function block_in_region(x, y, z)
    if not x or not y or not z then
        return false
    end

    local abs_x = x - CLIENT_PLAYER.region.x * 32
    local abs_z = z - CLIENT_PLAYER.region.z * 32

    if abs_x < -127 or abs_x > 127 or abs_z < -127 or abs_z > 127 then
        return false
    end

    return true
end

function module.get_bytes()
    return buffer.bytes
end

function module.reset_buffer()
    buffer = protocol.create_databuffer()
end

function module.on_placed(blockid, x, y, z, states)
    if not block_in_region(x, y, z) then
        buffer:put_bytes(protocol.build_packet("client", protocol.ClientMsg.BlockUpdate, {
            block = {
                pos = { x = x, y = y, z = z },
                state = states,
                id = blockid
            }
        }))
    else
        local abs_x = x - CLIENT_PLAYER.region.x * 32
        local abs_z = z - CLIENT_PLAYER.region.z * 32
        buffer:put_bytes(protocol.build_packet("client", protocol.ClientMsg.BlockRegionUpdate, {
            block = {
                pos = { x = abs_x, y = y, z = abs_z },
                state = states,
                id = blockid
            }
        }))
    end
end

function module.on_broken(blockid, x, y, z)
    if not block_in_region(x, y, z) then
        buffer:put_bytes(protocol.build_packet(
            "client",
            protocol.ClientMsg.BlockDestroy,
            {
                pos = { x = x, y = y, z = z },
            }
        ))
    else
        local abs_x = x - CLIENT_PLAYER.region.x * 32
        local abs_z = z - CLIENT_PLAYER.region.z * 32
        buffer:put_bytes(protocol.build_packet(
            "client",
            protocol.ClientMsg.BlockRegionDestroy,
            {
                pos = { x = abs_x, y = y, z = abs_z },
            }
        ))
    end
end

function module.on_interact(blockid, x, y, z)
    if not block_in_region(x, y, z) then
        buffer:put_bytes(protocol.build_packet(
            "client",
            protocol.ClientMsg.BlockInteract,
            {
                pos = { x = x, y = y, z = z },
            }
        ))
    else
        local abs_x = x - CLIENT_PLAYER.region.x * 32
        local abs_z = z - CLIENT_PLAYER.region.z * 32
        buffer:put_bytes(protocol.build_packet(
            "client",
            protocol.ClientMsg.BlockRegionInteract,
            {
                pos = { x = abs_x, y = y, z = abs_z },
            }
        ))
    end
end

return module
