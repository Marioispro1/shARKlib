--!strict
export type CleanupFn = () -> ()

export type Node = {
    fn: ((...any) -> any)?,           -- evaluation fn (effect / derive); nil for plain sources
    value: any,                       -- last cached value
    equals: ((any, any) -> boolean)?, -- equality predicate; true == skip propagation
    owner: Node?,                     -- parent scope, used for the cleanup tree
    sources: { Node },                -- nodes this node reads
    observers: { Node },              -- nodes that read this node
    children: { Node },               -- scopes created while this node was the owner
    cleanups: { CleanupFn },          -- callbacks run on re-evaluation / disposal
    handlers: { (any) -> () }?,       -- error handlers (errorboundary)
    context: { [any]: any }?,         -- scoped context map
    priority: number,                 -- update priority; lower runs first
    state: number,                    -- 0 clean, 1 dirty, 2 disposed
    name: string?,                    -- optional debug label
}

local Runtime = {}

Runtime.STATE_CLEAN    = 0
Runtime.STATE_DIRTY    = 1
Runtime.STATE_DISPOSED = 2

Runtime.PRIORITY_DEFAULT = 0
Runtime.PRIORITY_RENDER  = -10
Runtime.PRIORITY_LAYOUT  =  10

Runtime.current    = nil :: Node?  -- scope currently being evaluated (tracking target)
Runtime.owner      = nil :: Node?  -- current ownership scope (cleanup parent)
Runtime.untracked  = false         -- when true, reads do not subscribe
Runtime.batchDepth = 0             -- depth of nested batch() calls

Runtime.queue  = {} :: { Node }
Runtime.queued = {} :: { [Node]: true }

Runtime.onError = function(err: any)
    task.spawn(error, "[shARKlib] uncaught error: " .. tostring(err))
end

Runtime.strict   = false
Runtime.devtools = nil :: { onCreate: ((Node) -> ())?, onDispose: ((Node) -> ())?, onRun: ((Node) -> ())? }?

return Runtime

