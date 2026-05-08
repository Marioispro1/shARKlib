--!strict
--[[
    effect.luau
    Schedules a function to run immediately and again whenever any
    source it reads changes. Returns nothing; cleanup is bound to the
    enclosing root / scope.
]]

local Graph = require(script.Parent.graph)

local function effect(fn: () -> ())
    local node = Graph.createNode(fn :: any, nil)
    Graph.run(node)
end

return effect
