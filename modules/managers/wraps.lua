local module = {}

local IDS = {}

function module.show(wrap)
    local pos = {
        wrap.pos.x,
        wrap.pos.y,
        wrap.pos.z
    }
    local id = gfx.blockwraps.wrap(pos, wrap.texture, wrap.emission)

    IDS[wrap.id] = id
end

function module.hide(id)
    if not IDS[id] then return end

    gfx.blockwraps.unwrap(IDS[id])

    IDS[id] = nil
end

function module.set_pos(wrap_id, wrap_pos)
    if not IDS[wrap_id] then return end

    local pos = {
        wrap_pos.x,
        wrap_pos.y,
        wrap_pos.z
    }

    local id = IDS[wrap_id]
    gfx.blockwraps.set_pos(id, pos)
end

function module.set_texture(wrap_id, texture)
    if not IDS[wrap_id] then return end

    local id = IDS[wrap_id]
    gfx.blockwraps.set_texture(id, texture)
end

function module.set_faces(wrap_id, faces)
    if not IDS[wrap_id] then return end

    local id = IDS[wrap_id]
    gfx.blockwraps.set_faces(id, unpack(faces))
end

function module.set_tints(wrap_id, faces)
    if not IDS[wrap_id] then return end

    local id = IDS[wrap_id]
    gfx.blockwraps.set_tints(id, unpack(faces))
end

return module