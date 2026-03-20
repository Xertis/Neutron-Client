local shell_api = require "api/v2/shell/api"
local events = import "api/v2/events"
local entities = import "api/v2/entities"
local env = import "api/v2/env"
local rpc = import "api/v2/rpc"
local bson = import "lib/data/bson"
local inv_dat = import "api/v2/inv_dat"

local client_api = {
    events = events,
    rpc = rpc,
    bson = bson,
    env = env,
    entities = entities,
    inventory_data = inv_dat,
}


return {
    client = client_api,
    shell = shell_api
}
