--!strict
--[[
    read.luau
    Resolve a value that may be either a plain value or a 0-arg getter
    (source / derive). Subscribes if it's a getter and we're in scope.
]]

local function read<T>(value: T | (() -> T)): T
    if type(value) == "function" then
        return (value :: any)()
    end
    return value :: T
end

return read
