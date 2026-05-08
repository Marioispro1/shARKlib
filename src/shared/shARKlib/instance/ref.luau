--!strict
--[[
    ref.luau
    Capture an Instance reference, either via a callback or by writing
    to a source. Two equivalent forms:

        local frame
        sh.create("Frame") {
            sh.ref(function(inst) frame = inst end),
        }

        local frameRef = sh.source(nil :: Frame?)
        sh.create("Frame") {
            sh.ref(frameRef),
        }
]]

local action = require(script.Parent.action)

local function ref<T>(target: ((Instance) -> ()) | ((T?) -> T))
    return action(function(instance: Instance)
        (target :: any)(instance)
    end, -1000) -- run very early so other actions can read the ref
end

return ref
