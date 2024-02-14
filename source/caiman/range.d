module caiman.range;

import caiman.traits;

/**
 * Last In First Out
 *
 * ```d
 * [] -> push(1) push(2) -> [1, 2] // Order doesn't change between LIFO vs FILO
 * [1, 2] -> pop() -> [1] // Value pushed last gets popped
 * ```
*/
public enum LIFO;
/**
 * First In Last Out
 *
 * ```d
 * [] -> push(1) push(2) -> [1, 2] // Order doesn't change between LIFO vs FILO
 * [1, 2] -> pop() -> [2] // Value pushed first gets popped
 * ```
*/
public enum FILO;

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
T[] portionBy(T)(ref T arr, ptrdiff_t blockSize, bool pad = true)
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

/**
 * Pops a value off of the array
 *
 * Params:
 *  O = Stack order to pop the value using.
 *  T = Array type being popped from.
 *  arr = The array being popped from.
 *
 * Returns: 
 *  The value that was popped off the stack.
 *
 * Remarks:returns:
 *  Defaults to `LIFO`
*/
ElementType!T pop(O = LIFO, T)(ref T arr)
    if ((is(O == LIFO) || is(O == FILO)) && isDynamicArray!T)
{
    assert(arr.length != 0, "Cannot pop from an empty collection!");

    static if (is(O == LIFO))
    {
        scope (exit) arr = arr[0..$-1];
        return arr[$-1];
    }
    else
    {
        scope (exit) arr = arr[1..$];
        return arr[0];
    }
}

/**
 * Duplicates the top value of the array without modifying the stack.
 *
 * Params:
 *  O = Stack order to duplicate the value using.
 *  T = Array type.
 *  arr = The array.
 *
 * Returns: 
 *  The duplicated value from the top of the stack.
 *
 * Remarks:
 *  Defaults to `LIFO`
*/
ElementType!T peek(O, T)(ref T arr)
    if ((is(O == LIFO) || is(O == FILO)) && isDynamicArray!T)
{
    assert(arr.length != 0, "Cannot dup from an empty collection!");

    static if (is(O == LIFO))
    {
        return arr[$-1];
    }
    else
    {
        return arr[0];
    }
}

/**
 * Swaps the top two values on the stack.
 *
 * Params:
 *  O = Stack order to perform the swap on.
 *  T = Array type.
 *  arr = The array.
 *
 * Remarks:
 *  Defaults to `LIFO`
*/
void swap(O = LIFO, T)(ref T arr)
    if ((is(O == LIFO) || is(O == FILO)) && isDynamicArray!T)
{
    assert(arr.length >= 2, "Cannot swap in a collection with less than 2 elements!");

    static if (is(O == LIFO))
    {
        arr[$-1] = arr[$-1] ^ arr[$-2];
        arr[$-2] = arr[$-1] ^ arr[$-2];
        arr[$-1] = arr[$-1] ^ arr[$-2];
    }
    else
    {
        arr[0] = arr[0] ^ arr[1];
        arr[1] = arr[0] ^ arr[1];
        arr[0] = arr[0] ^ arr[1];
    }
}

/**
 * Pushes a value onto the array.
 *
 * Params:
 *  T = Array type being pushed to.
 *  arr = The array being pushed to.
 *  val = The value to push onto the array.
*/
nothrow void push(T)(ref T arr, ElementType!T val)
    if ((is(O == LIFO) || is(O == FILO)) && isDynamicArray!T)
{
    arr ~= val;
}