local events = start_require "api/v2/events"
local entities = start_require "api/v2/entities"
local env = start_require "api/v2/env"
local sandbox = require "api/v2/sandbox"
local rpc = require "api/v2/rpc"
local bson = require "lib/files/bson"
local inv_dat = require "api/v2/inv_dat"
local laucnher_api = require "api/v2/launcher/api"

local client_api = {
    events = events,
    rpc = rpc,
    bson = bson,
    env = env,
    entities = entities,
    sandbox = sandbox,
    inventory_data = inv_dat,
}


return {
    client = client_api,
    launcher = laucnher_api
}