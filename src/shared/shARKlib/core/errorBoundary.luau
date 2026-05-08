--!strict
local Graph  = require(script.Parent.graph)
local source = require(script.Parent.source)

local function errorBoundary(try: () -> any, fallback: (any, () -> ()) -> any): () -> any
    local err = source(nil :: any)
    local function reset() err(nil) end

    local boundary = Graph.createNode(function()
        local e = err()
        if e ~= nil then
            return fallback(e, reset)
        end
        local ok, result = pcall(try)
        if ok then return result end
        err(result)
        return nil
    end :: any, nil)

    -- install a handler so child errors are funneled into our `err` source
    boundary.handlers = { function(e) err(e) end }
    Graph.run(boundary)

    return function() return Graph.read(boundary) end
end

return errorBoundary
