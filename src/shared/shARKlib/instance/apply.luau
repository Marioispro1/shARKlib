--!strict
local Runtime = require(script.Parent.Parent.core.runtime)
local Graph = require(script.Parent.Parent.core.graph)
local Log = require(script.Parent.Parent.tooling.log)

local Children = newproxy(false) -- exported sentinel
local CHILDREN_KEY = Children

local function isAction(v: any): boolean
	return type(v) == "table" and v.__sparkAction == true
end

local function bindProperty(instance: Instance, key: string, value: any)
	if type(value) == "function" then
		-- reactive property: re-assign when any read source changes
		local node = Graph.createNode(function()
			local ok, v = pcall(value)
			if ok then
				(instance :: any)[key] = v
			else
				Graph.throw(Runtime.current :: any, v)
			end
			return nil
		end, nil)
		Graph.run(node)
	else
		(instance :: any)[key] = value
	end
end

local function bindEvent(_instance: Instance, signal: RBXScriptSignal, handler: any)
	if type(handler) ~= "function" then
		error(Log.message("instance.apply", "bindEvent", "event handler must be a function"), 3)
	end
	local conn = signal:Connect(handler)
	if Runtime.owner then
		table.insert(Runtime.owner.cleanups, function()
			conn:Disconnect()
		end)
	end
end

local addChild -- forward decl
local function addChildren(parent: Instance, list: { any })
	for i = 1, #list do
		addChild(parent, list[i])
	end
end

function addChild(parent: Instance, child: any)
	local t = type(child)
	if t == "nil" then
		return
	elseif t == "table" then
		if (child :: any).__sparkAction then
			-- actions in child position attach to the parent
			(child :: any).run(parent)
		else
			addChildren(parent, child :: { any })
		end
	elseif t == "function" then
		-- dynamic child: a getter returning instance | {instance} | nil.
		-- re-evaluates and re-parents on every change, cleaning up the
		-- previous result.
		local last: { Instance } = {}
		local node = Graph.createNode(function()
			local ok, value = pcall(child)
			if not ok then
				return nil
			end

			-- build the next set of instances (preserving order).
			local nextList: { Instance } = {}
			if typeof(value) == "Instance" then
				table.insert(nextList, value)
			elseif type(value) == "table" then
				for _, inst in ipairs(value) do
					if typeof(inst) == "Instance" then
						table.insert(nextList, inst)
					end
				end
			end

			-- diff: only unparent instances that are gone from `next`.
			-- this keeps existing children attached so observers like
			-- smoothlayout don't see spurious childremoved/childadded.
			local nextSet: { [Instance]: true } = {}
			for _, inst in ipairs(nextList) do
				nextSet[inst] = true
			end
			for i = #last, 1, -1 do
				local inst = last[i]
				if not nextSet[inst] and inst.Parent == parent then
					inst.Parent = nil
				end
			end

			-- parent any new ones; existing ones already have correct
			-- parent so we leave them be (this avoids the property
			-- write-back which would also fire signals).
			for _, inst in ipairs(nextList) do
				if inst.Parent ~= parent then
					inst.Parent = parent
				end
			end

			last = nextList
			return nil
		end, nil)
		Graph.run(node)
		if Runtime.owner then
			table.insert(Runtime.owner.cleanups, function()
				for i = #last, 1, -1 do
					if last[i].Parent then
						last[i].Parent = nil
					end
				end
			end)
		end
	elseif typeof(child) == "Instance" then
		child.Parent = parent
	else
		error(Log.message("instance.apply", "addChild", "invalid child of type " .. typeof(child)), 3)
	end
end

local function apply(instance: Instance, props: { [any]: any }): Instance
	-- collect actions to defer until properties/children are set
	local actions: { any }? = nil

	-- 1) properties + events (children handled in pass 2)
	for key, value in pairs(props) do
		if type(key) == "string" then
			local existing = (instance :: any)[key]
			if typeof(existing) == "RBXScriptSignal" then
				bindEvent(instance, existing, value)
			else
				bindProperty(instance, key, value)
			end
		elseif typeof(key) == "RBXScriptSignal" then
			bindEvent(instance, key, value)
		end
		-- numeric keys and children_key fall through to pass 2
	end

	-- 2) children (numeric keys + children sentinel)
	for _, value in ipairs(props) do
		if isAction(value) then
			actions = actions or {}
			table.insert(actions, value)
		else
			addChild(instance, value)
		end
	end
	local kids = props[CHILDREN_KEY]
	if kids ~= nil then
		addChild(instance, kids)
	end

	-- 3) actions
	if actions then
		table.sort(actions, function(a, b)
			return a.priority < b.priority
		end)
		for _, a in ipairs(actions) do
			a.run(instance)
		end
	end

	return instance
end

local M = {}
M.apply = apply
M.Children = Children
return M
