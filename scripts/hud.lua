function on_hud_open()
    PACK_ENV["hud"] = table.deep_copy(_G["hud"])
    _G["hud"].open = function() end
    _G["hud"].open_block = function() end
    hud.set_allow_pause(false)
end

function on_hud_render()
    events.emit("client:hud_render")
end
