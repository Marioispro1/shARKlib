--!strict
local Runtime = require(script.Parent.runtime)

export type Signal<T...> = {
    connect: (self: Signal<T...>, fn: (T...) -> ()) -> () -> (),
    once:    (self: Signal<T...>, fn: (T...) -> ()) -> () -> (),
    fire:    (self: Signal<T...>, T...) -> (),
    wait:    (self: Signal<T...>) -> T...,
    destroy: (self: Signal<T...>) -> (),
}

local function signal<T...>(): Signal<T...>
    local listeners: { (T...) -> () } = {}
    local self: any = {}

    function self:connect(fn)
        table.insert(listeners, fn)
        local function disconnect()
            for i = #listeners, 1, -1 do
                if listeners[i] == fn then
                    local n = #listeners
                    listeners[i] = listeners[n]
                    listeners[n] = nil
                    break
                end
            end
        end
        if Runtime.owner then
            table.insert(Runtime.owner.cleanups, disconnect)
        end
        return disconnect
    end

    function self:once(fn)
        local disconnect
        disconnect = self:connect(function(...)
            disconnect()
            fn(...)
        end)
        return disconnect
    end

    function self:fire(...)
        -- snapshot to allow connect/disconnect during fire
        local snapshot = table.clone(listeners)
        for i = 1, #snapshot do
            local ok, err = pcall(snapshot[i], ...)
            if not ok then Runtime.onError(err) end
        end
    end

    function self:wait()
        local thread = coroutine.running()
        local disconnect
        disconnect = self:connect(function(...)
            disconnect()
            task.spawn(thread, ...)
        end)
        return coroutine.yield()
    end

    function self:destroy()
        table.clear(listeners)
    end

    return self :: Signal<T...>
end

return signal
