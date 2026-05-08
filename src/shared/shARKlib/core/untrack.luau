--!strict
--[[
    untrack.luau
    Run `fn` without subscribing to any source it reads.
]]

local Runtime = require(script.Parent.runtime)

local function untrack<T>(fn: () -> T): T
    local prev = Runtime.untracked
    Runtime.untracked = true
    local ok, result = pcall(fn)
    Runtime.untracked = prev
    if not ok then error(result, 0) end
    return result
end

return untrack
