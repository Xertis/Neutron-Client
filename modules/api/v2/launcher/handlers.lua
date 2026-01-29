local module = {call = {}}
local handlers = {}

local meta = {
    __index = function(table, key)
        return handlers[key]
    end
}

setmetatable(module.call, meta)

function module.set_handlers(_handlers)
    table.merge(handlers, _handlers)
end

return module