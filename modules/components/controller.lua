local protocol = import "net/protocol/protocol"


local tsf = entity.transform
local body = entity.rigidbody
local rig = entity.skeleton

local target_pos = nil
local SMOOTH = 12

local bone_transitions = {}
local rot_transition = nil

local function mat4_lerp(a, b, t)
    local da = mat4.decompose(a)
    local db = mat4.decompose(b)
    if not da or not db then return b end
    local pos   = vec3.lerp(da.translation, db.translation, t)
    local scale = vec3.lerp(da.scale, db.scale, t)
    local rot   = quat.slerp(da.quaternion, db.quaternion, t)
    local m     = mat4.from_quat(rot)
    m           = mat4.scale(m, scale)
    m           = mat4.translate(m, pos)
    return m
end

function set_pos(pos)
    local current = tsf:get_pos()
    local dist = vec3.length(vec3.sub(pos, current))
    if dist > 10 or dist < 0.01 then
        tsf:set_pos(pos)
        if body then body:set_vel({ 0, 0, 0 }) end
        target_pos = nil
    else
        target_pos = pos
    end
end

function set_rot(rot_mat)
    local current = tsf:get_rot()
    rot_transition = {
        from  = current,
        to    = rot_mat,
        t     = 0,
        speed = 8
    }
end

function set_transform_matrix(key, val)
    local current = rig:get_matrix(key) or val
    bone_transitions[key] = {
        from  = current,
        to    = val,
        t     = 0,
        speed = 8
    }
end

function on_render(delta)
    if rot_transition then
        local tr = rot_transition
        tr.t = tr.t + delta * tr.speed
        local t = math.min(tr.t, 1.0)
        tsf:set_rot(mat4_lerp(tr.from, tr.to, t))
        if t >= 1.0 then
            rot_transition = nil
        end
    end

    for key, tr in pairs(bone_transitions) do
        tr.t = tr.t + delta * tr.speed
        local t = math.min(tr.t, 1.0)
        local m = mat4_lerp(tr.from, tr.to, t)
        rig:set_matrix(key, m)
        if t >= 1.0 then
            bone_transitions[key] = nil
        end
    end

    if target_pos and body then
        local current = tsf:get_pos()
        local diff    = vec3.sub(target_pos, current)
        local dist    = vec3.length(diff)
        if dist < 0.01 then
            tsf:set_pos(target_pos)
            body:set_vel({ 0, 0, 0 })
            target_pos = nil
        else
            body:set_vel(vec3.mul(diff, SMOOTH))
        end
    end
end

function on_attacked(attackerid, playerid)
    if not playerid or playerid == -1 then return end
    SERVER:push_packet(protocol.ClientMsg.EntityInteract, {
        uid = SERVER_UID, action = 0
    })
end

function on_used(playerid)
    if not playerid or playerid == -1 then return end
    SERVER:push_packet(protocol.ClientMsg.EntityInteract, {
        uid = SERVER_UID, action = 1
    })
end
