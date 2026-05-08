--!strict
local Runtime = require(script.Parent.runtime)

local function cleanup(fn: () -> ())
    local owner = Runtime.owner
    if not owner then
        warn("[shARKlib] cleanup() called outside of a reactive scope; ignored")
        return
    end
    table.insert(owner.cleanups, fn)
end

return cleanup
