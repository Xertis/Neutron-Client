function on_hud_open()
    hud.set_allow_pause(false)
end

function on_hud_render()
    events.emit("client:hud_render")
end