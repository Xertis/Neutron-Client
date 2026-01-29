local connections = require "api/v2/laucher/connections"
local packs = require "api/v2/launcher/packs"
local handlers = require "api/v2/launcher/handlers"

local data = start_require "api/v2/launcher/data"

local api = {
    internal = {
        connections = connections,
        packs = packs,
        handlers = handlers
    },
    extensions = {
        data = data
    }
}


local function parse_path(path)
    local index = string.find(path, ':')
    if index == nil then
        error("invalid path syntax (':' missing)")
    end
    return string.sub(path, 1, index-1), string.sub(path, index+1, -1)
end

local meta = {
    __index = function(table, key)
        local prefix = parse_path(debug.getinfo(2, 'S').source)
        if prefix == "client" or prefix == LAUNCHER_PACK then
            return api[key]
        end

        return error("Only the launcher has access to this system. To gain access to internal systems, you must register the pack as a launcher")
    end
}

function api.extensions.register_as_launcher(app, after_init)
    if LAUNCHER_PACK then
        error("The launcher is already registered")
    end

    local prefix = parse_path(debug.getinfo(2, 'S').source)
    LAUNCHER_PACK = prefix
    require "init/client"(app, after_init)
end

local wrap_api = {
    extensions = api.extensions
}

setmetatable(wrap_api, meta)

return api