/// Multi-threaded easy function invocation and Queue
module tern.concurrency;

public import std.concurrency;
import tern.traits;
import tern.typecons;

public:
/**
 * Asynchronously invokes `F` and awaits its return value.
 *
 * Params:
 *  F = Function to be invoked.
 *  args = Arguments to invoke `F` on.
 *
 * Returns:
 *  The return of `F`
 */
ReturnType!F await(alias F, ARGS...)(ARGS args)
    if (!is(ReturnType!F == void))
{
    void function(ARGS args) f = (ARGS args) { auto ret = F(args); send(ownerTid, ret); };
    spawn(f, args);
    return receiveOnly!(ReturnType!F);
}

/// ditto
ReturnType!F await(alias F, ARGS...)(ARGS args)
    if (isCallable!F && !__traits(compiles, is(ReturnType!F == void)))
{
    void function(ARGS args) f = (ARGS args) { auto ret = F(args); send(ownerTid, ret); };
    spawn(f, args);
    return receiveOnly!(typeof(F(args)));
}

/// ditto
bool await(alias F, ARGS...)(ARGS args)
    if (is(ReturnType!F == void))
{
    void function(ARGS args) f = (ARGS args) { F(args); send(ownerTid, true); };
    spawn(f, args);
    return receiveOnly!bool;
}

/**
 * Asynchronously invokes `F` and ignores any further actions from the spawn.
 *
 * Params:
 *  F = Function to be invoked.
 *  args = Arguments to invoke `F` on.
 */
void async(alias F, ARGS...)(ARGS args)
{
    void function(ARGS args) f = (ARGS args) { F(args); };
    spawn(f, args);
}

/// Thread-safe queue implementation with range capabilities
public struct Queue(T)
{
private:
final:
    shared Atomic!(T[]) queue;

public:
    void enqueue(T val) shared
    {
        queue ~= val;
    }

    T dequeue() shared
    {
        scope (exit) queue = queue[1..$];
        return queue[0];
    }

    size_t length() shared
    {
        return queue.length;
    }

    bool empty() shared
    {
        return queue.length == 0;
    }

    T front() shared
    {
        return queue.value[0];
    }

    T back() shared
    {
        return queue.value[$-1];
    }

    void popFront()
    {
        queue = queue[1..$];
    }

    void popBack()
    {
        queue = queue[0..$-1];
    }
}