--!strict
--[[
    values.luau
    Render a list keyed by *value identity* (preserving rendered
    instances when items are reordered). The component is invoked once
    per unique value with a *source* yielding that item's index.
]]

local Graph = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source = require(script.Parent.Parent.core.source)
local root = require(script.Parent.Parent.core.root)

local function values<T>(list: () -> { T }, component: (T, () -> number) -> any): () -> { any }
	local entries: { [any]: { indexSource: any, destroy: () -> (), rendered: any } } = {}

	local node = Graph.createNode(
		function()
			local arr = list() or {}
			local seen: { [any]: true } = {}
			local out = table.create(#arr)

			for i, item in ipairs(arr) do
				seen[item] = true
				local entry = entries[item]
				if entry then
					entry.indexSource(i)
				else
					local idx
					local rendered
					local destroy
					root(function(d)
						destroy = d
						-- create the index source INSIDE the detached root
						-- so it isn't disposed when the outer values node
						-- re-runs disposeChildren on itself.
						idx = source(i)
						rendered = component(item, idx)
					end)
					entry = { indexSource = idx, destroy = destroy :: any, rendered = rendered }
					entries[item] = entry
				end
				out[i] = entry.rendered
			end

			for k, e in pairs(entries) do
				if not seen[k] then
					e.destroy()
					entries[k] = nil
				end
			end

			return out
		end :: any,
		nil
	)

	Graph.run(node)

	if Runtime.owner then
		table.insert(Runtime.owner.cleanups, function()
			for _, e in pairs(entries) do
				e.destroy()
			end
			table.clear(entries)
		end)
	end

	return function()
		return Graph.read(node)
	end
end

return values
