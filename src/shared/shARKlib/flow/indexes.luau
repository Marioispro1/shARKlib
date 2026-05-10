--!strict
local Graph = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source = require(script.Parent.Parent.core.source)
local root = require(script.Parent.Parent.core.root)

local function indexes<T>(list: () -> { T }, component: (() -> T, number) -> any): () -> { any }
	local items: { { source: any, value: any, destroy: () -> () } } = {}

	local node = Graph.createNode(
		function()
			local arr = list() or {}
			local n = #arr

			-- shrink: dispose extras
			for i = #items, n + 1, -1 do
				items[i].destroy()
				items[i] = nil
			end

			-- update / extend
			for i = 1, n do
				local entry = items[i]
				if entry then
					if entry.value ~= arr[i] then
						entry.source(arr[i])
						entry.value = arr[i]
					end
				else
					local sig
					local rendered
					local destroy
					local indexAtCreate = i
					root(function(d)
						destroy = d
						-- create the value source inside the detached root
						-- so it survives outer re-evaluations.
						sig = source(arr[indexAtCreate])
						rendered = component(sig, indexAtCreate)
					end)
					items[i] = {
						source = sig,
						value = arr[i],
						destroy = destroy :: any,
						rendered = rendered,
					} :: any
				end
			end

			local out = table.create(n)
			for i = 1, n do
				out[i] = (items[i] :: any).rendered
			end
			return out
		end :: any,
		nil
	)

	Graph.run(node)

	if Runtime.owner then
		table.insert(Runtime.owner.cleanups, function()
			for i = #items, 1, -1 do
				items[i].destroy()
			end
			table.clear(items)
		end)
	end

	return function()
		return Graph.read(node)
	end
end

return indexes

