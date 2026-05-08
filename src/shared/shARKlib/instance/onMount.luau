--!strict
--[[
    onMount.luau
    Action that runs `fn(instance)` once, on the next frame after the
    instance is parented into the live UI tree. Useful for layout that
    requires the instance to have a real `AbsoluteSize`/`AbsolutePosition`.

        sh.create("Frame") {
            sh.onMount(function(frame)
                print("size:", frame.AbsoluteSize)
            end),
        }
]]

local RunService = game:GetService("RunService")

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)

local function onMount(fn: (Instance) -> ())
    return action(function(instance: Instance)
        local thread = task.spawn(function()
            -- wait until parented somewhere ancestor-rooted
            while not instance:IsDescendantOf(game) do
                RunService.Heartbeat:Wait()
                if not instance.Parent then return end
            end
            fn(instance)
        end)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                task.cancel(thread)
            end)
        end
    end, 1000) -- low priority so other actions run first
end

return onMount
