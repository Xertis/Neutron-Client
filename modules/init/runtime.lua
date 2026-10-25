local packs = import "api/v2/shell/internal/packs"

local STORE = "neutron-runtime"

local module = {}

local function link_env()
    session.reset("neutron-client-env")
    setmetatable(session.get("neutron-client-env"), {
        __index = PACK_ENV,
        __newindex = function(_, key, value)
            rawset(PACK_ENV, key, value)
        end
    })
end

function module.attach()
    local state = session.get(STORE)

    _G["external_app"] = state.external_app

    for _, id in ipairs(packs.get_shell_packs()) do
        table.insert_unique(CONTENT_PACKS, id)
    end

    local Client = import "client:net/classes/client"
    local client = Client.new()

    link_env()

    state.tick = function()
        client:tick()
    end
end

function module.tick()
    session.get(STORE).tick()
end

return module
