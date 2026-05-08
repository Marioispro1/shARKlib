--!strict
--[[
    onEvent.luau
    Attach a connection to an arbitrary RBXScriptSignal property of an
    instance using a string name. Convenient when the property name
    isn't statically known, or when you want a self-cleaning handler:

        sh.create("Part") {
            sh.onEvent("Touched", function(other) ... end),
        }
]]

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)

local function onEvent(name: string, fn: (...any) -> ())
    return action(function(instance: Instance)
        local sig = (instance :: any)[name]
        if typeof(sig) ~= "RBXScriptSignal" then
            error(("[shARKlib] onEvent: %s.%s is not a signal"):format(instance.ClassName, name), 2)
        end
        local conn = sig:Connect(fn)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function() conn:Disconnect() end)
        end
    end)
end

return onEvent
