local protocol = require "multiplayer/protocol-kernel/protocol"
local module = {}

local function get_cursor()
    if hud.is_inventory_open() then
        local invid = gui.root["hud.exchange-slot"].inventory
        local slotIndex = gui.root["hud.exchange-slot"].slotIndex

        local item_id, item_count = inventory.get(invid, slotIndex)
        return item_id, item_count, inventory.get_all_data(invid, slotIndex)
    end
end

local id2Invid = {
    [0] = 0,
    [1] = 1
}
local invid2Id = {
    [0] = 0,
    [1] = 1
}

local function open_inventory(invid, id)
    id2Invid[id] = invid
    invid2Id[invid] = id
end

local function close_inventory(invid)
    local id = invid2Id[invid]

    invid2Id[invid] = nil
    id2Invid[id] = nil
end

-- id = айди на сервере
-- invid = айди для клиента
function module.open_block(id, pos)
    local invid = hud.open_block(pos.x, pos.y, pos.z)
    open_inventory(invid, id)
end

function module.open_virtual(layout, disable_player_inventory, root_id, id)
    local invid = hud.open(layout, disable_player_inventory, root_id)
    open_inventory(invid, id)
end

function module.close_inventory_by_invid(invid)
    close_inventory(invid)
end

function module.close_inventory_by_id(id)
    close_inventory(id2Invid[id])
    hud.close_inventory()
end

function module.sync(id, _inventory)
    if id ~= -1 then
        inventory.set_inv(id2Invid[id], _inventory)
    elseif hud.is_player_inventory_open() or hud.is_inventory_open() then
        inventory.set_inv(gui.root["hud.exchange-slot"].inventory, _inventory)
    end
end

local function normalize_item(id, count, meta)
    return {
        id = id or 0,
        count = count or 0,
        meta = (meta and next(meta)) and meta or nil
    }
end

local function checksum(invid)
    local inv = {}
    if invid ~= 0 then
        inv = inventory.get_inv(invid)
    end

    local c_id, c_count, c_meta = get_cursor()

    local cursor = normalize_item(c_id, c_count, c_meta)
    return table.checksum({ inv, cursor })
end

function module.interact(invid, slot, action)
    local item_id = 0

    if invid ~= 0 then
        item_id = inventory.get(invid, slot)
    else
        item_id = get_cursor()
    end

    SERVER:push_packet(protocol.ClientMsg.InventoryInteract, {
        inventory_id = invid2Id[invid],
        slot = slot,
        action = action,
        item_id = item_id,
        checksum = checksum(invid)
    })
end

return module
