--!strict
--[[
    cleanup.luau
    Register a callback to run when the enclosing scope is re-evaluated
    or disposed. Outside of any scope this is a silent no-op (and warns).
]]

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
