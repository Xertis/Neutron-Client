-- Инициализируем stdmin
require "quartz:std/stdmin"

initializator = {}

local default_config = {
    Account = {
        name = "Test",
        friends = {}
    },
    Servers = {
    },
    Pinned_packs = {
    }
}

-- Инициализируем конфиг

if not file.exists(CONFIG_PATH) then
    file.write(CONFIG_PATH, json.tostring(default_config))
end

CONFIG = table.merge(json.parse(file.read(CONFIG_PATH)), default_config)

-- Инициализацация паков
function initializator.init_packs()
    table.filter(CONTENT_PACKS, function ()
        return false
    end)

    external_app.reset_content()
    table.insert(CONTENT_PACKS, PACK_ID)

    for _, pack in ipairs(pack.get_available()) do
        if table.has(CONFIG.Pinned_packs, pack) then
            table.insert_unique(CONTENT_PACKS, pack)
        end
    end

    external_app.config_packs(CONTENT_PACKS)
    external_app.load_content()
end

-- Инициализация скриптов
function initializator.init_pack_scripts()
    local paths = file.list_all_res("scripts/client/")

    for _, path in ipairs(paths) do
        if file.name(path) == "main.lua" then
            __load_script(path)
        end
    end
end

initializator.init_packs()
initializator.init_pack_scripts()