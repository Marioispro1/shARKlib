--!strict
--[[
    tag.luau
    Returns an action that adds a CollectionService tag to an instance,
    cleaning it up on disposal.
]]

local CollectionService = game:GetService("CollectionService")
local action  = require(script.Parent.action)
local Runtime = require(script.Parent.Parent.core.runtime)

local function tag(name: string)
    return action(function(instance: Instance)
        CollectionService:AddTag(instance, name)
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, function()
                if instance.Parent then
                    CollectionService:RemoveTag(instance, name)
                end
            end)
        end
    end)
end

return tag
