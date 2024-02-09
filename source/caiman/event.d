module caiman.event;

import caiman.traits;
import std.array;

public struct Event
{
public:
final:
    void* fn;
    debug string signature;

    auto subscribe(void* fn) => this ~= fn;
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