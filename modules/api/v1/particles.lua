local entities = import "api/v1/entities"
local utils = import "lib/utils/utils"

local uids = entities.__get_uids__()
local PARTICLES_PID = {}
local module = {}

function module.emit(particle)
    if type(particle.origin) == "number" then
        local origin = uids[particle.origin]
        if origin then
            particle.origin = origin
        else
            utils.to_tick(function(_particle)
                if uids[_particle.origin] then
                    module.emit(_particle)
                    return
                end

                return { _particle }
            end, { particle }, tostring(particle.pid) .. "particle")

            return
        end
    end

    local client_pid = gfx.particles.emit(
        particle.origin,
        particle.count,
        particle.preset,
        particle.extension
    )

    PARTICLES_PID[particle.pid] = client_pid
end

function module.stop(pid)
    if not PARTICLES_PID[pid] then
        utils.remove_tick(tostring(pid) .. "particle")
        return
    end
    gfx.particles.stop(PARTICLES_PID[pid])
    PARTICLES_PID[pid] = nil
end

function module.set_origin(particle)
    if not PARTICLES_PID[particle.pid] then
        local ticker = utils.get_tick(tostring(particle.pid) .. "particle")
        ticker[2][1].origin = particle.origin
        return
    end
    gfx.particles.set_origin(PARTICLES_PID[particle.pid], particle.origin)
end

return module
