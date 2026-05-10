--!strict
local derive = require(script.Parent.Parent.core.derive)
local Log = require(script.Parent.Parent.tooling.log)

local function combine(...): any
    local n = select("#", ...)
    if n < 2 then
        error(Log.message("data.combine", "validate", "requires at least one source and a combiner"), 2)
    end
    local fn = select(n, ...)
    if type(fn) ~= "function" then
        error(Log.message("data.combine", "validate", "last argument must be the combiner function"), 2)
    end
    local sources = { select(1, ...) }
    sources[n] = nil
    return derive(function()
        local args = table.create(n - 1)
        for i = 1, n - 1 do args[i] = sources[i]() end
        return fn(table.unpack(args, 1, n - 1))
    end)
end

return combine

