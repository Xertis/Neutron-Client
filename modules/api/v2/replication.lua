local messages = import "api/v2/messages"

local Replication = {}

local REPLICATORS = {}

local function has_null(schema)
    for key, typ in pairs(schema) do
        if type(typ) == "string" then
            if typ:find("NullAble<") then return true end
        else
            if has_null(typ) then
                return true
            end
        end
    end
    return false
end

local function nullabling(schema)
    local nullable = {}
    for key, typ in pairs(schema) do
        if type(typ) == "string" then
            nullable[key] = "NullAble<" .. typ .. ">"
        else
            nullable[key] = nullabling(typ)
        end
    end
    return nullable
end

local function sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

local function compile_schema(schema)
    local entries = {}
    for _, key in ipairs(sorted_keys(schema)) do
        local typ = schema[key]
        if type(typ) == "table" then
            table.insert(entries, { key = key, nested = compile_schema(typ) })
        else
            table.insert(entries, { key = key, type = typ })
        end
    end
    return entries
end

local function diff(compiled, new, old)
    local result = nil
    for i = 1, #compiled do
        local f = compiled[i]
        local k = f.key

        if f.nested then
            local sub = diff(f.nested, new[k], old[k])
            if sub then
                result = result or {}
                result[k] = sub
            end
        else
            local nv = new[k]
            if nv ~= old[k] then
                result = result or {}
                result[k] = nv
            end
        end
    end
    return result
end

local function apply_diff(compiled, target, patch)
    if not patch then return target end
    for i = 1, #compiled do
        local f = compiled[i]
        local k = f.key
        local p = patch[k]

        if p ~= nil then
            if f.nested then
                apply_diff(f.nested, target[k], p)
            else
                target[k] = p
            end
        end
    end
    return target
end

local Replicator = {}
Replicator.__index = Replicator

function Replication.new(pack, event, schema)
    if has_null(schema) then
        error("Replication схема не может иметь NullAble тип")
    end

    schema = nullabling(schema)

    local compiled_schema = compile_schema(schema)
    schema._rep_id = "var"

    local message = messages.new(pack, event, schema)
    local replicator_id = #REPLICATORS + 1

    local self = setmetatable({
        _listeners = {},
        _id = replicator_id
    }, Replicator)

    REPLICATORS[replicator_id] = self

    message:on(function(dirty)
        local id = dirty._rep_id
        local listener = self._listeners[id]
        if not listener then
            logger.log(string.format("A table has been received from a non-existent listener '%s'", id), "W")
            return
        end

        if listener._on_recv then
            if not listener._on_recv(dirty) then
                return
            end
        end

        apply_diff(compiled_schema, listener, dirty)
    end)

    return self
end

function Replicator:create_listener(id, initial_value, on_recv)
    self._listeners[id] = {
        _on_recv = on_recv
    }
    table.merge(self._listeners[id], table.deep_copy(initial_value))
    return self._listeners[id]
end

function Replicator:remove_replica(id)
    if self._listeners[id] then
        self._listeners[id] = nil
    end
end

return Replication
