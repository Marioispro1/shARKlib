--!strict
--[[
    show.luau
    Conditionally renders a component based on a boolean source. The
    component re-runs only when the truthiness of `cond` changes (so
    children are not destroyed for unrelated state changes).
]]

local derive = require(script.Parent.Parent.core.derive)
local Graph = require(script.Parent.Parent.core.graph)

local function show<T>(cond: () -> any, component: () -> T, fallback: (() -> T)?): () -> T?
	local truthy = derive(function()
		return cond() and true or false
	end)
	local node = Graph.createNode(
		function()
			if truthy() then
				return component()
			elseif fallback then
				return fallback()
			end
			return nil
		end :: any,
		nil
	)
	Graph.run(node)
	return function()
		return Graph.read(node)
	end
end

return show
