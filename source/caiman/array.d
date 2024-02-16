module caiman.array;

import caiman.traits;
import caiman.algorithm;

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
        arr.swap(arr.length - 1, arr.length - 2);
    else
        arr.swap(0, 1);
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