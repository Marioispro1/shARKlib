--!strict
local Runtime = require(script.Parent.Parent.core.runtime)
local Graph   = require(script.Parent.Parent.core.graph)

local Scheduler = {}

function Scheduler.setStrict(on: boolean)
    Runtime.strict = on
end

function Scheduler.setOnError(handler: (any) -> ())
    Runtime.onError = handler
end

function Scheduler.flushSync()
    Graph.flush()
end

function Scheduler.setDevtools(hooks: any)
    Runtime.devtools = hooks
end

return Scheduler

