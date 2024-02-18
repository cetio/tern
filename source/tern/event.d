/// Event subscription management
module tern.event;

import tern.traits;
import std.array;

/// Event subscription manager for arbitrary function pointers
public struct Event
{
public:
final:
    /// Current function pointer subscribed
    void* fn;
    /// Debug only signature string
    debug string signature;

    /**
     * Subscribes `fn` to this event, making it be called when `invoke` is called.
     *
     * Params:
     *  fn = Function to be subscribed.
     */
    auto subscribe(void* fn) => this ~= fn;
    /**
     * Unsubscribes `fn` to this event, making it be called when `invoke` is called.
     *
     * Params:
     *  fn = Function to be unsubscribed.
     */
    auto unsubscribe(void* fn) => this -= fn;

    auto opOpAssign(string op, T : U*, U)(T val)
        if (op == "~")
    {
        debug
        {
            signature = typeof(val).stringof.replace(" function", "");
        }
        fn = cast(void*)val;
        return this;
    }

    auto opOpAssign(string op, T : U*, U)(T val)
        if (op == "-")
    {
        if (cast(void*)val == fn)
            fn = null;
        else
            throw new Throwable("Tried to unset function in event that was not previously set!");

        return this;
    }

    auto invoke(T = void, ARGS...)(ARGS args)
    {
        if (fn == null)
            throw new Throwable("No subscriptions set on event!");

        return (cast(T function(ARGS))fn)(args);
    }

    auto opCall(ARGS...)(ARGS args)
    {
        if (fn == null)
            throw new Throwable("No subscriptions set on event!");

        return (cast(void function(ARGS))fn)(args);
    }
}