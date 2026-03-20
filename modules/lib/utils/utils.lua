local utils = {}

function utils.lerp(cur_pos, target_pos, t)
    t = math.clamp(t, 0, 1)
    local diff = vec3.sub(target_pos, cur_pos)
    local scaledDiff = vec3.mul(diff, t)
    return vec3.add(cur_pos, scaledDiff)
end

local tickers = {}

function utils.get_tick(key)
   return tickers[key]
end

function utils.remove_tick(key)
   tickers[key] = nil
end

function utils.to_tick(func, args, key)
   if not key then
      table.insert(tickers, {func, args})
   else
      tickers[key] = {func, args}
   end
end

function utils.__tick()
    for i, ticker in pairs(tickers) do
        local func = ticker[1]
        local args = ticker[2]

        local res = func(unpack(args))
        if res == nil and type(i) == "number" then
           table.remove(tickers, i)
        elseif res == nil then
           tickers[i] = nil
        else
           ticker[2] = res
        end
   end
end

return utils