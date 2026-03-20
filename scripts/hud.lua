local inventory_manager = nil

function on_hud_open()
    PACK_ENV["hud"] = table.deep_copy(_G["hud"])
    _G["hud"].open = function() end
    _G["hud"].open_block = function() end
    hud.set_allow_pause(false)
    inventory_manager = import "managers/inventory"
end

function on_hud_render()
    events.emit("client:hud_render")
end

function on_inventory_interact(...)
    inventory_manager.interact(...)
end
