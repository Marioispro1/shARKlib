--!strict
local Runtime = require(script.Parent.runtime)
local Log = require(script.Parent.Parent.tooling.log)

local function cleanup(fn: () -> ())
    local owner = Runtime.owner
    if not owner then
        Log.warn("cleanup", "register", "called outside of a reactive scope; ignored")
        return
    end
    table.insert(owner.cleanups, fn)
end

return cleanup

