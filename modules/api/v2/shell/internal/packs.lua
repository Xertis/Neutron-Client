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

function module.get_shell_packs()
    local all = table.unique(table.merge(pack.get_available(), pack.get_installed()))
    local result = {}

    if table.has(all, SHELL.prefix) then
        table.insert_unique(result, SHELL.prefix)
    end

    for id in pairs(SHELL.trusted) do
        if table.has(all, id) then
            table.insert_unique(result, id)
        end
    end

    return result
end

function module.reset_packs()
    CONTENT_PACKS = { "client" }
    for _, id in ipairs(module.get_shell_packs()) do
        table.insert_unique(CONTENT_PACKS, id)
    end
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
