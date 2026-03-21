require "init/requires"
local packs = import "api/v2/shell/internal/packs"
local sandbox = import "api/v2/shell/extensions/sandbox"

local internal = {
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
    return string.sub(path, 1, index - 1), string.sub(path, index + 1, -1)
end

local meta = {
    __index = function(table, key)
        local prefix = parse_path(debug.getinfo(2, 'S').source)
        if prefix == "client" or prefix == SHELL.prefix then
            return internal[key]
        end
        return error(
            "Only the shell has access to this system. To gain access to internal systems, you must register the pack as a shell")
    end
}

local function init_connections()
    if not internal.connections then
        internal.connections = import "api/v2/shell/internal/connections"
    end
end

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
    init_connections()
    api.extensions = table.merge(module.extensions or {}, api.extensions)
    return {
        api_version = API_VERSION,
        protocol_version = PROTOCOL_VERSION
    }
end

function api.__run_in_single(port)
    local shell_module = import "init/single" ()
    SHELL = {
        prefix = "client",
        config = {},
        module = shell_module
    }
    init_connections()
    api.extensions = {}
    internal.connections.join("localhost:" .. port, 1, "player", "player", function() end, function() end)
end

function internal.run(app)
    import "init/client" (app)
end

setmetatable(api.internal, meta)
return api
