--!strict
--[[
    watch.luau
    Run a callback whenever a source (or any reactive expression)
    changes — but skip the initial synchronous invocation. Returns a
    function to stop early.

        watch(count, function(new, old) print(new, old) end)
]]

local Graph = require(script.Parent.graph)

local function watch<T>(source: () -> T, fn: (new: T, old: T?) -> ()): () -> ()
    local first = true
    local prev: T? = nil
    local node = Graph.createNode(function()
        local v = source()
        if first then
            first = false
            prev = v
            return v
        end
        local old = prev
        prev = v
        fn(v, old)
        return v
    end :: any, nil)
    Graph.run(node)
    return function() Graph.dispose(node) end
end

return watch
