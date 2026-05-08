--!strict
local Runtime = require(script.Parent.Parent.core.runtime)
local source  = require(script.Parent.Parent.core.source)
local Graph   = require(script.Parent.Parent.core.graph)

local function throttle<T>(input: () -> T, interval: number): () -> T
    local out = source(input())
    local lastEmit = 0
    local pending: thread? = nil
    local pendingValue: T

    local watcher = Graph.createNode(function()
        local v = input()
        local now = os.clock()
        local since = now - lastEmit
        if since >= interval then
            lastEmit = now
            out(v)
        else
            pendingValue = v
            if not pending then
                pending = task.delay(interval - since, function()
                    pending = nil
                    lastEmit = os.clock()
                    out(pendingValue)
                end)
            end
        end
        return nil
    end :: any, nil)
    Graph.run(watcher)

    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function()
            if pending then task.cancel(pending) end
        end)
    end

    return out
end

return throttle
