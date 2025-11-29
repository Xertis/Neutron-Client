app.config_packs({ "quartz" })
app.load_content()

gui_util.add_page_dispatcher(function(name, args)
    if name == "pause" then
        name = "quartz_pause"
    end

    return name, args
end)

_G["leave_to_menu"] = function (reason)
    local world_is_open = world.is_open()
    if world_is_open then
        app.close_world(false)
    end

    if world_is_open or menu.page == "quartz_connection" then
        initializator.init_packs()
        menu.page = "quartz_connection"
        local document = Document.new("quartz:pages/quartz_connection")
        document.info.text = reason or "Unexpected disconnection"
    end
end

local protect_app = {}

for key, val in pairs(app) do
    protect_app[key] = function (...)
        if parse_path(debug.getinfo(2).source) == "quartz" then
            return val(...)
        end
    end
end

protect_app.reset_content = function ()
    app.reset_content({"quartz"})
end

_G["external_app"] = protect_app

-- _G["leave_to_menu"] = function (reason)
--     if world.is_open() then
--         app.close_world(false)
--     end

--     app.reset_content()
--     menu:reset()
--     app.config_packs({PACK_ID})
--     app.load_content()
--     menu.page = "quartz_connection"

--     local document = Document.new("quartz:pages/quartz_connection")
--     document.info.text = reason or "@menu.Unexpect_Disconnected"
-- end

require "quartz:init/quartz"
