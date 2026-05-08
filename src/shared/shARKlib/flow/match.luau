--!strict
--[[
    match.luau
    Like `switch` but matches via predicates rather than equality.

        match(state) {
            { function(s) return s.kind == "loading" end, Loading },
            { function(s) return s.kind == "ready"   end, Ready   },
        }
]]

local Graph = require(script.Parent.Parent.core.graph)

local function match<T>(source: () -> T)
	return function(cases: { { any } })
		local node = Graph.createNode(
			function()
				local v = source()
				for i = 1, #cases do
					local case = cases[i]
					if case[1](v) then
						return case[2]()
					end
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
end

return match
