local protocol = import "net/protocol/protocol"
local components_manager = import "managers/components"
local Player = import "net/classes/player"

local entities_uids = {}
local handlers = {}
local desynced_entities = {}

local self = Module()
local shared = self.shared
local single = self.single
local remote = self.remote

local PLAYER_ENTITY_ID = nil

local function vec_zero()
    return { 0, 0, 0 }
end

local original_spawn = entities.spawn

entities.spawn = function(name, ...)
    local source_path = debug.getinfo(2, "S").source
    local prefix = parse_path(source_path) or ""

    if desynced_entities[name] or prefix:find(PACK_ID) then
        return original_spawn(name, ...)
    end

    local entity = original_spawn(name, ...)
    entity:despawn()

    SERVER:push_packet(protocol.ClientMsg.EntitySpawnAttempt, { def = entity:def_index(), args = { ... } })

    return entity
end

function shared.desync(name)
    desynced_entities[name] = true
end

function shared.sync(name)
    desynced_entities[name] = nil
end

function shared.set_handler(triggers, handler)
    for _, trigger in ipairs(triggers) do
        handlers[trigger] = handler
    end
end

function shared.__despawn__(uid)
    local cuid = entities_uids[uid]
    if not cuid then return end

    entities_uids[uid] = nil
    local entity = entities.get(cuid)
    if entity then
        local pid = entity:get_player()
        if not pid or pid == -1 then
            entity:despawn()
        else
            local player = PLAYER_LIST[pid]
            player:despawn()
            PLAYER_LIST[pid] = nil
        end
    end

    components_manager.clean_component(cuid)
end

local function call_component(entity, fields)
    for _, comp in pairs(entity.components) do
        if comp.on_custom_field_update then
            for field_key, field_value in pairs(fields) do
                comp.on_custom_field_update(field_key, field_value)
            end
        end
    end
end

function remote.__update(cuid, def, dirty)
    local std_fields = dirty.standard_fields or {}
    local entity = entities.get(cuid)
    if not entity then return end

    call_component(entity, dirty.custom_fields or {})

    if handlers[def] then
        handlers[def](cuid, def, dirty.custom_fields or {})
    end

    if dirty.components then
        for comp_name, enabled in pairs(dirty.components) do
            components_manager.set_component_state(cuid, comp_name, enabled)
        end
    end

    local skeleton = entity.skeleton

    if skeleton then
        for key, val in pairs(dirty.textures or {}) do
            skeleton:set_texture(key, val)
        end
        for key, val in pairs(dirty.models or {}) do
            skeleton:set_model(tonumber(key), val)
        end
        for key, val in pairs(dirty.matrix or {}) do
            skeleton:set_matrix(tonumber(key), val)
        end
    end


    local transform = entity.transform
    local rigidbody = entity.rigidbody

    local controller = nil
    if entity:has_component("client:controller") then
        controller = entity:require_component("client:controller")
    end

    if std_fields.tsf_pos and controller then controller.set_pos(std_fields.tsf_pos) end
    if std_fields.tsf_rot and controller then controller.set_rot(std_fields.tsf_rot) end

    if std_fields.tsf_size then transform:set_size(std_fields.tsf_size) end
    if std_fields.body_size then rigidbody:set_size(std_fields.body_size) end
    if std_fields.body_material then rigidbody:set_material(std_fields.body_material) end
    if std_fields.body_mass then rigidbody:set_mass(std_fields.body_mass) end
    if std_fields.body_elastic then rigidbody:set_elasticity(std_fields.body_elastic) end
end

function single.__update(cuid, def, dirty)
    local entity = entities.get(cuid)
    if not entity then return end

    call_component(entity, dirty.custom_fields or {})

    if handlers[def] then
        handlers[def](cuid, def, dirty.custom_fields or {})
    end
end

function shared.__get_uids__()
    return entities_uids
end

function shared.__emit__(uid, def, dirty)
    if not PLAYER_ENTITY_ID then
        local player_entity = entities.get(player.get_entity(hud.get_player()))
        PLAYER_ENTITY_ID = player_entity:def_index()
    end

    local std_fields = dirty.standard_fields or {}
    local custom_fields = dirty.custom_fields or {}

    if not entities_uids[uid] then
        local entity_name = entities.def_name(def)
        local new_entity = nil
        if def ~= PLAYER_ENTITY_ID then
            new_entity = original_spawn(entity_name, std_fields.tsf_pos or vec_zero())
            entities_uids[uid] = new_entity:get_uid()
            if new_entity.rigidbody then
                new_entity.rigidbody:set_gravity_scale(vec_zero())
            end
            components_manager.wrap_components(new_entity, uid)
            self.__update(entities_uids[uid], def, dirty)
        else
            player.create(custom_fields.name, custom_fields.pid)
            player.set_loading_chunks(custom_fields.pid, false)
            PLAYER_LIST[custom_fields.pid] = Player.new(custom_fields.pid, custom_fields.name)
            external_app.tick()

            local player_entity = entities.get(player.get_entity(custom_fields.pid))
            entities_uids[uid] = player_entity:get_uid()
            player.set_flight(custom_fields.pid, true)
            player.set_noclip(custom_fields.pid, true)
            if player_entity.rigidbody then
                player_entity.rigidbody:set_gravity_scale(vec_zero())
            end
            components_manager.wrap_components(player_entity, uid)
            self.__update(entities_uids[uid], def, dirty)
        end
        return
    end
    local cuid = entities_uids[uid]
    self.__update(cuid, def, dirty)
end

return self:build()
