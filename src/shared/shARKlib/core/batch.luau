--!strict
--[[
    batch.luau
    Defer queue flushing until the outermost batch returns. Useful when
    writing several sources that would otherwise each trigger a flush.
]]

local Runtime = require(script.Parent.runtime)
local Graph   = require(script.Parent.graph)

local function batch<T>(fn: () -> T): T
    Runtime.batchDepth += 1
    local ok, result = pcall(fn)
    Runtime.batchDepth -= 1
    if Runtime.batchDepth == 0 then
        Graph.flush()
    end
    if not ok then error(result, 0) end
    return result
end

return batch
