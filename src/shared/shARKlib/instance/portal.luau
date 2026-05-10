--!strict
local apply   = require(script.Parent.apply)
local Runtime = require(script.Parent.Parent.core.runtime)

local function portal(target: Instance, children: { any }): Instance
    -- a transparent invisible folder used purely as a logical anchor
    local anchor = Instance.new("Folder")
    anchor.Name = "PortalAnchor"
    apply.apply(target, { [apply.Children] = children })
    if Runtime.owner then
        table.insert(Runtime.owner.cleanups, function() anchor:Destroy() end)
    end
    return anchor
end

return portal

