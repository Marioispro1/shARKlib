--!strict
--[[
    changed.luau
    Returns an action that, when applied to an instance, mirrors a
    property's value into a callback (or source) on every change.

        apply(textBox, { Text = "", changed("Text", textSource) })
]]

local action = require(script.Parent.action)

local function changed(property: string, callback: (any) -> ())
    return action(function(instance: Instance)
        callback((instance :: any)[property])
        local conn = instance:GetPropertyChangedSignal(property):Connect(function()
            callback((instance :: any)[property])
        end)
        local Runtime = require(script.Parent.Parent.core.runtime)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function() conn:Disconnect() end)
        end
    end, 100)
end

return changed
