/// Algorithms for finding some kind of sequence or element in an array
module tern.algorithm.searching;

import tern.traits;

public:
static:
pure:
/** 
 * Portions `arr` into blocks of `blockSize`, with optional padding.
 *
 * Params:
 *  arr = The array to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the array be padded? Defaults to true.
 *
 * Returns: 
 *  `arr` portioned into blocks of `blockSize`
 */
T[] portionBy(T)(ref T arr, size_t blockSize, bool pad = true)
    if (isDynamicArray!T)
{
    if (pad)
        arr ~= new ElementType!T[blockSize - (arr.length % blockSize)];
    
    T[] ret;
    foreach (i; 0..((arr.length / 8) - 1))
        ret ~= arr[(i * 8)..((i + 1) * 8)];
    return ret;
}

/** 
 * Portions `arr` into blocks of `blockSize`.
 *
 * Params:
 *  arr = The array to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the array be padded? Defaults to true.
 *
 * Returns: 
 *  `arr` portioned into blocks of `blockSize`
 */
P[] portionTo(P, T)(ref T arr)
    if (isDynamicArray!T)
{
    arr ~= new ElementType!T[P.sizeof - (arr.length % P.sizeof)];
    
    P[] ret;
    foreach (i; 0..((arr.length / P.sizeof) - 1))
        ret ~= *cast(P*)(arr[(i * P.sizeof)..((i + 1) * P.sizeof)].ptr);
    return ret;
}

size_t indexOf(A, B)(A arr, B elem)
    if (isInputRange!A && is(ElementType!A == B))
{
    foreach (i, u; arr)
    {
        if (u == elem)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B elem)
    if (isBidirectionalRange!A && is(ElementType!A == B))
{
    foreach_reverse (i, u; arr)
    {
        if (u == elem)
            return i;
    }
    return -1;
}

size_t indexOf(A)(A arr, A subarr)
    if (isInputRange!A)
{
    if (subarr.length > arr.length)
        return -1;

    foreach (i, u; arr)
    {
        if (arr[i..i + subarr.length] == subarr)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A)(A arr, A subarr)
    if (isBidirectionalRange!A)
{
    if (subarr.length > arr.length)
        return -1;

    foreach_reverse (i, u; arr)
    {
        if (i + subarr.length > arr.length)
            continue;

        if (arr[i .. i + subarr.length] == subarr)
            return i;
    }
    return -1;
}

bool contains(A, B)(A arr, B elem) if (isInputRange!A && is(ElementType!A == B)) => indexOf(arr, elem) != -1;
bool contains(A)(A arr, A subarr) if (isInputRange!A) => indexOf(arr, subarr) != -1;