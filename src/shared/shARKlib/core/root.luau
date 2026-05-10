--!strict
local Graph = require(script.Parent.graph)
local Runtime = require(script.Parent.runtime)

local function root<T...>(fn: (destroy: () -> ()) -> T...): T...
	local node = Graph.createNode(nil, nil)
	-- detach from any ambient owner. createnode already inserted us
	-- into runtime.owner.children, so remove that entry too — otherwise
	-- when the outer scope re-evaluates it would dispose us along with
	-- its real children.
	if node.owner then
		local siblings = node.owner.children
		for i = #siblings, 1, -1 do
			if siblings[i] == node then
				local n = #siblings
				siblings[i] = siblings[n]
				siblings[n] = nil
				break
			end
		end
		node.owner = nil
	end
	local prevOwner, prevCurrent = Runtime.owner, Runtime.current
	Runtime.owner = node
	Runtime.current = nil
	local destroy = function()
		Graph.dispose(node)
	end
	local ok, a, b, c, d, e = pcall(fn, destroy)
	Runtime.owner = prevOwner
	Runtime.current = prevCurrent
	if not ok then
		Graph.dispose(node)
		error(a, 0)
	end
	return a, b, c, d, e
end

return root

