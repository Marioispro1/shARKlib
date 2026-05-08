--!strict
local apply     = require(script.Parent.apply)
local Templates = require(script.Parent.templates)

type Props = { [any]: any }

local function create(target: string | Instance, templateName: string?): (Props) -> Instance
    if typeof(target) == "Instance" then
        local source = target
        return function(props: Props): Instance
            return apply.apply(source:Clone(), props)
        end
    elseif type(target) == "string" then
        local class = target
        local name = templateName
        return function(props: Props): Instance
            local source = Templates.resolve(class, name)
            return apply.apply(source:Clone(), props)
        end
    end
    error("[shARKlib] create() expects a class name or Instance", 2)
end

return create
