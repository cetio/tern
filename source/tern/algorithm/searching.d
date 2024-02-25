/// Algorithms for finding some kind of sequence or element in an array
module tern.algorithm.searching;

import tern.traits;
import tern.meta;
import std.range.primitives : isBidirectionalRange, isInputRange;

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
    if (isArray!T)
{
    static if (!isStaticArray!T)
        arr ~= new ElementType!T[P.sizeof - (arr.length % P.sizeof)];
    else
        static assert(Length!T % P.sizeof == 0, "Static array cannot be portioned, does not align to size!");
    
    P[] ret;
    foreach (i; 0..((arr.length / P.sizeof) - 1))
        ret ~= *cast(P*)(&arr[(i * P.sizeof)]);
    return ret;
}

size_t indexOf(A, B)(A arr, B elem)
    if (isInputRange!A && !isInputRange!B)
{
    size_t index;
    foreach (u; arr)
    {
        if (arr[index] == elem)
            return --index;
        index++;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B elem)
    if (isBidirectionalRange!A && !isInputRange!B)
{
    size_t index;
    foreach_reverse (u; arr)
    {
        if (arr[index] == elem)
            return --index;
    }
    return -1;
}

size_t indexOf(A, B)(A arr, B subarr)
    if (isInputRange!A && isInputRange!B)
{
    if (subarr.length > arr.length)
        return -1;

    size_t index;
    foreach (u; arr)
    {
        if (index + subarr.length > arr.length)
            return -1;

        if (arr[index..(index + subarr.length)] == subarr)
            return index;
        index++;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B subarr)
    if (isBidirectionalRange!A && isBidirectionalRange!B)
{
    if (subarr.length > arr.length)
        return -1;

    size_t index = arr.length;
    foreach_reverse (u; arr)
    {
        if (index + subarr.length > arr.length)
            continue;

        if (arr[index..(index + subarr.length)] == subarr)
            return index;
        index--;
    }
    return -1;
}


bool contains(A, B)(A arr, B elem) if (isInputRange!A && !isInputRange!B) => indexOf(arr, elem) != -1;
bool contains(A, B)(A arr, B subarr) if (isInputRange!A && isInputRange!B) => indexOf(arr, subarr) != -1;

bool startsWith(A, B)(A arr, B elem) if (isInputRange!A && !isInputRange!B) => arr.length >= 1 && arr[0..1].contains(elem);
bool startsWith(A, B)(A arr, B subarr) if (isInputRange!A && isInputRange!B) => arr.length >= subarr.length && arr[0..subarr.length].contains(subarr);
bool endsWith(A, B)(A arr, B elem) if (isInputRange!A && !isInputRange!B) => arr.length >= 1 && arr[$-1..$].contains(elem);
bool endsWith(A, B)(A arr, B subarr) if (isInputRange!A && isInputRange!B) => arr.length >= subarr.length && arr[$-subarr.length..$].contains(subarr);