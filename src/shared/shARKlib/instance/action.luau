--!strict
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
