--!strict
--[[
    smoothLayout.luau
    A drop-in replacement for `UIListLayout` that springs each child
    toward its target slot instead of snapping. Use it like a normal
    layout child:

        sh.create("Frame") {
            sh.smoothLayout {
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDim.new(0, 6),
                SortOrder     = Enum.SortOrder.LayoutOrder,
            },
            ...children...
        }

    Optional second arg overrides spring params:
        sh.smoothLayout(opts, { period = 0.35, damping = 0.85 })

    Notes
      * Children are positioned with `Position = UDim2.fromOffset(x, y)`
        so don't also bind `Position` to a source.
      * `Size` of children is read each frame; UI components that
        change size dynamically work out of the box.
      * Re-layouts happen on ChildAdded / ChildRemoved /
        LayoutOrder change / Size change / Visible change.
]]

local RunService = game:GetService("RunService")

local Runtime = require(script.Parent.Parent.core.runtime)
local action  = require(script.Parent.action)

type Opts = {
    FillDirection: Enum.FillDirection?,
    Padding: UDim?,
    SortOrder: Enum.SortOrder?,
    HorizontalAlignment: Enum.HorizontalAlignment?,
    VerticalAlignment: Enum.VerticalAlignment?,
}

type SpringOpts = { period: number?, damping: number? }

type ChildState = {
    current:  Vector2,
    target:   Vector2,
    velocity: Vector2,
    initialized: boolean,
}

local EPSILON = 0.05

