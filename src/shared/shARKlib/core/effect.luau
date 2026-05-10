--!strict
local Graph = require(script.Parent.graph)

local function effect(fn: () -> ())
    local node = Graph.createNode(fn :: any, nil)
    Graph.run(node)
end

return effect

