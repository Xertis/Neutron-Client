local protocol = import "net/protocol/protocol"

local tsf = entity.transform
local body = entity.rigidbody

function set_pos(target_pos)
    local current_pos = tsf:get_pos()
    local direction = vec3.sub(target_pos, current_pos)
    local distance = vec3.length(direction)

    if distance > 10 or distance < 0.1 then
        tsf:set_pos(target_pos)
        if body then
            body:set_vel({ 0, 0, 0 })
        end
    elseif body then
        local time_to_reach = 0.1
        local velocity = vec3.mul(vec3.normalize(direction), distance / time_to_reach)
        body:set_vel(velocity)
    end
end

function set_rot(rot_mat)
    tsf:set_rot(rot_mat)
end

function on_attacked(attackerid, playerid)
    if not playerid or playerid == -1 then return end

    SERVER:push_packet(protocol.ClientMsg.EntityInteract, {
        uid = SERVER_UID,
        action = 0
    })
end

function on_used(playerid)
    if not playerid or playerid == -1 then return end

    SERVER:push_packet(protocol.ClientMsg.EntityInteract, {
        uid = SERVER_UID,
        action = 1
    })
end

function on_custom_field_update(field, value)
    local pid = entity:get_player()
    if not pid then return end

    if field == "name" then
        player.set_name(pid, value)
        local player_obj = PLAYER_LIST[pid]
        player_obj.name = value
    elseif field == "rot" then
        player.set_rot(pid, value[1], value[2], value[3])
    elseif field == "hand" then
        local player_obj = PLAYER_LIST[pid]
        player_obj:set_hand_item(value)
    end
end

-- on_render = function(delta)
--     if not is_rotating or not target_rotation then
--         return
--     end

--     rotation_timer = rotation_timer + delta

--     local t = rotation_timer / rotation_duration

--     if t >= 1 then

--         tsf:set_rot(mat4.from_quat(target_rotation))
--         is_rotating = false
--         return
--     end

--     local interpolated = quat.slerp(start_rotation, target_rotation, t)

--     tsf:set_rot(mat4.from_quat(interpolated))
-- end,
