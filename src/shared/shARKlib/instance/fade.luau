--!strict
--[[
    fade.luau
    Action that fades a GuiObject's transparency in on mount and out
    on cleanup. Useful for entry/exit animations.

        sh.create("Frame") {
            sh.fade { duration = 0.2 },
            ...
        }

    `propertyMap` lets you override which transparency-style properties
    to animate. By default: BackgroundTransparency, TextTransparency,
    ImageTransparency — whichever the instance actually has.
]]

local TweenService = game:GetService("TweenService")

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)

type Opts = {
    duration: number?,
    easing: Enum.EasingStyle?,
    direction: Enum.EasingDirection?,
    fadeOut: boolean?,
    propertyMap: { string }?,
}

local CANDIDATES = { "BackgroundTransparency", "TextTransparency", "ImageTransparency" }

local function fade(opts: Opts?)
    opts = opts or {}
    local duration  = opts.duration or 0.2
    local easing    = opts.easing or Enum.EasingStyle.Quad
    local direction = opts.direction or Enum.EasingDirection.Out
    local doExit    = opts.fadeOut ~= false

    return action(function(instance: Instance)
        local props = opts.propertyMap or CANDIDATES
        local snapshots: { [string]: number } = {}
        for _, p in ipairs(props) do
            local ok, v = pcall(function() return (instance :: any)[p] end)
            if ok and type(v) == "number" then snapshots[p] = v end
        end

        -- fade in: start at 1, tween to original
        for p in pairs(snapshots) do (instance :: any)[p] = 1 end
        local info = TweenInfo.new(duration, easing, direction)
        TweenService:Create(instance, info, snapshots :: any):Play()

        if doExit and Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                if not instance.Parent then return end
                local target: { [string]: any } = {}
                for p in pairs(snapshots) do target[p] = 1 end
                local exitInfo = TweenInfo.new(duration, easing, Enum.EasingDirection.In)
                local tween = TweenService:Create(instance, exitInfo, target)
                tween:Play()
                tween.Completed:Once(function() instance:Destroy() end)
            end)
        end
    end, 500)
end

return fade
