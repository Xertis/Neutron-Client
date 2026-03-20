local events = import "api/v1/events"
local entities = import "api/v1/entities"
local env = import "api/v1/env"
local rpc = import "api/v1/rpc"
local bson = import "lib/data/bson"
local inv_dat = import "api/v1/inv_dat"

local api = {
    events = events,
    rpc = rpc,
    bson = bson,
    env = env,
    entities = entities,
    inventory_data = inv_dat,
}

return { client = api }
