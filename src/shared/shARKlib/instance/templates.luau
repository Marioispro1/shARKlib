--!strict
local builtin = require(script.Parent.defaults)
local Log = require(script.Parent.Parent.tooling.log)

local Templates = {}

-- props for the unnamed (default) template, per class
Templates.default = {} :: { [string]: { [string]: any } }

-- props for named templates, per class -> name -> props
Templates.named = {} :: { [string]: { [string]: { [string]: any } } }

-- compiled clone sources, keyed by `class .. "::" .. name` (or class for default)
Templates.cache = {} :: { [string]: Instance }

Templates.initialized = false

local function mergeInto(dst: { [string]: any }, src: { [string]: any })
    for k, v in pairs(src) do dst[k] = v end
end

local function clearCache()
    for _, instance in pairs(Templates.cache) do instance:Destroy() end
    table.clear(Templates.cache)
end

-- public: settemplate(map) or settemplate(name, map).
-- `map` is `{ [classname] = propstable }`. subsequent calls merge
-- on top of any previous templates of the same name.
function Templates.set(arg1: any, arg2: any?)
    if Templates.initialized then
        error(Log.message("templates", "set", "SetTemplate cannot be called after Init()"), 3)
    end

    local name: string?, map: { [string]: { [string]: any } }
    if type(arg1) == "string" then
        name = arg1
        map = arg2 :: any
        if type(map) ~= "table" then
            error(Log.message("templates", "set", "SetTemplate(name, map) expects a table as second arg"), 3)
        end
    else
        name = nil
        map = arg1 :: any
        if type(map) ~= "table" then
            error(Log.message("templates", "set", "SetTemplate(map) expects a table"), 3)
        end
    end

    if name == nil then
        for class, props in pairs(map) do
            local existing = Templates.default[class]
            if existing then mergeInto(existing, props) else
                Templates.default[class] = table.clone(props)
            end
        end
    else
        for class, props in pairs(map) do
            local byClass = Templates.named[class]
            if not byClass then
                byClass = {}
                Templates.named[class] = byClass
            end
            local existing = byClass[name]
            if existing then mergeInto(existing, props) else
                byClass[name] = table.clone(props)
            end
        end
    end

    -- mutating templates after init is forbidden, so we don't need to
    -- invalidate the cache here; if init has not yet been called the
    -- cache is empty anyway.
    clearCache()
end

-- build (and cache) a fresh "template" instance for `class`/`name`.
-- the instance has built-in defaults + user default template + named
-- template applied. `create()` clones it then layers per-call props.
function Templates.resolve(class: string, name: string?): Instance
    local key = if name then class .. "::" .. name else class
    local cached = Templates.cache[key]
    if cached then return cached end

    local ok, instance = pcall(Instance.new, class)
    if not ok then
        error(Log.message("templates", "resolve", "cannot create instance of class " .. class), 3)
    end

    local b = builtin[class]
    if b then for k, v in pairs(b) do (instance :: any)[k] = v end end

    local d = Templates.default[class]
    if d then for k, v in pairs(d) do (instance :: any)[k] = v end end

    if name then
        local byClass = Templates.named[class]
        local n = byClass and byClass[name]
        if not n then
            error(Log.message("templates", "resolve", ("no template '%s' for class '%s'"):format(name, class)), 3)
        end
        for k, v in pairs(n) do (instance :: any)[k] = v end
    end

    Templates.cache[key] = instance
    return instance
end

-- pre-warm the cache for every (class, name?) registered.
function Templates.init()
    if Templates.initialized then
        Log.warn("templates", "init", "Init() called twice; ignoring")
        return
    end
    Templates.initialized = true

    for class in pairs(Templates.default) do
        pcall(Templates.resolve, class, nil)
    end
    for class, byName in pairs(Templates.named) do
        pcall(Templates.resolve, class, nil) -- ensure default exists too
        for name in pairs(byName) do
            pcall(Templates.resolve, class, name)
        end
    end
end

function Templates.isInitialized(): boolean
    return Templates.initialized
end

return Templates

