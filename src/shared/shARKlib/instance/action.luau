--!strict
--[[
    action.luau
    Wrap a callback so it runs against an instance after it has been
    populated by `create`/`apply`. Multiple actions can target the same
    instance (priority orders them: lower runs first).
]]

export type Action = {
    __sparkAction: true,
    priority: number,
    run: (Instance) -> (),
}

local function action(fn: (Instance) -> (), priority: number?): Action
    return {
        __sparkAction = true,
        priority = priority or 0,
        run = fn,
    }
end

return action
