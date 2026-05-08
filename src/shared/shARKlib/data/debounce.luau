--!strict
--[[
    debounce.luau
    Wraps a source so reads see the latest value, but downstream
    observers are only notified after `delay` seconds of quiet.

        local query = sh.source("")
        local debounced = sh.debounce(query, 0.25)
        sh.effect(function() runSearch(debounced()) end)
]]

local Runtime = require(script.Parent.Parent.core.runtime)
local source  = require(script.Parent.Parent.core.source)
local Graph   = require(script.Parent.Parent.core.graph)

local function debounce<T>(input: () -> T, delay: number): () -> T
    local out = source(input())
    local pending: thread? = nil

    local watcher = Graph.createNode(function()
        local v = input()
        if pending then task.cancel(pending) end
        pending = task.delay(delay, function()
            pending = nil
            out(v)
        end)
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

return debounce
