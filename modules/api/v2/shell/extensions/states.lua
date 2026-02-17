local states = {}
local module = {}

local states_structure = {
    client = {
        username = "",
        identity = ""
    }
}


function module.get_state(...)
    local value = states
    for _, key in ipairs(...) do
        if value[key] ~= nil then
            value = value[key]
        else
            value = nil
            break
        end
    end

    if type(value) == "table" then
        return table.deep_copy(value)
    end

    return value
end

function module.set_state(value, ...)
    local tbl = states
    local len = #{...}

    for id, key in ipairs(...) do
        if tbl[key] then
            tbl = tbl[key]
        elseif id < len then
            tbl[key] = {}
            tbl = tbl[key]
        else
            tbl[key] = value
            return
        end
    end
end

return module