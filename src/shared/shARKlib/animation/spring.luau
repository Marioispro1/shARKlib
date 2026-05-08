--!strict
--[[
    spring.luau
    Animated source driven by a critically-/under-damped harmonic
    oscillator. Accepts a target source and returns a source that
    smoothly tracks it. Supports number, Vector2, Vector3, Color3,
    UDim, and UDim2 via component-wise integration.

    Optimization: a single shared RunService heartbeat drives every
    active spring, avoiding per-spring connections and allocations.
]]

local RunService = game:GetService("RunService")

local Graph = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source = require(script.Parent.Parent.core.source)

----------------------------------------------------------------------
-- value <-> component vector helpers
----------------------------------------------------------------------

local function decompose(v: any): ({ number }, string)
	local t = typeof(v)
	if t == "number" then
		return { v }, "number"
	end
	if t == "Vector2" then
		return { v.X, v.Y }, "Vector2"
	end
	if t == "Vector3" then
		return { v.X, v.Y, v.Z }, "Vector3"
	end
	if t == "Color3" then
		return { v.R, v.G, v.B }, "Color3"
	end
	if t == "UDim" then
		return { v.Scale, v.Offset }, "UDim"
	end
	if t == "UDim2" then
		return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }, "UDim2"
	end
	error("[shARKlib] spring: unsupported value type " .. t, 3)
end

local function recompose(parts: { number }, kind: string): any
	if kind == "number" then
		return parts[1]
	end
	if kind == "Vector2" then
		return Vector2.new(parts[1], parts[2])
	end
	if kind == "Vector3" then
		return Vector3.new(parts[1], parts[2], parts[3])
	end
	if kind == "Color3" then
		return Color3.new(math.clamp(parts[1], 0, 1), math.clamp(parts[2], 0, 1), math.clamp(parts[3], 0, 1))
	end
	if kind == "UDim" then
		return UDim.new(parts[1], parts[2])
	end
	if kind == "UDim2" then
		return UDim2.new(parts[1], parts[2], parts[3], parts[4])
	end
	error("unreachable")
end

----------------------------------------------------------------------
-- shared driver
----------------------------------------------------------------------

type Entry = {
	target: { number },
	position: { number },
	velocity: { number },
	period: number,
	damping: number,
	kind: string,
	output: any, -- source setter
	alive: boolean,
}

local active: { Entry } = {}
local connection: RBXScriptConnection? = nil

local EPSILON = 1e-4

local function step(dt: number)
	if dt > 0.1 then
		dt = 0.1
	end -- clamp to avoid blowups on hitches
	for i = #active, 1, -1 do
		local e = active[i]
		if not e.alive then
			local last = #active
			active[i] = active[last]
			active[last] = nil
		else
			local omega = 2 * math.pi / e.period
			local zeta = e.damping
			local stable = true
			for c = 1, #e.position do
				local x = e.position[c]
				local v = e.velocity[c]
				local dx = x - e.target[c]

				-- semi-implicit Euler with analytic spring force
				local accel = -2 * zeta * omega * v - omega * omega * dx
				v = v + accel * dt
				x = x + v * dt

				e.position[c] = x
				e.velocity[c] = v
				if math.abs(dx) > EPSILON or math.abs(v) > EPSILON then
					stable = false
				end
			end
			if stable then
				e.position = { table.unpack(e.target) }
				for c = 1, #e.velocity do
					e.velocity[c] = 0
				end
				e.alive = false
			end
			e.output(recompose(e.position, e.kind))
		end
	end
	if #active == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureDriver()
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

----------------------------------------------------------------------
-- public api
----------------------------------------------------------------------

local function spring<T>(target: () -> T, period: number?, damping: number?): () -> T
	period = period or 0.4
	damping = damping or 1

	local initial = target()
	local parts, kind = decompose(initial)
	local out = source(initial)

	local entry: Entry = {
		target = parts,
		position = { table.unpack(parts) },
		velocity = table.create(#parts, 0),
		period = period :: number,
		damping = damping :: number,
		kind = kind,
		output = out,
		alive = false,
	}

	-- track changes to the target source
	local watcher = Graph.createNode(
		function()
			local newTarget = target()
			local newParts = decompose(newTarget)
			entry.target = newParts
			entry.alive = true
			ensureDriver()
			if not table.find(active, entry) then
				table.insert(active, entry)
			end
			return nil
		end :: any,
		nil
	)
	Graph.run(watcher)

	if Runtime.owner then
		table.insert(Runtime.owner.cleanups, function()
			entry.alive = false
		end)
	end

	return out
end

return spring
