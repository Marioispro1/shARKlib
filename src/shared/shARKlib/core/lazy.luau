--!strict
--[[
    lazy.luau
    Defer the construction of a component until the first time it is
    rendered. Useful for splitting initialization cost.
]]

local function lazy<T>(loader: () -> (() -> T)): () -> T
    local component: (() -> T)? = nil
    return function()
        if not component then
            component = loader()
        end
        return (component :: () -> T)()
    end
end

return lazy
