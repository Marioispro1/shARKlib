--!strict
local Graph = require(script.Parent.graph)
local untrack = require(script.Parent.untrack)

local function watch<T>(source: () -> T, fn: (new: T, old: T?) -> ()): () -> ()
    local first = true
    local prev: T? = nil
	local node = Graph.createNode(function()
		local v = source()
		if first then
			first = false
			prev = v
			return v
		end
		local old = prev
		prev = v
		-- Only `source()` should be tracked by this watcher.
		-- Running the callback untracked prevents accidental
		-- self-subscriptions and feedback loops.
		untrack(function()
			fn(v, old)
		end)
		return v
	end :: any, nil)
    Graph.run(node)
    return function() Graph.dispose(node) end
end

return watch

