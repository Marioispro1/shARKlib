--!strict
--[[
    source.luau
    A `source` is a callable reactive cell: invoke with no argument to
    read (and subscribe), or with an argument to write. Pass an updater
    function to compute a new value from the previous one.
]]

local Graph = require(script.Parent.graph)

export type Source<T> = (T?) -> T

local function source<T>(initial: T, equals: ((T, T) -> boolean)?): Source<T>
	local node = Graph.createNode(nil, initial, equals :: any)
	return function(...): T
		if select("#", ...) == 0 then
			return Graph.read(node)
		end
		local v = (select(1, ...))
		if type(v) == "function" then
			v = v(node.value)
		end
		return Graph.write(node, v)
	end
end

return source
