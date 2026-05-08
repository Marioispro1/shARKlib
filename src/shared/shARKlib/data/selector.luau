--!strict
local Graph   = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source  = require(script.Parent.Parent.core.source)
local effect  = require(script.Parent.Parent.core.effect)

local function selector<K>(input: () -> K)
    local sources: { [K]: any } = {}
    local prev: K? = nil

    -- one effect that reroutes the boolean signals as `input` changes
    effect(function()
        local current = input()
        if current == prev then return end
        local prevSource = prev ~= nil and sources[prev :: K]
        local currSource = current ~= nil and sources[current]
        if prevSource then prevSource(false) end
        if currSource then currSource(true) end
        prev = current
    end)

    return function(key: K): () -> boolean
        local s = sources[key]
        if not s then
            s = source(prev == key)
            sources[key] = s
        end
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                sources[key] = nil
            end)
        end
        return s
    end
end

return selector
