local module = {}

function module.insert_pack(pack)
    table.insert_unique(CONTENT_PACKS, pack)
end

function module.remove_pack(pack)
    table.remove_value(CONTENT_PACKS, pack)
end

function module.set_packs(packs)
    CONTENT_PACKS = packs
end

function module.reset_packs()
    CONTENT_PACKS = {"client", SHELL.prefix}
end

function module.get_packs()
    return table.copy(CONTENT_PACKS)
end

function module.init_scripts()
    local paths = file.list_all_res("scripts/client/")

    for _, path in ipairs(paths) do
        if file.name(path) == "main.lua" then
            __load_script(path)
        end
    end
end

function module.reload_packs(use_core)
    external_app.reset_content()
    external_app.config_packs(CONTENT_PACKS)

    if not use_core then external_app.load_content()
    else external_app.load_content() end
end

return module