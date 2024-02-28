/// Algorithms for finding some kind of sequence or element in an range.
module tern.algorithm.searching;

public import tern.functional;
import tern.traits;
import tern.meta;
import tern.blit;
import tern.algorithm.iteration;
import tern.lambda;

public:
/**
 * Searches for the index of the given argument in `range`.
 *
 * Params:
 *  range = The range to search in.
 *
 * Return:
 *  The index of the given argument in `range` or -1 if not found.
 */
size_t indexOf(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    foreach (i; 0..range.loadLength)
    {
        if (range[i] == elem)
            return i;
    }
    return -1;
}

/// ditto
size_t indexOf(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    if (subrange.loadLength > range.loadLength)
        return -1;

    foreach (i; 0..(range.loadLength - subrange.loadLength + 1))
    {
        if (range[i..(i + subrange.loadLength)] == subrange)
            return i;
    }
    return -1;
}

/// ditto
size_t indexOf(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    foreach (i; 0..range.loadLength)
    {
        if (F(range[i]))
            return i;
    }
    return -1;
}

/**
 * Searches for the last index of the given argument in `range`.
 *
 * Params:
 *  range = The range to search in.
 *
 * Return:
 *  The last index of the given argument in `range` or -1 if not found.
 */
size_t lastIndexOf(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    foreach_reverse (i; 0..range.loadLength)
    {
        if (range[i] == elem)
            return i;
    }
    return -1;
}

/// ditto
size_t lastIndexOf(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    if (subrange.loadLength >= range.loadLength)
        return -1;

    foreach_reverse (i; 0..(range.loadLength - subrange.loadLength + 1))
    {
        if (range[i..(i + subrange.loadLength)] == subrange)
            return i;
    }
    return -1;
}

/// ditto
size_t lastIndexOf(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    foreach_reverse (i; 0..range.loadLength)
    {
        if (F(range[i]))
            return i;
    }
    return -1;
}

/** 
 * Portions `range` into blocks of `blockSize`, with optional padding.
 *
 * Params:
 *  range = The range to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the range be padded? Defaults to true.
 *
 * Returns: 
 *  `range` portioned into blocks of `blockSize`.
 */
T[] portionBy(T)(ref T range, size_t blockSize, bool pad = true)
    if (isIndexable!T)
{
    if (pad)
        range ~= new ElementType!T[blockSize - (range.loadLength % blockSize)];
    
    T[] ret;
    foreach (i; 0..((range.loadLength / 8) - 1))
        ret ~= range[(i * 8)..((i + 1) * 8)];
    return ret;
}

/** 
 * Portions `range` into blocks of `blockSize`.
 *
 * Params:
 *  range = The range to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the range be padded? Defaults to true.
 *
 * Returns: 
 *  `range` portioned into blocks of `blockSize`.
 */
P[] portionTo(P, T)(ref T range)
    if (isIndexable!T)
{
    static if (!isStaticArray!T)
        range ~= new ElementType!T[P.sizeof - (range.loadLength % P.sizeof)];
    else
        static assert(Length!T % P.sizeof == 0, "Static range cannot be portioned, does not align to size!");
    
    P[] ret;
    foreach (i; 0..((range.loadLength / P.sizeof) - 1))
        ret ~= *cast(P*)(&range[(i * P.sizeof)]);
    return ret;
}

/**
 * Searches for the index of the given argument in `range`.
 *
 * Params:
 *  range = The range to search in.
 *
 * Return:
 *  The index of the given argument in `range` or -1 if not found.
 */
size_t countUntil(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.indexOf(elem);
}

/// ditto
size_t countUntil(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.indexOf(subrange);
}

/// ditto
size_t countUntil(alias F, A)(A range)
    if (isForward!A)
{
    return range.indexOf!F;
}

/**
 * Searches for the last index of the given argument in `range`.
 *
 * Params:
 *  range = The range to search in.
 *
 * Return:
 *  The last index of the given argument in `range` with 1-based indexing or -1 if not found.
 */
size_t among(alias F, A)(A range)
    if (isIndexable!A)
{
    return range.indexOf!F + 1;
}

/**
 * Checks if `range` contains `elem`.
 *
 * Params:
 *  range = The range to search in.
 *  elem = The element to search for.
 *
 * Return:
 *  True if `range` contains `elem`.
 */
bool contains(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.indexOf(elem) != -1;
}

/**
 * Checks if `range` contains `subrange`.
 *
 * Params:
 *  range = The range to search in.
 *  subrange = The range to search for.
 *
 * Return:
 *  True if `range` contains `subrange`.
 */
bool contains(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.indexOf(subrange) != -1;
}

bool contains(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    return range.indexOf!F != -1;
}

bool canFind(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return indexOf(range, elem) != -1;
}

bool canFind(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return indexOf(range, subrange) != -1;
}

bool canFind(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    return range.indexOf!F != -1;
}

size_t all(alias F, A)(A range)
    if (isForward!A)
{
    return range.filter!F.length == range.loadLength;
}

size_t any(alias F, A)(A range)
    if (isForward!A)
{
    return range.indexOf!F != -1;
}

bool startsWith(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.length >= 1 && range[0..1].contains(elem);
}

bool startsWith(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.length >= subrange.length && range[0..subrange.length].contains(subrange);
}

bool endsWith(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.length >= 1 && range[$-1..$].contains(elem);
}

bool endsWith(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.length >= subrange.length && range[$-subrange.length..$].contains(subrange);
}

size_t count(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    size_t count;
    foreach (u; range)
    {
        if (u == elem)
            count++;
    }
    return count;
}

size_t count(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    size_t count;
    range.plane!((ref i) {
        count++;
    })(subrange);
    return count;
}