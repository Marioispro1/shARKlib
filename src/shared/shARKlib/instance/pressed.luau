--!strict
--[[
    pressed.luau
    Like `hover`, but tracks whether the user is currently holding the
    mouse button down on the target. Works on any GuiObject; uses
    InputBegan/InputEnded so it covers MouseButton1 and Touch.
]]

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)
local source  = require(script.Parent.Parent.core.source)

local function pressed(): (any, () -> boolean)
    local down = source(false)
    local act = action(function(instance: Instance)
        if not instance:IsA("GuiObject") then return end
        local c1 = instance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                down(true)
            end
        end)
        local c2 = instance.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                down(false)
            end
        end)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                c1:Disconnect(); c2:Disconnect()
            end)
        end
    end)
    return act, down
end

return pressed
