--!strict
local Graph   = require(script.Parent.Parent.core.graph)
local Runtime = require(script.Parent.Parent.core.runtime)
local source  = require(script.Parent.Parent.core.source)
local untrack = require(script.Parent.Parent.core.untrack)

export type ResourceStatus = {
    loading: () -> boolean,
    error:   () -> any?,
    refetch: () -> (),
}

local function resource<T>(fetcher: () -> T): (() -> T?, ResourceStatus)
    local value   = source(nil :: T?)
    local loading = source(false)
    local err     = source(nil :: any?)

    local epoch = 0

    local function start()
        epoch += 1
        local mine = epoch
        loading(true)
        err(nil)
        task.spawn(function()
            local ok, result = pcall(fetcher)
            if mine ~= epoch then return end -- stale
            if ok then
                value(result)
                err(nil)
            else
                err(result)
            end
            loading(false)
        end)
    end

    -- re-run on dep changes
    local watcher = Graph.createNode(function()
        -- read all deps of `fetcher` for tracking, but actually invoke
        -- the work asynchronously
        fetcher() -- dependency read; result discarded here
        untrack(start)
        return nil
    end :: any, nil)
    Graph.run(watcher)

    local status: ResourceStatus = {
        loading = loading :: any,
        error   = err :: any,
        refetch = function() untrack(start) end,
    }

    return function() return value() end, status
end

return resource
