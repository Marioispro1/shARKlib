--!strict
--[[
    switch.luau
    `switch(source) { [key] = component, ... }` selects exactly one
    component per source value. Only re-renders when the key changes;
    components are memoized per key so switching back is cheap.
]]

local Graph = require(script.Parent.Parent.core.graph)
local derive = require(script.Parent.Parent.core.derive)

local function switch<K>(source: () -> K)
	return function(cases: { [K]: () -> any })
		local key = derive(source)
		local cache: { [any]: any } = {}
		local node = Graph.createNode(
			function()
				local k = key()
				local component = cases[k]
				if not component then
					return nil
				end
				local cached = cache[k]
				if cached ~= nil then
					return cached
				end
				local result = component()
				cache[k] = result
				return result
			end :: any,
			nil
		)
		Graph.run(node)
		return function()
			return Graph.read(node)
		end
	end
end

return switch
