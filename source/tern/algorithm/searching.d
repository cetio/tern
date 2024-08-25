/// Algorithms for searching in a range.
module tern.algorithm.searching;

// TODO: Barter?
import tern.traits;
import tern.typecons;
import tern.functional;
import tern.algorithm;
import tern.object : loadLength;
import tern.memory : memchr, reference;

public:
/**
 * Searches for the index of the given argument in `range`.
 *
 * Params:
 *  range = The range to search in.
 *
 * Returns:
 *  The index of the given argument in `range` or -1 if not found.
 */
size_t indexOf(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    static if ((B.sizeof == 1 || B.sizeof == 2 || B.sizeof == 4 ||
        B.sizeof == 8 || B.sizeof == 16) && (isDynamicArray!A || isStaticArray!A))
    {
        if ((B.sizeof * range.loadLength) % 16 == 0)
            return memchr!0(reference!range, B.sizeof * range.loadLength, elem);
    }

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
 * Returns:
 *  The last index of the given argument in `range` or -1 if not found.
 */
size_t lastIndexOf(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    static if ((B.sizeof == 1 || B.sizeof == 2 || B.sizeof == 4 ||
        B.sizeof == 8 || B.sizeof == 16) && (isDynamicArray!A || isStaticArray!A))
    {
        if ((B.sizeof * range.loadLength) % 16 == 0)
            return memchr!1(reference!range, B.sizeof * range.loadLength, elem);
    }

    foreach (i; 0..range.loadLength)
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
 * Returns:
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
 * Returns:
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
 * Returns:
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
 * Returns:
 *  True if `range` contains `subrange`.
 */
bool contains(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.indexOf(subrange) != -1;
}

/// ditto
bool contains(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    return range.indexOf!F != -1;
}

/// ditto
bool canFind(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return indexOf(range, elem) != -1;
}

/// ditto
bool canFind(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return indexOf(range, subrange) != -1;
}

/// ditto
bool canFind(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    return range.indexOf!F != -1;
}

/**
 * Checks if all elements in `range` fulfill a given predicate `F`.
 *
 * Params:
 *  F = The function predicate to use.
 *  range = The range of values to check if fulfill `F`.
 *
 * Returns:
 *  True if all elements in `range` fulfill `F`.
 */
bool all(alias F, A)(A range)
    if (isForward!A)
{
    return range.filter!F.length == range.loadLength;
}

/**
 * Checks if any elements in `range` fulfill a given predicate `F`.
 *
 * Params:
 *  F = The function predicate to use.
 *  range = The range of values to check if fulfill `F`.
 *
 * Returns:
 *  True if any elements in `range` fulfill `F`.
 */
bool any(alias F, A)(A range)
    if (isForward!A)
{
    return range.indexOf!F != -1;
}

/**
 * Checks if `range` starts with a given element.
 *
 * Params:
 *  range = The range of values to check if starts with `elem`.
 *  elem = The element to check if `range` starts with.
 *
 * Returns:
 *  True if `range` starts with `elem`.
 */
bool startsWith(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.length >= 1 && range[0..1].contains(elem);
}

/// ditto
bool startsWith(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.length >= subrange.length && range[0..subrange.length].contains(subrange);
}

/**
 * Checks if `range` ends with a given element.
 *
 * Params:
 *  range = The range of values to check if ends with `elem`.
 *  elem = The element to check if `range` ends with.
 *
 * Returns:
 *  True if `range` ends with `elem`.
 */
bool endsWith(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.length >= 1 && range[$-1..$].contains(elem);
}

/// ditto
bool endsWith(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.length >= subrange.length && range[$-subrange.length..$].contains(subrange);
}

/**
 * Counts all occurrences of `elem` in `range`.
 *
 * Params:
 *  range = The range of values to count in.
 *  elem = The element to count for in `range`.
 *
 * Returns:
 *  Number of occurrences of `elem` in range.
 */
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

/// ditto
size_t count(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    size_t count;
    range.plane!((ref i) {
        count++;
    })(subrange);
    return count;
}