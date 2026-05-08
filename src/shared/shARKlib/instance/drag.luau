--!strict
--[[
    drag.luau
    Make a GuiObject draggable. Returns `(action, positionSource)`
    where the source tracks the GuiObject's `Position` (UDim2) as it
    is dragged.

        local d, pos = sh.drag()
        sh.create("Frame") {
            Position = pos, -- bind to Position so the move sticks
            d,
        }
]]

local UserInputService = game:GetService("UserInputService")

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)
local source  = require(script.Parent.Parent.core.source)

local function drag(initial: UDim2?): (any, () -> UDim2)
    local pos = source(initial or UDim2.fromScale(0, 0))

    local act = action(function(instance: Instance)
        if not instance:IsA("GuiObject") then return end
        if initial then instance.Position = initial end

        local dragging = false
        local startInput: Vector3
        local startPos:   UDim2
        local conns: { RBXScriptConnection } = {}

        table.insert(conns, instance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startInput = input.Position
                startPos = instance.Position
            end
        end))

        table.insert(conns, instance.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        table.insert(conns, UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - startInput
            local next = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            pos(next)
        end))

        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                for _, c in ipairs(conns) do c:Disconnect() end
            end)
        end
    end)

    return act, pos
end

return drag
