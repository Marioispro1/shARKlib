--!strict
local Runtime = require(script.Parent.runtime)
local Log = require(script.Parent.Parent.tooling.log)

type Node = Runtime.Node

local Graph = {}

local function defaultEquals(a: any, b: any): boolean
	return a == b
end

----------------------------------------------------------------------
-- node lifecycle
----------------------------------------------------------------------

function Graph.createNode(fn: ((...any) -> any)?, value: any, equals: ((any, any) -> boolean)?): Node
	local node: Node = {
		fn = fn,
		value = value,
		equals = equals or defaultEquals,
		owner = Runtime.owner,
		sources = {},
		observers = {},
		children = {},
		cleanups = {},
		handlers = nil,
		context = nil,
		priority = Runtime.PRIORITY_DEFAULT,
		state = if fn then Runtime.STATE_DIRTY else Runtime.STATE_CLEAN,
		name = nil,
	}
	if Runtime.owner then
		table.insert(Runtime.owner.children, node)
	end
	local dt = Runtime.devtools
	if dt and dt.onCreate then
		dt.onCreate(node)
	end
	return node
end

local function removeFromArray(t: { any }, v: any)
	for i = #t, 1, -1 do
		if t[i] == v then
			local n = #t
			t[i] = t[n]
			t[n] = nil
			return
		end
	end
end

local function clearSources(node: Node)
	local sources = node.sources
	for i = 1, #sources do
		removeFromArray(sources[i].observers, node)
	end
	table.clear(sources)
end

local function runCleanups(node: Node)
	local cleanups = node.cleanups
	for i = #cleanups, 1, -1 do
		local ok, err = pcall(cleanups[i])
		if not ok then
			Runtime.onError(err)
		end
	end
	table.clear(cleanups)
end

local disposeChildren -- forward decl

local function disposeNode(node: Node)
	if node.state == Runtime.STATE_DISPOSED then
		return
	end
	disposeChildren(node)
	runCleanups(node)
	clearSources(node)
	table.clear(node.observers)
	node.state = Runtime.STATE_DISPOSED
	node.fn = nil
	node.handlers = nil
	node.context = nil
	Runtime.queued[node] = nil
	local dt = Runtime.devtools
	if dt and dt.onDispose then
		dt.onDispose(node)
	end
end
Graph.dispose = disposeNode

function disposeChildren(node: Node)
	local children = node.children
	for i = #children, 1, -1 do
		disposeNode(children[i])
	end
	table.clear(children)
end
Graph.disposeChildren = disposeChildren

----------------------------------------------------------------------
-- reading / writing
----------------------------------------------------------------------

-- register a dependency from the current scope to `node`.
function Graph.track(node: Node)
	if node.state == Runtime.STATE_DISPOSED then
		return
	end
	local cur = Runtime.current
	if cur and not Runtime.untracked and cur.state ~= Runtime.STATE_DISPOSED then
		if not table.find(cur.sources, node) then
			table.insert(cur.sources, node)
			table.insert(node.observers, cur)
		end
	end
end

-- read a node's cached value, subscribing the active scope.
function Graph.read(node: Node): any
	Graph.track(node)
	return node.value
end

-- push `node` onto the pending queue (deduplicated).
local function enqueue(node: Node)
	if node.state == Runtime.STATE_DISPOSED then
		return
	end
	if Runtime.queued[node] then
		return
	end
	Runtime.queued[node] = true
	table.insert(Runtime.queue, node)
end

local flushQueue -- forward decl

-- re-evaluate a node's `fn`, capturing fresh dependencies, and
-- propagate the new value to observers if it changed.
function Graph.run(node: Node)
	if node.state == Runtime.STATE_DISPOSED then
		return
	end
	local fn = node.fn
	if not fn then
		return
	end

	disposeChildren(node)
	runCleanups(node)
	clearSources(node)

	local prevCurrent, prevOwner = Runtime.current, Runtime.owner
	Runtime.current = node
	Runtime.owner = node
	node.state = Runtime.STATE_CLEAN

	local ok, result = pcall(fn, node.value)

	Runtime.current = prevCurrent
	Runtime.owner = prevOwner

	local dt = Runtime.devtools
	if dt and dt.onRun then
		dt.onRun(node)
	end

	if not ok then
		Graph.throw(node, result)
		return
	end

	if Runtime.strict and node.fn then
		-- run a second time to surface side-effect bugs (results discarded)
		local prevC, prevO = Runtime.current, Runtime.owner
		Runtime.current = node
		Runtime.owner = node
		disposeChildren(node)
		runCleanups(node)
		clearSources(node)
		pcall(fn, node.value)
		Runtime.current = prevC
		Runtime.owner = prevO
	end

	local prevValue = node.value
	local equals = node.equals :: (any, any) -> boolean
	node.value = result
	if not equals(prevValue, result) then
		local observers = node.observers
		for i = 1, #observers do
			local obs = observers[i]
			if obs.state == Runtime.STATE_CLEAN then
				obs.state = Runtime.STATE_DIRTY
				enqueue(obs)
			end
		end
	end
end

-- write a value to a source node and propagate to observers.
function Graph.write(node: Node, value: any)
	if node.state == Runtime.STATE_DISPOSED then
		return value
	end
	local equals = node.equals :: (any, any) -> boolean
	if equals(node.value, value) then
		return value
	end
	node.value = value
	local observers = node.observers
	for i = 1, #observers do
		local obs = observers[i]
		if obs.state == Runtime.STATE_CLEAN then
			obs.state = Runtime.STATE_DIRTY
			enqueue(obs)
		end
	end
	if Runtime.batchDepth == 0 then
		flushQueue()
	end
	return value
end

----------------------------------------------------------------------
-- error propagation (used by errorboundary)
----------------------------------------------------------------------

function Graph.throw(node: Node, err: any)
	local cursor: Node? = node
	while cursor do
		local h = cursor.handlers
		if h and #h > 0 then
			for i = 1, #h do
				local ok, e = pcall(h[i], err)
				if ok then
					return
				end
				err = e
			end
		end
		cursor = cursor.owner
	end
	Runtime.onError(err)
end

----------------------------------------------------------------------
-- queue flushing
----------------------------------------------------------------------

local function priorityCmp(a: Node, b: Node): boolean
	return a.priority < b.priority
end

function flushQueue()
	-- drain runtime.queue iteratively. running a node may enqueue more
	-- observers, so we re-fetch runtime.queue each pass and replace it
	-- with a fresh table before processing the current batch.
	local queued = Runtime.queued
	local guard = 0
	while #Runtime.queue > 0 do
		local batch = Runtime.queue
		Runtime.queue = {}
		table.sort(batch, priorityCmp)
		for i = 1, #batch do
			local node = batch[i]
			queued[node] = nil
			if node.state == Runtime.STATE_DIRTY then
				Graph.run(node)
			end
		end
		guard += 1
		if guard > 1000 then
			-- safety net for circular reactive dependencies
			table.clear(Runtime.queue)
			table.clear(queued)
			error(Log.message("graph", "flushQueue", "aborted after 1000 passes (cycle?)"), 0)
		end
	end
end
Graph.flush = flushQueue

return Graph
