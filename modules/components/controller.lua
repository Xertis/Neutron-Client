local tsf = entity.transform
local body = entity.rigidbody

local function set_pos(target_pos)
    local current_pos = tsf:get_pos()
    local direction = vec3.sub(target_pos, current_pos)
    local distance = vec3.length(direction)

    if distance > 10 or distance < 0.01 then
        tsf:set_pos(target_pos)
        if body then
            body:set_vel({0, 0, 0})
        end
    elseif body then
        local time_to_reach = 0.1
        local velocity = vec3.mul(vec3.normalize(direction), distance / time_to_reach)
        body:set_vel(velocity)
    end
end

local function set_rot(rot_mat)
    tsf:set_rot(rot_mat)
end

return {
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

    set_pos = set_pos,
    set_rot = set_rot,
}