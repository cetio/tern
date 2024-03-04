module tern.concurrency;

import tern.functional : barter;
import tern.object : loadLength;
import tern.traits;
import std.parallelism;
import std.concurrency;
import std.range : iota;

public:
/**
 * Asynchronously invokes `F` and awaits its return value.
 *
 * Params:
 *  F = Function to be invoked.
 *  args = Arguments to invoke `F` on.
 *
 * Returns:
 *  The return of `F`.
 */
auto await(alias F, ARGS...)(ARGS args)
    if (!isNoReturn!F)
{
    void function(ARGS args) f = (ARGS args) { auto ret = F(args); send(ownerTid, ret); };
    spawn(f, args);
    return receiveOnly!(ReturnType!F);
}

/// ditto
auto await(alias F, ARGS...)(ARGS args)
    if (isCallable!F && !__traits(compiles, isNoReturn!F))
{
    void function(ARGS args) f = (ARGS args) { auto ret = F(args); send(ownerTid, ret); };
    spawn(f, args);
    return receiveOnly!(typeof(F(args)));
}

/// ditto
bool await(alias F, ARGS...)(ARGS args)
    if (isNoReturn!F)
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

/**
 * Spins up a group of `WORKERS` to run `F` on the given `args`.
 *
 * Params:
 *  WORKERS = The number of workers to delegate the task to.
 *  F = The function to be invoked.
 *  args = Arguments to invoke `F` on.
 */
void spinGroup(size_t WORKERS, alias F, ARGS...)(ARGS args)
{
    enum range = iota(0, WORKERS);
    foreach (worker; parallel(range))
        F(args, worker);
}

/**
 * Spins up a group to iterate across all elements in `range` on.
 *
 * Params:
 *  F = The function to be invoked.
 *  range = The range to iterate across.
 */
void parallelForeach(alias F, T)(auto ref T range)
{
    immutable size_t chunk = range.loadLength / ((range.loadLength / 4) | 1);
    spinGroup!(4, (size_t worker) {
        size_t index = worker * chunk;
        size_t len = index + chunk;
        if (len >= range.loadLength)
        {
            if (len - chunk >= range.loadLength)
                return;
            size_t rem = range.loadLength % chunk;
            len -= rem != 0 ? chunk - rem : 0;
        }
        
        foreach (i; index..len)
            barter!F(i, range[i]);
    })();
}

/// ditto
void parallelForeachReverse(alias F, T)(auto ref T range)
{
    immutable size_t chunk = range.loadLength / ((range.loadLength / 4) | 1);
    spinGroup!(4, (size_t worker) {
        size_t index = worker * chunk;
        size_t len = index + chunk;
        if (len >= range.loadLength)
        {
            if (len - chunk >= range.loadLength)
                return;
            size_t rem = range.loadLength % chunk;
            len -= rem != 0 ? chunk - rem : 0;
        }
        
        foreach_reverse (i; index..len)
            barter!F(i, range[i]);
    })();
}

/**
 * Spins up a group to iterate from `start` to `end` with increments of `step`.
 *
 * Params:
 *  F = The function to be invoked.
 *  start = The starting value.
 *  end = The ending value.
 *  step = The increment.
 */
void parallelFor(alias F)(ptrdiff_t start, ptrdiff_t end, ptrdiff_t step)
{
    ptrdiff_t cycles = end - start < 0 ? -(end - start) : end - start;
    immutable size_t chunk = cycles / ((cycles / (4 * step)) | 1);
    spinGroup!(4, (size_t worker) {
        size_t index = worker * chunk;
        size_t len = index + chunk;
        if (len >= cycles)
        {
            if (len - chunk >= cycles)
                return;
            size_t rem = cycles % chunk;
            len -= rem != 0 ? chunk - rem - 1 : 0;
        }
        
        foreach (i; index..len)
            barter!F(i);
    })();
}

/**
 * Spins up a group to call `F` while `W`.
 *
 * Params:
 *  W = The conditional function.
 *  F = The function to be invoked.
 */
void parallelWhile(alias W, alias F)()
{
    size_t index;
    spinGroup!(4, (size_t worker) {
        if (!barter!W(index, worker))
            return;

        barter!F(index++);
    })();
}