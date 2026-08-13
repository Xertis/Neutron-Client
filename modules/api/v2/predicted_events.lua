local Messages = import "api/v2/messages"

local next_request_id = 0

local PredictedEvent = {}
PredictedEvent.__index = PredictedEvent

local Instant = {}
Instant.__index = Instant


function PredictedEvent.new(pack, event, schema, config)
    if not schema.pos then
        error("The schema must include a 'pos' field")
    end

    local self = {}

    self.messages = {
        c_start = Messages.new(pack, event, {
            request_id = "var",
            data = schema
        }),
        c_interrupt = Messages.new(pack, event .. "0", {
            event_id = "var"
        }),
        s_ack = Messages.new(pack, event .. "2", {
            request_id = "var",
            event_id = "Nilable<var>",
            accepted = "boolean"
        }),
        s_observe_start = Messages.new(pack, event .. "3", {
            event_id = "var",
            progress = "norm16",
            data = schema
        }),
        s_progress = Messages.new(pack, event .. "4", {
            event_id = "var",
            progress = "norm16"
        }),
        s_finish = Messages.new(pack, event .. "5", {
            event_id = "var"
        }),
        s_interrupt = Messages.new(pack, event .. "6", {
            event_id = "var"
        })
    }

    self.messages.s_ack:on(function (data)
        local requested_instant = self.requested_instances[data.request_id]
        self.requested_instances[data.request_id] = nil

        if data.accepted then
            self.instances[data.event_id] = requested_instant
            requested_instant.event_id = data.event_id
            requested_instant.active = true
            self.config.on_ack_start(requested_instant)
        else
            self.config.on_reject(requested_instant)
        end
    end)

    self.messages.s_progress:on(function (data)
        local instant = self.instances[data.event_id]
        if not instant then return end

        instant.progress = data.progress

        self.config.on_progress(instant)
    end)

    self.messages.s_finish:on(function (data)
        local instant = self.instances[data.event_id]
        if not instant then return end
        instant.progress = 1
        instant.active = false
        self.instances[data.event_id] = nil
        self.config.on_finish(instant)
    end)

    self.messages.s_interrupt:on(function (data)
        local instant = self.instances[data.event_id]
        if not instant then return end
        instant.active = false
        self.instances[data.event_id] = nil
        self.config.on_interrupt(instant)
    end)

    self.messages.s_observe_start:on(function (packet)
        local instant = Instant.new(self, packet.event_id, nil, packet.data, packet.progress)
        self.instances[packet.event_id] = instant
        self.config.on_ack_start(instant)
    end)

    self.requested_instances = {}
    self.instances = {}

    self.config = config

    return setmetatable(self, PredictedEvent)
end

function PredictedEvent:start(data)
    self.messages.c_start:send({
        request_id = next_request_id,
        data = data
    })

    local instant = Instant.new(self, nil, next_request_id, data, 0)
    self.requested_instances[next_request_id] = instant

    next_request_id = next_request_id + 1

    return instant
end

function Instant.new(predicted, event_id, request_id, data, progress)
    return setmetatable({
        event_id = event_id,
        request_id = request_id,
        data = data,
        progress = progress,
        predicted = predicted,
        active = false
    }, Instant)
end

function Instant:get_progress()
	return self.progress
end

function Instant:interrupt()
    if not self.active then return end

    self.active = false
    self.predicted.messages.c_interrupt:send({
        event_id = self.event_id
    })
end

return PredictedEvent
