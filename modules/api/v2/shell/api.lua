require "init/requires"
local packs = import "api/v2/shell/internal/packs"
local sandbox = import "api/v2/shell/extensions/sandbox"
local runtime = import "init/runtime"

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
        if prefix == "client" or prefix == SHELL.prefix or SHELL.trusted[prefix] then
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

local function bind_shell(shell)
    SHELL = shell
    init_connections()
    api.extensions = table.merge(api.extensions, shell.module)
end

function api.register_as_shell(module)
    if SHELL then
        error("The shell is already registered")
    end
    local prefix = parse_path(debug.getinfo(2, 'S').source)
    local shell = {
        trusted = {},
        prefix = prefix,
        module = module,
    }

    session.get("neutron-runtime").shell = shell

    bind_shell(shell)
    logger.log("The shell was registered")
    return {
        api_version = API_VERSION,
        protocol_version = PROTOCOL_VERSION
    }
end

function internal.add_trusted_pack(prefix)
    SHELL.trusted[prefix] = true
end

function internal.run(app)
    import "init/client" (app)
end

setmetatable(api.internal, meta)

do
    local saved = session.get("neutron-runtime").shell
    if saved and not SHELL then
        bind_shell(saved)
        runtime.attach()
        logger.log("The shell was restored")
    end
end

return api
