/// Algorithms for finding some kind of sequence or element in an range
module tern.algorithm.searching;

public import tern.algorithm.plane;
import tern.traits;
import tern.meta;
import tern.blit;
import tern.algorithm.iteration;
import tern.lambda;

public:
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
 *  `range` portioned into blocks of `blockSize`
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
 *  `range` portioned into blocks of `blockSize`
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

size_t countUntil(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.indexOf(elem);
}

size_t countUntil(A, B)(A range, B subrange)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    return range.indexOf(subrange);
}

size_t countUntil(alias F, A)(A range)
    if (isForward!A)
{
    return range.indexOf!F;
}

size_t among(alias F, A)(A range)
    if (isIndexable!A)
{
    return range.indexOf!F + 1;
}

bool contains(A, B)(A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    return range.indexOf(elem) != -1;
}

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