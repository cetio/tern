module tern.algorithm.plane;

import tern.traits;
import tern.blit;
import tern.lambda;

public:
/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto plane(alias C, A, B)(ref A range, B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    size_t i;
    while (true)
    {
        if (range[i] != elem)
        {
            if (++i >= range.loadLength)
                return;
            continue;
        }

        static if (__traits(compiles, { auto _ = barter!C(i, range[i]); }))
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
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto plane(alias C, A, B)(ref A range, B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    size_t i;
    while (true)
    {   
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (++i + subrange.loadLength > range.loadLength)
                return;
            continue;
        }

        static if (__traits(compiles, { auto _ = barter!C(i, slice); }))
        {
            auto ret = barter!C(i, slice);
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
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto plane(alias C, alias F, T)(ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    size_t i;
    while (true)
    {
        if (!F(range[i]))
        {
            if (++i >= range.loadLength)
                return;
            continue;
        }

        static if (__traits(compiles, { auto _ = barter!C(i, range[i]); }))
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
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto planeReverse(alias C, A, B)(ref A range, B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    size_t i = range.loadLength - 1;
    while (true)
    {  
        if (range[i] != elem)
        {
            if (--i < 0)
                return;
            continue;
        }

        static if (__traits(compiles, { auto _ = barter!C(i, range[i]); }))
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
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto planeReverse(alias C, A, B)(ref A range, B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    size_t i = range.loadLength - subrange.loadLength;
    while (true)
    {
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (--i - subrange.loadLength < 0)
                return;
            continue;
        }
            
        static if (__traits(compiles, { auto _ = barter!C(i, slice); }))
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
 * Calls `C` using auto-fulfillment (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto planeReverse(alias C, alias F, T)(ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    size_t i = range.loadLength;
    while (true)
    {
        if (!F(range[i]))
        {
            if (--i < 0)
                return;
            continue;
        }

        static if (__traits(compiles, { auto _ = barter!C(i, range[i]); }))
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