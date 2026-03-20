local module = {}
local tasks = {}

function module.add_task(job, on_cancel, config, args)
    local new_task = {
        job = job,
        time = config.time,
        delay = config.delay or 0,
        start_time = time.uptime(),
        data = args,
        last_start = 0,
        job_name = config.job_name,
        on_cancel = on_cancel or function () end
    }

    table.insert(tasks, new_task)
end

function module.cancel_task(job_name)
    for i=#tasks, 1, -1 do
        if tasks[i].job_name == job_name then
            tasks[i].on_cancel()
            table.remove(tasks, i)
        end
    end
end

events.on("client:hud_render", function ()
    local cur_time = time.uptime()
    for i=#tasks, 1, -1 do
        local task = tasks[i]

        if task.start_time + task.time < cur_time then
            task.on_cancel()
            table.remove(tasks, i)
        else
            if cur_time - task.last_start > task.delay then
                task.data = {task.job(unpack(task.data))}
                task.last_start = cur_time
            end
        end
    end
end)

return module