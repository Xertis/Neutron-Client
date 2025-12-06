local Player = {}
local max_id = 0
Player.__index = Player

local function is_chunk_loaded(x, z)
    local check_x = math.floor(x)
    local check_y = 60
    local check_z = math.floor(z)

    return block.get(check_x, check_y, check_z) ~= -1
end

function Player.new(pid, name, pos, rot, cheats)
    local self = setmetatable({}, Player)

    self.pid = pid
    self.name = name
    self.invid = player.get_inventory(pid)
    self.inv = {}
    self.slot = 0
    self.region = {x = 0, z = 0}
    self.pos = pos or {x = 0, y = -10, z = 0}
    self.rot = rot or {yaw = 0, pitch = 0}
    self.cheats = cheats or {noclip = false, flight = false}
    self.active = true
    self.hand_item = 0
    self.ping = {
        ping = -1,
        last_upd = 0
    }

    self.id = max_id
    self.is_loaded = false
    self.pending_updates = {}

    self.changed_flags = {
        pos = false,
        rot = false,
        cheats = false,
        inv = false,
        slot = false,
        region = false
    }

    max_id = max_id + 1

    return self
end

function Player:is_chunk_loaded()
    return is_chunk_loaded(self.pos.x, self.pos.z)
end

function Player:apply_pending_updates()
    if self.pending_updates.pos then
        local pos = self.pending_updates.pos
        player.set_pos_interpolated(self.pid, pos.x, pos.y, pos.z, CLIENT_PLAYER.pid == self.pid)
        player.set_spawnpoint(self.pid, pos.x, math.abs(pos.y), pos.z)
        self.pending_updates.pos = nil
        self.changed_flags.pos = true
        self.changed_flags.region = true
    end

    if self.pending_updates.rot then
        local rot = self.pending_updates.rot
        player.set_rot(self.pid, rot.yaw, rot.pitch, 0)
        self.pending_updates.rot = nil
        self.changed_flags.rot = true
    end

    if self.pending_updates.cheats then
        local cheats = self.pending_updates.cheats
        player.set_flight(self.pid, cheats.flight)
        player.set_noclip(self.pid, cheats.noclip)
        self.pending_updates.cheats = nil
        self.changed_flags.cheats = true
    end
end

function Player:set_pos(pos, set_flag)
    if pos == nil then return end

    local cur_loaded = self:is_chunk_loaded()

    self.pos = {x = pos.x, y = pos.y, z = pos.z}

    self.region = {
        x = math.floor(pos.x / 32),
        z = math.floor(pos.z / 32)
    }

    if set_flag then
        self.changed_flags.region = true
    end

    if cur_loaded then
        local no_interpolated = CLIENT_PLAYER.pid == self.pid
        player.set_pos_interpolated(self.pid, pos.x, pos.y, pos.z, no_interpolated)
        player.set_spawnpoint(self.pid, pos.x, math.abs(pos.y), pos.z)
        if set_flag then self.changed_flags.pos = true end
        self.pending_updates.pos = nil
    else
        self.pending_updates.pos = pos
    end
end

function Player:set_rot(rot, set_flag)
    if rot == nil then return end

    self.rot = {yaw = rot.yaw, pitch = rot.pitch}

    if self:is_chunk_loaded() then
        player.set_rot(self.pid, rot.yaw, rot.pitch, 0)
        if set_flag then self.changed_flags.rot = true end
        self.pending_updates.rot = nil
    else
        self.pending_updates.rot = rot
    end
end

function Player:set_cheats(cheats, set_flag)
    if cheats == nil then return end

    if CLIENT_PLAYER.pid ~= self.pid then
        if self.cheats.noclip == false then
            cheats = {noclip = true, flight = true}

        end
    end

    self.cheats = {noclip = cheats.noclip, flight = cheats.flight}

    if self:is_chunk_loaded() then

        player.set_flight(self.pid, cheats.flight)
        player.set_noclip(self.pid, cheats.noclip)
        if set_flag then self.changed_flags.cheats = true end
        self.pending_updates.cheats = nil
    else
        self.pending_updates.cheats = cheats
    end
end

function Player:set_inventory(inv, set_flag)
    if inv == nil then return end
    self.inv = inv
    inventory.set_inv(self.invid, inv)

    if set_flag then self.changed_flags.inv = true end
end

function Player:set_slot(slot_id, set_flag)
    if slot_id == nil then return end
    self.slot = slot_id
    player.set_selected_slot(self.pid, slot_id)

    if set_flag then self.changed_flags.slot = true end
end

function Player:set_hand_item(hand_item)
    if not hand_item then return end
    local invid, slot = player.get_inventory(self.pid)

    inventory.set(invid, slot, hand_item, 1)
end


function Player:tick()
    local cur_loaded = self:is_chunk_loaded()
    if cur_loaded and not self.is_loaded then
        self:apply_pending_updates()
    end

    self.is_loaded = cur_loaded

    if self.is_loaded then
        self:__check_pos()
        self:__check_rot()
        self:__check_cheats()
    end

    self:__check_inv()
    self:__check_slot()
end

function Player:is_active()
    return self.active
end

function Player:__check_pos()
    if not CACHED_DATA.over then
        return
    end

    local x, y, z = player.get_pos(self.pid)
    if math.euclidian3D(self.pos.x, self.pos.y, self.pos.z, x, y, z) > 0.05 then
        self.pos = {x = x, y = y, z = z}
        self.changed_flags.pos = true
    end

    local cur_region_x = math.floor(x / 32)
    local cur_region_z = math.floor(z / 32)

    if self.region.x ~= cur_region_x or self.region.z ~= cur_region_z then
        self.region = {x = cur_region_x, z = cur_region_z}
        self.changed_flags.region = true
    end
end

function Player:__check_rot()
    local yaw, pitch = player.get_rot(self.pid)

    if self.rot.yaw ~= yaw or self.rot.pitch ~= pitch then
        self.rot = {yaw = yaw, pitch = pitch}
        self.changed_flags.rot = true
    end
end

function Player:__check_cheats()
    local noclip, flight = player.is_noclip(self.pid), player.is_flight(self.pid)

    if self.cheats.noclip ~= noclip or self.cheats.flight ~= flight then
        self.cheats = {noclip = noclip, flight = flight}
        self.changed_flags.cheats = true
    end
end

function Player:__check_inv()
    local cur_inv = inventory.get_inv(self.invid)
    if not table.deep_equals(self.inv, cur_inv) then
        self.inv = cur_inv
        self.changed_flags.inv = true
    end
end

function Player:__check_slot()
    local _, cur_slot = player.get_inventory(self.pid)
    if self.slot ~= cur_slot then
        self.slot = cur_slot
        self.changed_flags.slot = true
    end
end

function Player:despawn()
    player.delete(self.pid)
    self.active = false
end

return Player