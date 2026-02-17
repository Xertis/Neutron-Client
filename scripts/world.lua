local Player = require "multiplayer/classes/player"

local protocol = nil
local sandbox = nil
local utils = nil

local buffer = {}
local loaded_chunks = {}

local CACHED_DATA = nil
local SERVER = nil
local CLIENT_PLAYER = nil
local CHUNK_LOADING_DISTANCE = nil

function on_world_open()
    protocol = require "multiplayer/protocol-kernel/protocol"
    sandbox = start_require "multiplayer/client/sandbox"
    utils = require "lib/utils"

    require "init/cmd"
    -------------------------
    local env = session.get_entry("neutron-client-env")
    CACHED_DATA = env.CACHED_DATA
    SERVER = env.SERVER
    CHUNK_LOADING_DISTANCE = env.CHUNK_LOADING_DISTANCE

    CLIENT_PLAYER = Player.new(env.CLIENT_PID, env.SHELL.module.states.get_username())

    env.CLIENT_PLAYER = CLIENT_PLAYER
    env.SHELL.module.handlers.game.join(SERVER, CLIENT_PLAYER)
end

function on_chunk_present(x, z)
    if #buffer < (external_app.get_setting("chunks.load-distance") ^ 2) / 2 then
        if not loaded_chunks[x .. '/' .. z] then
            table.insert(buffer, x)
            table.insert(buffer, z)
            loaded_chunks[x .. '/' .. z] = true
        end
        return
    end

    SERVER:push_packet(protocol.ClientMsg.RequestChunks, { buffer })
    buffer = { x, z }
end

function on_chunk_remove(x, z)
    loaded_chunks[x .. '/' .. z] = nil
end

function on_world_tick()
    utils.__tick()

    CLIENT_PLAYER:tick()

    local x, y, z = player.get_pos(CLIENT_PLAYER.pid)

    if y < 0 or y > 255 then
        player.set_pos(CLIENT_PLAYER.pid, x, math.clamp(y, 0, 255), z)
    end

    if not CACHED_DATA.over then
        CLIENT_PLAYER:set_pos(CACHED_DATA.pos, false)
        CLIENT_PLAYER:set_rot(CACHED_DATA.rot, false)
        CLIENT_PLAYER:set_cheats(CACHED_DATA.cheats, false)
        CLIENT_PLAYER:set_inventory(CACHED_DATA.inv, false)
        CLIENT_PLAYER:set_slot(CACHED_DATA.slot, false)
        CLIENT_PLAYER:set_infinite_items(CACHED_DATA.infinite_items, false)
        CLIENT_PLAYER:set_instant_destruction(CACHED_DATA.instant_destruction, false)
        CLIENT_PLAYER:set_interaction_distance(CACHED_DATA.interaction_distance, false)
    end

    if external_app.get_setting("chunks.load-distance") > CHUNK_LOADING_DISTANCE then
        external_app.set_setting("chunks.load-distance", CHUNK_LOADING_DISTANCE)
    end
end

function on_block_placed(blockid, x, y, z, playerid)
    if not CLIENT_PLAYER then return end
    if playerid ~= CLIENT_PLAYER.pid then return end

    local states = block.get_states(x, y, z)

    sandbox.on_placed(blockid, x, y, z, states)
end

function on_block_broken(blockid, x, y, z, playerid)
    if not CLIENT_PLAYER then return end
    if playerid ~= CLIENT_PLAYER.pid then return end

    sandbox.on_broken(blockid, x, y, z)
end

function on_block_interact(blockid, x, y, z, playerid)
    if not CLIENT_PLAYER then return end
    if playerid ~= CLIENT_PLAYER.pid then return end

    x, y, z = block.seek_origin(x, y, z)
    sandbox.on_interact(blockid, x, y, z)
end
