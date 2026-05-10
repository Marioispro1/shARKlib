--!strict
local Runtime = require(script.Parent.runtime)
local Log = require(script.Parent.Parent.tooling.log)

export type Context<T> = {
    read:    (self: Context<T>) -> T,
    provide: <R...>(self: Context<T>, value: T, fn: () -> R...) -> R...,
}

local function context<T>(default: T): Context<T>
    local key = {}
    local ctx = {} :: any

    function ctx:read(): T
        local cursor = Runtime.owner
        while cursor do
            local map = cursor.context
            if map and map[key] ~= nil then
                return map[key]
            end
            cursor = cursor.owner
        end
        return default
    end

    function ctx:provide<R...>(value: T, fn: () -> R...): R...
        local owner = Runtime.owner
        if not owner then
            error(Log.message("context", "provide", "requires a reactive scope"), 2)
        end
        local map = owner.context
        if not map then
            map = {}
            owner.context = map
        end
        local prev = map[key]
        map[key] = value
        local ok, a, b, c, d = pcall(fn)
        map[key] = prev
        if not ok then error(a, 0) end
        return a, b, c, d
    end

    return ctx :: Context<T>
end

return context

