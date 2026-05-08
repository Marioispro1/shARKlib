--!strict
--[[
    derive.luau
    A memoized computed value. Re-runs when any tracked source changes;
    only notifies its own observers when the result is not equal.
]]

local Graph = require(script.Parent.graph)

local function derive<T>(fn: () -> T, equals: ((T, T) -> boolean)?): () -> T
	local node = Graph.createNode(fn :: any, nil, equals :: any)
	Graph.run(node)
	return function(): T
		return Graph.read(node)
	end
end

return derive
