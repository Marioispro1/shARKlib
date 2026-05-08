--!strict
--[[
    scheduler.luau
    Public hooks into the runtime scheduler:
      * setStrict(bool)    - re-run effects twice for debug
      * setOnError(fn)     - global uncaught error handler
      * flushSync()        - flush pending updates immediately
      * setDevtools(hooks) - register devtools observer
]]

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
