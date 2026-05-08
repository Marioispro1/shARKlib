--!strict
--[[
    create.luau

        create(class)              -> (props) -> Instance
        create(class, templateName)-> (props) -> Instance
        create(existingInstance)   -> (props) -> Instance  (clones it)

    The two-arg form selects one of the named templates registered via
    `shARKlib.SetTemplate(name, ...)`. The library's built-in defaults
    and the unnamed user template are always layered first.

    Performance: a per-(class, templateName) clone source is built once
    and then `:Clone()`d for every call, so per-instance cost is just
    the clone plus the user-supplied prop pass.
]]

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
