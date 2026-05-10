--!strict
local Runtime = require(script.Parent.Parent.core.runtime)
local Graph   = require(script.Parent.Parent.core.graph)
local Log = require(script.Parent.log)

local Scheduler = {}

function Scheduler.setStrict(on: boolean)
    Runtime.strict = on
    local mode = if on then "on" else "off"
    Log.info("scheduler", "setStrict", ("strict set to %s"):format(Log.braced(mode)))
end

function Scheduler.setOnError(handler: (any) -> ())
    Runtime.onError = handler
    Log.info("scheduler", "setOnError", "error handler updated")
end

function Scheduler.flushSync()
    Graph.flush()
end

function Scheduler.setDevtools(hooks: any)
    Runtime.devtools = hooks
    local mode = if hooks ~= nil then "on" else "off"
    Log.info("scheduler", "setDevtools", ("devtools set to %s"):format(Log.braced(mode)))
end

return Scheduler

