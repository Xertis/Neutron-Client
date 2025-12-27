local protocol = start_require "multiplayer/protocol-kernel/protocol"

local module = {
    blocks = {}
}

function module.blocks.sync_inventory(pos)
    local invid = inventory.get_block(pos.x, pos.y, pos.z)
    local inv = inventory.get_inv(invid)

    SERVER:push_packet(protocol.ClientMsg.BlockInventory, {
        pos = {x = pos.x, y = pos.y, z = pos.z},
        inventory = inv
    })
end

function module.blocks.sync_slot(pos, slot)
    SERVER:push_packet(protocol.ClientMsg.BlockInventorySlot, {
        pos = {x = pos.x, y = pos.y, z = pos.z},
        slot_id = slot.slot_id,
        item_id = slot.item_id,
        item_count = slot.item_count
    })
end

return module