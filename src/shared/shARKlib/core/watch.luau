--!strict
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
