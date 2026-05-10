--!strict
local source = require(script.Parent.Parent.core.source)
local Runtime = require(script.Parent.Parent.core.runtime)

local function screenSize(): () -> Vector2
    local camera = workspace.CurrentCamera
    local s = source(camera and camera.ViewportSize or Vector2.zero)

    local conn: RBXScriptConnection? = nil
    local function bind(c: Camera)
        if conn then conn:Disconnect() end
        conn = c:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            s(c.ViewportSize)
        end)
        s(c.ViewportSize)
    end

    if camera then bind(camera) end
    local cameraConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local c = workspace.CurrentCamera
        if c then bind(c) end
    end)

    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function()
            if conn then conn:Disconnect() end
            cameraConn:Disconnect()
        end)
    end

    return s
end

return screenSize

