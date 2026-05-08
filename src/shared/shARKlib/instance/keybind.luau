--!strict
--[[
    keybind.luau
    Bind a keyboard key to a callback. Cleans up automatically.

        sh.keybind(Enum.KeyCode.E, function() print("E pressed") end)
        sh.keybind(Enum.KeyCode.Escape, close, { gameProcessed = true })
]]

local UserInputService = game:GetService("UserInputService")

local Runtime = require(script.Parent.Parent.core.runtime)

type Opts = { gameProcessed: boolean?, ended: boolean? }

local function keybind(key: Enum.KeyCode, fn: (input: InputObject) -> (), opts: Opts?)
    local allowGameProcessed = opts and opts.gameProcessed or false
    local fireOnEnded        = opts and opts.ended or false

    local signal = if fireOnEnded then UserInputService.InputEnded else UserInputService.InputBegan
    local conn = signal:Connect(function(input, gameProcessed)
        if gameProcessed and not allowGameProcessed then return end
        if input.KeyCode == key then fn(input) end
    end)
    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function() conn:Disconnect() end)
    else
        warn("[shARKlib] keybind called outside of a reactive scope; never disposed")
    end
    return function() conn:Disconnect() end
end

return keybind
