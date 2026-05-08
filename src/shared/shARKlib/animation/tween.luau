--!strict
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local Graph   = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source  = require(script.Parent.Parent.core.source)

local function lerpAny(a: any, b: any, t: number): any
    local kind = typeof(a)
    if kind == "number"  then return a + (b - a) * t end
    if kind == "Vector2" or kind == "Vector3" or kind == "Color3" then
        return a:Lerp(b, t)
    end
    if kind == "UDim" then
        return UDim.new(a.Scale + (b.Scale - a.Scale) * t, a.Offset + (b.Offset - a.Offset) * t)
    end
    if kind == "UDim2" then
        return UDim2.new(
            a.X.Scale  + (b.X.Scale  - a.X.Scale)  * t,
            a.X.Offset + (b.X.Offset - a.X.Offset) * t,
            a.Y.Scale  + (b.Y.Scale  - a.Y.Scale)  * t,
            a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t
        )
    end
    error("[shARKlib] tween: unsupported type " .. kind, 3)
end

local function tween<T>(target: () -> T, info: TweenInfo?): () -> T
    info = info or TweenInfo.new(0.25)
    local current = target()
    local out = source(current)

    local from, to = current, current
    local startedAt = os.clock()
    local conn: RBXScriptConnection? = nil

    local function tick()
        local i = info :: TweenInfo
        local elapsed = os.clock() - startedAt
        local alpha = math.clamp(elapsed / math.max(i.Time, 1e-6), 0, 1)
        local eased = TweenService:GetValue(alpha, i.EasingStyle, i.EasingDirection)
        out(lerpAny(from, to, eased))
        if alpha >= 1 then
            if conn then conn:Disconnect(); conn = nil end
        end
    end

    local watcher = Graph.createNode(function()
        local newTarget = target()
        if newTarget == to then return nil end
        from = out()
        to = newTarget
        startedAt = os.clock()
        if not conn then conn = RunService.Heartbeat:Connect(tick) end
        return nil
    end :: any, nil)
    Graph.run(watcher)

    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function()
            if conn then conn:Disconnect() end
        end)
    end

    return out
end

return tween
