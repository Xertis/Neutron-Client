local module = {}

local TEXTS_IDS = {}

function module.show(text)
    local id = gfx.text3d.show(
        text.position,
        text.text,
        text.preset,
        text.extension
    )
    TEXTS_IDS[text.id] = id

    if text.axisX then
        gfx.text3d.set_axis_x(id, text.axisX)
    end
    if text.axisY then
        gfx.text3d.set_axis_y(id, text.axisY)
    end
    if text.rotation then
        gfx.text3d.set_rotation(id, text.rotation)
    end
end

function module.apply(text)
    if not text or not TEXTS_IDS[text.id] then
        return
    end

    local id = TEXTS_IDS[text.id]

    if text.text then
        gfx.text3d.set_text(id, text.text)
    end
    if text.position then
        gfx.text3d.set_pos(id, text.position)
    end
    if text.rotation then
        gfx.text3d.set_rotation(id, text.rotation)
    end
    if text.preset then
        gfx.text3d.update_settings(id, text.preset)
    end
    if text.axisX then
        gfx.text3d.set_axis_x(id, text.axisX)
    end
    if text.axisY then
        gfx.text3d.set_axis_y(id, text.axisY)
    end
end

function module.hide(id)
    if not TEXTS_IDS[id] then
        return
    end

    gfx.text3d.hide(TEXTS_IDS[id])
end

return module