local module = {}

local SPEAKERS_IDS = {}

function module.emit(Audio)
    local play_func = audio.isStream and
                    (Audio.x and audio.play_stream or audio.play_stream_2d) or
                    (Audio.x and audio.play_sound or audio.play_sound_2d)

    local id
    if Audio.x then
        id = play_func(
            Audio.path,
            Audio.x, Audio.y, Audio.z,
            Audio.volume,
            Audio.pitch,
            Audio.channel,
            Audio.loop
        )
    else
        id = play_func(
            Audio.path,
            Audio.volume,
            Audio.pitch,
            Audio.channel,
            Audio.loop
        )
    end

    SPEAKERS_IDS[Audio.id] = id
end

function module.stop(id)
    if SPEAKERS_IDS[id] then
        audio.stop(SPEAKERS_IDS[id])
        SPEAKERS_IDS[id] = nil
    end
end

function module.apply(sound)
    if not sound or not SPEAKERS_IDS[sound.id] then
        return
    end

    local id = SPEAKERS_IDS[sound.id]

    if sound.loop ~= nil then
        audio.set_loop(id, sound.loop)
    end

    if sound.volume ~= nil then
        audio.set_volume(id, sound.volume)
    end

    if sound.pitch ~= nil then
        audio.set_pitch(id, sound.pitch)
    end

    if sound.x then
        audio.set_position(id, sound.x, sound.y, sound.z)
    end

    if sound.time ~= nil then
        audio.set_time(id, sound.time)
    end

    if sound.velX then
        audio.set_velocity(id, sound.velX, sound.velY, sound.velZ)
    end

    if sound.paused == true then
        audio.pause(id)
    end

    if sound.paused == false then
        audio.resume(id)
    end

    return true
end

return module