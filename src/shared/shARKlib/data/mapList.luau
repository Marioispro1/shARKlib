--!strict
local derive = require(script.Parent.Parent.core.derive)

local function mapList<T, R>(list: () -> { T }, fn: (T, number) -> R): () -> { R }
    local cache: { [any]: R } = {}
    return derive(function()
        local arr = list() or {}
        local out = table.create(#arr)
        local seen: { [any]: true } = {}
        for i, item in ipairs(arr) do
            seen[item] = true
            local cached = cache[item]
            if cached == nil then
                cached = fn(item, i)
                cache[item] = cached
            end
            out[i] = cached
        end
        for k in pairs(cache) do
            if not seen[k] then cache[k] = nil end
        end
        return out
    end)
end

return mapList

