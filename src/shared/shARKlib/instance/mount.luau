--!strict
local root = require(script.Parent.Parent.core.root)

local function mount(component: () -> (Instance | { Instance }), parent: Instance?): () -> ()
    local destroy
    root(function(d)
        destroy = d
        local result = component()
        if typeof(result) == "Instance" then
            result.Parent = parent
        elseif type(result) == "table" then
            for _, inst in ipairs(result) do
                if typeof(inst) == "Instance" then
                    inst.Parent = parent
                end
            end
        end
    end)
    return destroy
end

return mount

