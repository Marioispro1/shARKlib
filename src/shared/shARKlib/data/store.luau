--!strict
local Graph   = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)

type Node = Runtime.Node

local function makeStore<T>(initial: T)
    local pathNodes: { [string]: Node } = {}

    local function nodeFor(pathKey: string, value: any): Node
        local n = pathNodes[pathKey]
        if not n then
            n = Graph.createNode(nil, value)
            n.name = "store:" .. pathKey
            pathNodes[pathKey] = n
        end
        return n
    end

    local proxyMt: any = nil
    local function wrap(value: any, path: string): any
        if type(value) ~= "table" then return value end
        return setmetatable({ __path = path, __raw = value }, proxyMt)
    end

    proxyMt = {
        __index = function(self, key)
            local raw = rawget(self, "__raw")
            local path = rawget(self, "__path") .. "." .. tostring(key)
            local v = raw[key]
            local node = nodeFor(path, v)
            -- subscribe; node.value tracks raw[key]
            node.value = v
            Graph.track(node)
            return wrap(v, path)
        end,
        __newindex = function()
            error("[shARKlib] store proxies are read-only; use store:set", 2)
        end,
        __iter = function(self)
            local raw = rawget(self, "__raw")
            local path = rawget(self, "__path")
            local k
            return function()
                local v
                k, v = next(raw, k)
                if k == nil then return nil end
                return k, wrap(v, path .. "." .. tostring(k))
            end
        end,
        __len = function(self) return #rawget(self, "__raw") end,
    }

    local rootValue: any = initial
    local rootProxy = wrap(rootValue, "$")

    local store: any = {}

    function store:get(): T
        return rootValue
    end

    function store:set(path: { any } | string, value: any)
        if type(path) == "string" then
            path = string.split(path, ".")
        end
        local cursor = rootValue
        local key = "$"
        for i = 1, #path - 1 do
            local p = path[i]
            cursor = cursor[p]
            key = key .. "." .. tostring(p)
            if type(cursor) ~= "table" then
                error("[shARKlib] store:set path traverses non-table", 2)
            end
        end
        local last = path[#path]
        local fullKey = key .. "." .. tostring(last)
        local prev = cursor[last]
        if prev == value then return end
        cursor[last] = value
        local node = pathNodes[fullKey]
        if node then
            Graph.write(node, value)
        end
    end

    function store:read()
        return rootProxy
    end

    setmetatable(store, { __index = function(_, k) return (rootProxy :: any)[k] end })

    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function()
            for _, n in pairs(pathNodes) do Graph.dispose(n) end
            table.clear(pathNodes)
        end)
    end

    return store
end

return makeStore

