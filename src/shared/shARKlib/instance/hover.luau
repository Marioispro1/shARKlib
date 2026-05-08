--!strict
--[[
    hover.luau
    Returns an `(action, source)` pair: the action wires the action
    target's `MouseEnter`/`MouseLeave` to a boolean source you read.

        local h, hovering = sh.hover()
        sh.create("Frame") {
            BackgroundColor3 = function() return hovering() and accent or base end,
            h,
        }
]]

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)
local source  = require(script.Parent.Parent.core.source)

local function hover(): (any, () -> boolean)
    local hovering = source(false)
    local act = action(function(instance: Instance)
        if not instance:IsA("GuiObject") then return end
        local c1 = instance.MouseEnter:Connect(function() hovering(true)  end)
        local c2 = instance.MouseLeave:Connect(function() hovering(false) end)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function() c1:Disconnect(); c2:Disconnect() end)
        end
    end)
    return act, hovering
end

return hover
