/// General-purpose functional programming oriented functions.
module tern.functional;

import tern.traits;
import tern.blit;
import tern.lambda;
import tern.meta;
import tern.concurrency;
import std.typecons;
import std.parallelism;

public:
/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto plane(alias C, A, B)(auto ref A range, B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {
        if (range[i] != elem)
        {
            if (++i >= range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto plane(alias C, A, B)(auto ref A range, B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {   
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (++i + subrange.loadLength > range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            ret = barter!C(i, slice);
            if (++i + subrange.loadLength > range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, slice);
            if (++i + subrange.loadLength > range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto plane(alias C, alias F, T)(auto ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!T, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {
        if (!barter!F(i, range[i]))
        {
            if (++i >= range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            ret = barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto planeReverse(alias C, A, B)(auto ref A range, B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength - 1;
    while (true)
    {  
        if (range[i] != elem)
        {
            if (--i < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (--i < 0)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (--i < 0)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto planeReverse(alias C, A, B)(auto ref A range, B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength - subrange.loadLength;
    while (true)
    {
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (--i - subrange.loadLength < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }
            
        static if (RETURN)
        {
            auto ret = barter!C(i, slice);
            if (--i - subrange.loadLength < 0)
                return ret;
        }
        else
        {
            barter!C(i, slice);
            if (--i - subrange.loadLength < 0)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto planeReverse(alias C, alias F, T)(auto ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!T, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength;
    while (true)
    {
        if (!barter!F(i, range[i]))
        {
            if (--i < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (--i < 0)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (--i < 0)
                return;
        }
    }
}

/**
 * Creates an array of numbers ranging from `start`..`end` with increments of `step`.
 *
 * Params:
 *  start = Array start value.
 *  end = Array end value.
 *  step = Array increment value. Defaults to 1.
 *
 * Returns:
 *  Array of numbers from `start`..`end` with increment of `step`.
 *
 * Remarks:
 *  End is not included in the array of values, exclusive.
 */
size_t[] iota(size_t start, size_t end, size_t step = 1)
{
    size_t[] buff = [start];
    end--;
    return buff.plane!(() => buff ~= buff[$-1] + step, () => buff[$-1] < end);
}

/**
 * Calls `F` with `args` and assigns `ex` if any exception is thrown.
 *
 * Params:
 *  F = The function to be called.
 *  args = The arguments to call `F` on.
 *
 * Returns:
 *  `F` return value, or false if an exception was thrown.
 *
 * Remarks:
 *  Will not catch throwables or errors, treated as critical.
 */
auto attempt(alias F, ARGS...)(ARGS args, out Exception ex)
{
    try
    {
        return F(args);
    }
    catch (Exception _ex)
    {
        ex = _ex;
        return false;
    }
}

/**
 * Asynchronously calls every function in `FUNCS` using the given arguments, and returns all of the values in a tuple.
 *
 * Params:
 *  F = The function to be called.
 *  args = The arguments to call `F` on.
 *
 * Returns:
 *  A tuple of all returned values from every function in `FUNCS`.
 *
 * Remarks:
 *  Race conditions are very likely, make sure that the functions are thread safe.
 */
public template juxt(FUNCS...)
    if (seqAll!(isCallable, FUNCS))
{
    /**
     * Asynchronously calls every function in `FUNCS` using the given arguments, and returns all of the values in a tuple.
     *
     * Params:
     *  F = The function to be called.
     *  args = The arguments to call `F` on.
     *
     * Returns:
     *  A tuple of all returned values from every function in `FUNCS`.
     *
     * Remarks:
     *  Race conditions are very likely, make sure that the functions are thread safe.
     */
    auto juxt(ARGS...)(ARGS args)
    {
        string tup()
        {
            string ret;
            static foreach (F; FUNCS)
                ret ~= is(ReturnType!F == void) ? "bool, " : fullyQualifiedName!(ReturnType!F)~", ";
            return "Tuple!("~ret[0..$-2]~')';
        }
        
        mixin(tup) ret;
        foreach (i; parallel(iota(0, FUNCS.length)))
        {
            static foreach (j, F; FUNCS)
                mixin("if (i == "~j.to!string~") ret["~j.to!string~"] = await!(FUNCS["~j.to!string~"])(args);");
        }
        return ret;
    }
}

/**
 * Calls `F` as forcibly pure with `args`.
 *
 * Params:
 *  F = The function to be called.
 *  args = The arguments to call `F` on.
 *
 * Returns:
 *  The return value of `F`.
 */
auto tap(alias F, ARGS...)(ARGS args)
    if (isCallable!F && isModule!(__traits(parent, F)))
{
    static if (!hasFunctionAttributes!(F, "pure"))
        auto G = cast(SetFunctionAttributes!(typeof(&F), functionLinkage!F, functionAttributes!F | FunctionAttribute.pure_))&F;
    else
        auto G = &F;
    return G(args);
}

/**
 * Calls `F` as forcibly pure with `args` on `parent`, and prevents side effects on `parent`.
 *
 * Params:
 *  F = The function to be called.
 *  args = The arguments to call `F` on.
 *
 * Returns:
 *  The return value of `F`.
 *
 * Remarks:
 *  Static data may still be modified by the function.
 */
auto tap(alias M, T, ARGS...)(auto ref T parent, ARGS args)
    if (isCallable!M && isSame!(T, __traits(parent, M)))
{
    static if (!hasFunctionAttributes!(M, "pure"))
        auto G = cast(SetFunctionAttributes!(
                typeof(mixin("&parent."~__traits(identifier, M))), 
                functionLinkage!M, 
                functionAttributes!M | FunctionAttribute.pure_)
            )mixin("&parent."~__traits(identifier, M));
    else
        auto G = mixin("&parent."~__traits(identifier, M));;
    T t = parent.qdup;
    scope (exit) parent.blit(t);
    return G(args);
}