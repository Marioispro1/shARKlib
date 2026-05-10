--!strict
local Graph = require(script.Parent.graph)

local function derive<T>(fn: () -> T, equals: ((T, T) -> boolean)?): () -> T
	local node = Graph.createNode(fn :: any, nil, equals :: any)
	Graph.run(node)
	return function(): T
		return Graph.read(node)
	end
end

return derive

