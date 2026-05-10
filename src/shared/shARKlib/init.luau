--!strict
local apply = require(script.instance.apply)
local Templates = require(script.instance.templates)

local M = {}

----------------------------------------------------------------------
-- bootstrap
----------------------------------------------------------------------

-- settemplate(map)        merges into the unnamed (default) template
-- settemplate(name, map)  merges into a named template
function M.SetTemplate(arg1: any, arg2: any?)
	Templates.set(arg1, arg2)
end

-- finalize templates and unlock the rest of the api.
function M.Init()
	Templates.init()
end

local function requireInit()
	if not Templates.isInitialized() then
		error("[shARKlib] call shARKlib.Init() before using this API", 3)
	end
end

----------------------------------------------------------------------
-- module map: where each public name lives
----------------------------------------------------------------------

local moduleMap: { [string]: { string } } = {
	-- core
	source = { "core", "source" },
	derive = { "core", "derive" },
	effect = { "core", "effect" },
	root = { "core", "root" },
	cleanup = { "core", "cleanup" },
	untrack = { "core", "untrack" },
	batch = { "core", "batch" },
	context = { "core", "context" },
	read = { "core", "read" },
	errorBoundary = { "core", "errorBoundary" },
	lazy = { "core", "lazy" },
	watch = { "core", "watch" },
	signal = { "core", "signal" },

	-- instance authoring
	create = { "instance", "create" },
	mount = { "instance", "mount" },
	action = { "instance", "action" },
	changed = { "instance", "changed" },
	portal = { "instance", "portal" },
	tag = { "instance", "tag" },
	smoothLayout = { "instance", "smoothLayout" },
	onMount = { "instance", "onMount" },
	onEvent = { "instance", "onEvent" },
	ref = { "instance", "ref" },
	keybind = { "instance", "keybind" },
	hover = { "instance", "hover" },
	pressed = { "instance", "pressed" },
	drag = { "instance", "drag" },
	screenSize = { "instance", "screenSize" },
	fade = { "instance", "fade" },

	-- control flow
	show = { "flow", "show" },
	switch = { "flow", "switch" },
	match = { "flow", "match" },
	indexes = { "flow", "indexes" },
	values = { "flow", "values" },

	-- animation
	spring = { "animation", "spring" },
	tween = { "animation", "tween" },

	-- data
	resource = { "data", "resource" },
	store = { "data", "store" },
	selector = { "data", "selector" },
	debounce = { "data", "debounce" },
	throttle = { "data", "throttle" },
	combine = { "data", "combine" },
	mapList = { "data", "mapList" },
}

local cached: { [string]: any } = {}
local function lazyLoad(name: string): any
	local hit = cached[name]
	if hit then
		return hit
	end
	local path = moduleMap[name]
	if not path then
		error("[shARKlib] no module named " .. name, 2)
	end
	local mod = require(script[path[1]][path[2]])
	cached[name] = mod
	return mod
end

local function wrap(name: string)
	return function(...)
		requireInit()
		return lazyLoad(name)(...)
	end
end

----------------------------------------------------------------------
-- public surface
----------------------------------------------------------------------

-- core
M.source = wrap("source")
M.derive = wrap("derive")
M.effect = wrap("effect")
M.root = wrap("root")
M.cleanup = wrap("cleanup")
M.untrack = wrap("untrack")
M.batch = wrap("batch")
M.context = wrap("context")
M.read = wrap("read")
M.errorBoundary = wrap("errorBoundary")
M.lazy = wrap("lazy")
M.watch = wrap("watch")
M.signal = wrap("signal")

-- instance authoring
M.create = wrap("create")
M.mount = wrap("mount")
M.action = wrap("action")
M.changed = wrap("changed")
M.portal = wrap("portal")
M.tag = wrap("tag")
M.smoothLayout = wrap("smoothLayout")
M.onMount = wrap("onMount")
M.onEvent = wrap("onEvent")
M.ref = wrap("ref")
M.keybind = wrap("keybind")
M.hover = wrap("hover")
M.pressed = wrap("pressed")
M.drag = wrap("drag")
M.screenSize = wrap("screenSize")
M.fade = wrap("fade")
M.apply = function(...)
	requireInit()
	return apply.apply(...)
end
M.Children = apply.Children -- safe to expose pre-init

-- control flow
M.show = wrap("show")
M.switch = wrap("switch")
M.match = wrap("match")
M.indexes = wrap("indexes")
M.values = wrap("values")

-- animation
M.spring = wrap("spring")
M.tween = wrap("tween")

-- data
M.resource = wrap("resource")
M.store = wrap("store")
M.selector = wrap("selector")
M.debounce = wrap("debounce")
M.throttle = wrap("throttle")
M.combine = wrap("combine")
M.mapList = wrap("mapList")

-- tooling: each method individually init-gated
M.scheduler = setmetatable({}, {
	__index = function(_, k)
		return function(...)
			requireInit()
			return require(script.tooling.scheduler)[k](...)
		end
	end,
})

return M

