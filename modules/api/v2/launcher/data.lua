local module = {}

local IDENTITY_SETTER = function (name) end

function module.set_identity(setter)
    IDENTITY_SETTER = setter
end

function module.get_identity(username)
    return IDENTITY_SETTER(username)
end

return module