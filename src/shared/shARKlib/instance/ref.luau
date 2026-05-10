--!strict
local action = require(script.Parent.action)

local function ref<T>(target: ((Instance) -> ()) | ((T?) -> T))
    return action(function(instance: Instance)
        (target :: any)(instance)
    end, -1000) -- run very early so other actions can read the ref
end

return ref

