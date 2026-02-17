require "client:init/requires"
local connections = require "api/v2/shell/internal/connections"
local packs = require "api/v2/shell/internal/packs"

local sandbox = require "api/v2/shell/extensions/sandbox"

local internal = {
    connections = connections,
    packs = packs
}

local api = {
    internal = {},
    extensions = {
        sandbox = sandbox
    },
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
        if prefix == "client" or prefix == SHELL.prefix then
            return internal[key]
        end

        return error("Only the shell has access to this system. To gain access to internal systems, you must register the pack as a shell")
    end
}

function api.register_as_shell(config, module)
    if SHELL then
        error("The shell is already registered")
    end

    local prefix = parse_path(debug.getinfo(2, 'S').source)
    SHELL = {
        prefix = prefix,
        config = config,
        module = module,

    }

    api.extensions = table.merge(module.extensions or {}, api.extensions)

    return {
        api_version = API_VERSION,
        protocol_version = PROTOCOL_VERSION
    }
end

function internal.run(app)
    require "init/client"(app)
end

setmetatable(api.internal, meta)

return api