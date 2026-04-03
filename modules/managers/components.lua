local module = {}

local components_states = {}

local function get_component_state(uid, component_name)
    return (components_states[uid] or {})[component_name]
end

local function wrap_components(components, entity)
    local uid = entity:get_uid()
    local client_component = entity:get_component("client:controller")

    local unfound_events = {
        on_used = true,
        on_attacked = true
    }

    for component_name, component in pairs(components) do
        module.set_component_state(uid, component_name, true)
        for key, val in pairs(component) do
            if type(val) ~= "function" or component_name == "client:controller" then goto continue end

            if (key ~= "on_used" and key ~= "on_attacked") or not unfound_events[key] then
                component[key] = function(...)
                    if get_component_state(uid, component_name) then
                        val(...)
                    end
                end
            elseif unfound_events[key] then
                unfound_events[key] = nil
                component[key] = function(...)
                    client_component[key](...)
                    if get_component_state(uid, component_name) then
                        val(...)
                    end
                end
            end
            ::continue::
        end
    end
end

function module.set_component_state(uid, component_name, state)
    table.set_default(components_states, uid, {})[component_name] = state
end

function module.clean_component(uid)
    components_states[uid] = nil
end

function module.wrap_components(entity, server_uid)
    local components = entity.components

    local chunk_env = { entity = entity, SERVER_UID = server_uid }
    setmetatable(chunk_env, { __index = PACK_ENV })

    __load_script("client:modules/components/controller.lua", true, chunk_env)

    entity.components["client:controller"] = chunk_env

    wrap_components(components, entity)
end

module.get_component_state = get_component_state

return module
