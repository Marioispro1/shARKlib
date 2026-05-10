--!strict
local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)
local Log = require(script.Parent.Parent.tooling.log)

local function onEvent(name: string, fn: (...any) -> ())
    return action(function(instance: Instance)
        local sig = (instance :: any)[name]
        if typeof(sig) ~= "RBXScriptSignal" then
            error(
                Log.message("instance.onEvent", "bind", ("%s.%s is not a signal"):format(instance.ClassName, name)),
                2
            )
        end
        local conn = sig:Connect(fn)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function() conn:Disconnect() end)
        end
    end)
end

return onEvent

