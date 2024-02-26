/// Algorithms for finding some kind of sequence or element in an array
module tern.algorithm.searching;

import tern.traits;
import tern.meta;
import tern.blit;

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
    if (isIndexable!T)
{
    if (pad)
        arr ~= new ElementType!T[blockSize - (arr.loadLength % blockSize)];
    
    T[] ret;
    foreach (i; 0..((arr.loadLength / 8) - 1))
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
    if (isIndexable!T)
{
    static if (!isStaticArray!T)
        arr ~= new ElementType!T[P.sizeof - (arr.loadLength % P.sizeof)];
    else
        static assert(Length!T % P.sizeof == 0, "Static array cannot be portioned, does not align to size!");
    
    P[] ret;
    foreach (i; 0..((arr.loadLength / P.sizeof) - 1))
        ret ~= *cast(P*)(&arr[(i * P.sizeof)]);
    return ret;
}

size_t indexOf(A, B)(A arr, B elem)
    if (isForward!A && isElement!(A, B))
{
    foreach (i; 0..arr.loadLength)
    {
        if (arr[i] == elem)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B elem)
    if (isBackward!A && isElement!(A, B))
{
    foreach_reverse (i; 0..arr.loadLength)
    {
        if (arr[i] == elem)
            return i;
    }
    return -1;
}

size_t indexOf(A, B)(A arr, B subarr)
    if (isForward!A && !isElement!(A, B) && isIndexable!B)
{
    if (subarr.loadLength > arr.loadLength)
        return -1;

    foreach (i; 0..(arr.loadLength - subarr.loadLength + 1))
    {
        if (arr[i..(i + subarr.loadLength)] == subarr)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B subarr)
    if (isForward!A && !isElement!(A, B) && isIndexable!B)
{
    if (subarr.loadLength >= arr.loadLength)
        return -1;

    foreach_reverse (i; 0..(arr.loadLength - subarr.loadLength + 1))
    {
        if (arr[i..(i + subarr.loadLength)] == subarr)
            return i;
    }
    return -1;
}

size_t indexOf(alias F, A)(A arr)
    if (isForward!A && isCallable!F)
{
    foreach (i; 0..arr.loadLength)
    {
        if (F(arr[i]))
            return i;
    }
    return -1;
}

size_t lastIndexOf(alias F, A)(A arr)
    if (isForward!A && isCallable!F)
{
    foreach_reverse (i; 0..arr.loadLength)
    {
        if (F(arr[i]))
            return i;
    }
    return -1;
}

size_t countUntil(A, B)(A arr, B elem) if (isIndexable!A && isElement!(A, B))  => arr.indexOf(elem);
size_t countUntil(A, B)(A arr, B subarr) if (isIndexable!A && !isElement!(A, B) && isIndexable!B) => arr.indexOf(subarr);
size_t countUntil(alias F, A)(A arr) if (isForward!A) => arr.indexOf!F;
size_t among(alias F, A)(A arr) if (isIndexable!A) => arr.indexOf!F + 1;

bool contains(A, B)(A arr, B elem) if (isIndexable!A && isElement!(A, B)) => arr.indexOf(elem)!= -1;
bool contains(A, B)(A arr, B subarr) if (isIndexable!A && !isElement!(A, B) && isIndexable!B) => arr.indexOf(subarr) != -1;
bool contains(alias F, A)(A arr) if (isIndexable!A && isCallable!F) => arr.indexOf!F != -1;
bool canFind(A, B)(A arr, B elem) if (isIndexable!A && isElement!(A, B)) => indexOf(arr, elem) != -1;
bool canFind(A, B)(A arr, B subarr) if (isIndexable!A && !isElement!(A, B) && isIndexable!B) => indexOf(arr, subarr) != -1;
bool canFind(alias F, A)(A arr) if (isIndexable!A && isCallable!F) => arr.indexOf!F != -1;

bool startsWith(A, B)(A arr, B elem) if (isIndexable!A && isElement!(A, B)) => arr.length >= 1 && arr[0..1].contains(elem);
bool startsWith(A, B)(A arr, B subarr) if (isIndexable!A && !isElement!(A, B) && isIndexable!B) => arr.length >= subarr.length && arr[0..subarr.length].contains(subarr);
bool endsWith(A, B)(A arr, B elem) if (isIndexable!A && isElement!(A, B)) => arr.length >= 1 && arr[$-1..$].contains(elem);
bool endsWith(A, B)(A arr, B subarr) if (isIndexable!A && !isElement!(A, B) && isIndexable!B) => arr.length >= subarr.length && arr[$-subarr.length..$].contains(subarr);

size_t count(A, B)(A arr, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    size_t count;
    foreach (u; arr)
    {
        if (u == elem)
            count++;
    }
    return count;
}

size_t count(A, B)(A arr, B subarr)
    if (isIndexable!A && !isElement!(A, B) && isIndexable!B)
{
    size_t count;
    while (size_t index = arr.indexOf(subarr) != -1)
    {
        arr = arr[index + subarr.loadLength..$];
        count++;
    }
    return count;
}