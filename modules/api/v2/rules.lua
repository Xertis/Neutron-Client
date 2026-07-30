local engine_create = rules.create
local engine_get = rules.get

local rules = {}

local Rule = {}
Rule.__index = Rule

local registered = {}

local function ensure_name(name)
    if type(name) ~= "string" or name == "" then
        error("rule name must be a non-empty string")
    end
end

function Rule.new(name, default)
    ensure_name(name)

    if registered[name] then
        error(string.format("A rule named '%s' has already been defined", name))
    end

    local self = setmetatable({}, Rule)

    self.name = name
    self.default = default
    self.next_listener_id = 0
    self.listeners = {}

    engine_create(name, default, function(value)
        self:process(value)
    end)

    registered[name] = self

    return self
end

function Rule:listen(listener)
    local id = tohex(self.next_listener_id)
    self.listeners[id] = listener
    self.next_listener_id = self.next_listener_id + 1
    return id
end

function Rule:unlisten(id)
    self.listeners[id] = nil
end

function Rule:process(value)
    for _, listener in pairs(self.listeners) do
        listener(value)
    end
end

function rules.define(name, properties)
    properties = properties or {}
    return Rule.new(name, properties.default)
end

function rules.define_if_absent(name, properties)
    ensure_name(name)
    return registered[name] or rules.define(name, properties)
end

function rules.is_defined(name)
    ensure_name(name)
    return registered[name] ~= nil
end

function rules.get_rule(name)
    ensure_name(name)
    return registered[name]
end

function rules.get_value(rule)
    return engine_get(rule.name)
end

local STANDARD_RULES = {
    "allow-cheats",
    "allow-content-access",
    "allow-flight",
    "allow-noclip",
    "allow-attack",
    "allow-destroy",
    "allow-cheat-movement",
    "allow-debug-cheats",
    "allow-fast-interaction",
}

for _, name in ipairs(STANDARD_RULES) do
    rules.define_if_absent(name, engine_get(name))
end

return rules
