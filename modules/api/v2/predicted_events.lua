local Messages = import "api/v2/messages"

local next_request_id = 0
local next_instance_id = 0

local PredictedEvent = {}
PredictedEvent.__index = PredictedEvent

local Instance = {}
Instance.__index = Instance


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

    config = {
        on_ack_start = config.on_ack_start or function(_) end,
        on_reject = config.on_reject or function(_) end,
        on_progress = config.on_progress or function(_) end,
        on_finish = config.on_finish or function(_) end,
        on_interrupt = config.on_interrupt or function(_) end,
    }

    self.messages.s_ack:on(function (data)
        local requested_instance = self.requested_instances[data.request_id]
        self.requested_instances[data.request_id] = nil

        if data.accepted then
            self.instances[data.event_id] = requested_instance
            requested_instance.event_id = data.event_id
            requested_instance.active = true
            self.config.on_ack_start(requested_instance)
        else
            self.config.on_reject(requested_instance)
        end
    end)

    self.messages.s_progress:on(function (data)
        local instance = self.instances[data.event_id]
        if not instance then return end

        instance.progress = data.progress

        self.config.on_progress(instance)
    end)

    self.messages.s_finish:on(function (data)
        local instance = self.instances[data.event_id]
        if not instance then return end
        instance.progress = 1
        instance.active = false
        self.instances[data.event_id] = nil
        self.config.on_finish(instance)
    end)

    self.messages.s_interrupt:on(function (data)
        local instance = self.instances[data.event_id]
        if not instance then return end
        instance.active = false
        self.instances[data.event_id] = nil
        self.config.on_interrupt(instance)
    end)

    self.messages.s_observe_start:on(function (packet)
        local instance = Instance.new(self, packet.event_id, nil, packet.data, packet.progress)
        self.instances[packet.event_id] = instance
        self.config.on_ack_start(instance)
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

    local instance = Instance.new(self, nil, next_request_id, data, 0)
    self.requested_instances[next_request_id] = instance

    next_request_id = next_request_id + 1

    return instance
end

function Instance.new(predicted, event_id, request_id, data, progress)
    local instance = setmetatable({
        instance_id = next_instance_id,
        event_id = event_id,
        request_id = request_id,
        data = data,
        start_time = time.uptime(),
        progress = progress,
        predicted = predicted,
        active = false
    }, Instance)

    next_instance_id = next_instance_id + 1

    return instance
end

function Instance:get_progress()
    return self.progress
end

function Instance:get_elapsed()
    local now = time.uptime()
    return now - self.start_time
end

function Instance:interrupt()
    if not self.active then return end

    self.active = false
    self.predicted.messages.c_interrupt:send({
        event_id = self.event_id
    })
end

return PredictedEvent