local function smoothLayout(opts: Opts?, springOpts: SpringOpts?)
    opts = opts or {}
    local fill    = opts.FillDirection or Enum.FillDirection.Vertical
    local padding = opts.Padding or UDim.new(0, 0)
    local sort    = opts.SortOrder or Enum.SortOrder.LayoutOrder
    local hAlign  = opts.HorizontalAlignment or Enum.HorizontalAlignment.Left
    local vAlign  = opts.VerticalAlignment or Enum.VerticalAlignment.Top

    local period  = (springOpts and springOpts.period)  or 0.30
    local damping = (springOpts and springOpts.damping) or 1.0

    return action(function(parent: Instance)
        if not parent:IsA("GuiObject") and not parent:IsA("ScrollingFrame") then
            -- still works on any container; just informational
        end

        local states: { [GuiObject]: ChildState } = {}
        local order:  { GuiObject } = {}

        local function isLayoutChild(child: Instance): boolean
            return child:IsA("GuiObject") and child.Visible
        end

        local function sortChildren()
            order = {}
            for _, c in ipairs(parent:GetChildren()) do
                if isLayoutChild(c) then table.insert(order, c :: GuiObject) end
            end
            if sort == Enum.SortOrder.LayoutOrder then
                table.sort(order, function(a, b)
                    if a.LayoutOrder == b.LayoutOrder then return a.Name < b.Name end
                    return a.LayoutOrder < b.LayoutOrder
                end)
            else
                table.sort(order, function(a, b) return a.Name < b.Name end)
            end
        end

        local function paddingPixels(): number
            local containerSize = if fill == Enum.FillDirection.Vertical
                then parent.AbsoluteSize.Y
                else parent.AbsoluteSize.X
            return padding.Offset + padding.Scale * containerSize
        end

        local function recomputeTargets()
            sortChildren()

            -- total along axis (for alignment)
            local pad = paddingPixels()
            local total = 0
            for i, child in ipairs(order) do
                local s = child.AbsoluteSize
                total += if fill == Enum.FillDirection.Vertical then s.Y else s.X
                if i < #order then total += pad end
            end

            local containerSize = parent.AbsoluteSize
            local startX, startY = 0, 0
            if fill == Enum.FillDirection.Vertical then
                if vAlign == Enum.VerticalAlignment.Center then
                    startY = math.floor((containerSize.Y - total) / 2)
                elseif vAlign == Enum.VerticalAlignment.Bottom then
                    startY = containerSize.Y - total
                end
            else
                if hAlign == Enum.HorizontalAlignment.Center then
                    startX = math.floor((containerSize.X - total) / 2)
                elseif hAlign == Enum.HorizontalAlignment.Right then
                    startX = containerSize.X - total
                end
            end

            local cursor = if fill == Enum.FillDirection.Vertical then startY else startX
            for _, child in ipairs(order) do
                local size = child.AbsoluteSize
                local cross = 0
                if fill == Enum.FillDirection.Vertical then
                    if hAlign == Enum.HorizontalAlignment.Center then
                        cross = math.floor((containerSize.X - size.X) / 2)
                    elseif hAlign == Enum.HorizontalAlignment.Right then
                        cross = containerSize.X - size.X
                    end
                else
                    if vAlign == Enum.VerticalAlignment.Center then
                        cross = math.floor((containerSize.Y - size.Y) / 2)
                    elseif vAlign == Enum.VerticalAlignment.Bottom then
                        cross = containerSize.Y - size.Y
                    end
                end

                local target = if fill == Enum.FillDirection.Vertical
                    then Vector2.new(cross, cursor)
                    else Vector2.new(cursor, cross)

                local state = states[child]
                if not state then
                    states[child] = {
                        current = target,
                        target  = target,
                        velocity = Vector2.zero,
                        initialized = true,
                    }
                else
                    state.target = target
                end

                cursor += (if fill == Enum.FillDirection.Vertical then size.Y else size.X) + pad
            end

            -- cull entries for removed children
            for c in pairs(states) do
                if not table.find(order, c) then states[c] = nil end
            end
        end

        ----------------------------------------------------------------
        -- per-child connection management
        ----------------------------------------------------------------

        local childConns: { [Instance]: { RBXScriptConnection } } = {}

        local function watchChild(child: Instance)
            if childConns[child] then return end
            local list = {}
            childConns[child] = list
            if child:IsA("GuiObject") then
                table.insert(list, child:GetPropertyChangedSignal("LayoutOrder"):Connect(recomputeTargets))
                table.insert(list, child:GetPropertyChangedSignal("Size"):Connect(recomputeTargets))
                table.insert(list, child:GetPropertyChangedSignal("Visible"):Connect(recomputeTargets))
            end
        end

        local function unwatchChild(child: Instance)
            local list = childConns[child]
            if not list then return end
            for _, c in ipairs(list) do c:Disconnect() end
            childConns[child] = nil
        end

        for _, c in ipairs(parent:GetChildren()) do watchChild(c) end
        local addedConn   = parent.ChildAdded:Connect(function(c) watchChild(c); recomputeTargets() end)
        local removedConn = parent.ChildRemoved:Connect(function(c) unwatchChild(c); states[c :: any] = nil; recomputeTargets() end)
        local resizeConn  = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(recomputeTargets)

        recomputeTargets()

        ----------------------------------------------------------------
        -- shared heartbeat: integrate spring per child
        ----------------------------------------------------------------

        local hbConn = RunService.Heartbeat:Connect(function(dt)
            if dt > 0.1 then dt = 0.1 end
            local omega = 2 * math.pi / period
            for child, s in pairs(states) do
                if child.Parent ~= parent then continue end
                local dx = s.current - s.target
                local accel = -2 * damping * omega * s.velocity - omega * omega * dx
                s.velocity = s.velocity + accel * dt
                s.current  = s.current  + s.velocity * dt

                if math.abs(dx.X) < EPSILON and math.abs(dx.Y) < EPSILON
                   and math.abs(s.velocity.X) < EPSILON and math.abs(s.velocity.Y) < EPSILON then
                    s.current = s.target
                    s.velocity = Vector2.zero
                end

                child.Position = UDim2.fromOffset(
                    math.round(s.current.X),
                    math.round(s.current.Y)
                )
            end
        end)

        ----------------------------------------------------------------
        -- cleanup binding
        ----------------------------------------------------------------

        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                hbConn:Disconnect()
                addedConn:Disconnect()
                removedConn:Disconnect()
                resizeConn:Disconnect()
                for _, list in pairs(childConns) do
                    for _, c in ipairs(list) do c:Disconnect() end
                end
                table.clear(childConns)
                table.clear(states)
            end)
        end
    end, -50) -- run early so layout is set before children settle
end

return smoothLayout
