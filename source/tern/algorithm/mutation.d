/// Algorithms for mutating arrays
module tern.algorithm.mutation;

import tern.traits;
import tern.typecons;
import tern.algorithm.searching;
import tern.algorithm.lazy_substitute;
import tern.blit;

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
 * Swaps elements `i0` and `i1` in `arr`
 *
 * Params:
 *  arr = The array.
 *  i0 = First i to swap.
 *  i1 = Second i to swap.
 */
void swap(T)(ref T arr, size_t i0, size_t i1)
    if (isIndexable!T)
{
    auto d = arr[i0];
    arr[i0] = arr[i1];
    arr[i1] = d;
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
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
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
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
        return arr[$-1];
    else
        return arr[0];
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
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
        arr.swap(arr.loadLength - 1, arr.loadLength - 2);
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
nothrow void push(A, B)(ref A arr, B val)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!A && isElement!(A, B))
{
    arr ~= val;
}

A replace(A, B, C)(A arr, B from, C to)
    if (isIndexable!A && isElement!(A, B) && isElement!(A, C))
{
    Enumerable!A ret = arr;
    foreach (i; 0..ret.length)
    {
        if (ret[i] == to)
            ret[i] = from;
    }
    return ret.value;
}

A replace(A, B, C)(A arr, B from, C to)
    if (isIndexable!A && isIndexable!B && isIndexable!C && !isElement!(A, B) && !isElement!(A, C))
{
    Enumerable!A ret = arr;
    foreach (ref i; 0..ret.length)
    {
        if (i + from.loadLength >= ret.loadLength)
            break;

        if (ret[i..(i + from.loadLength)] == from)
        {
            if (to.loadLength <= from.loadLength)
                ret[i..(i + to.loadLength)] = to;
            else
            {
                ret[i..(i + from.loadLength)] = to[0..from.loadLength];
                ret.insert(i + from.loadLength, to[from.loadLength..$]);
            }

            if (to.loadLength < from.loadLength)
                ret.alienate(i + to.loadLength, from.loadLength - to.loadLength);

            i += to.loadLength - 1;
        }
    }
    return ret.value;
}

A replaceMany(A, B, C...)(A arr, B to, C from)
    if (isIndexable!A)
{
    foreach (u; from)
        arr.replace(u, to);
    return arr;
}

A remove(A, B)(A arr, B val)
    if (isIndexable!A)
{
    Enumerable!A ret = arr;
    foreach (ref i; 0..ret.length)
    {
        if (i + val.loadLength > ret.length)
            break;

        if (ret[i..(i + val.loadLength)] == val)
            ret.alienate(i, val.loadLength);
    }
    return ret.value;
}

A removeMany(A, B...)(A arr, B vals)
    if (B.length > 1 && isIndexable!A)
{
    foreach (u; vals)
        arr = arr.remove(u);
    return arr;
}

LazySubstitute!(A, B, C) substitute(A, B, C)(A arr, B from, C to)
    if (isForward!T && isIndexable!T)
{
    return LazySubstitute!(A, B, C)(arr, from, to);
}

T reverse(T)(T arr) 
    if (isIndexable!T)
{
    for (size_t i = 0; i < arr.loadLength / 2; i++) 
        arr.swap(i, arr.loadLength - i - 1);
    return arr;
}

pragma(inline)
void fill(A, B)(ref A arr, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    Enumerable!A ret = arr;
    foreach (i; 0..ret.length)
        ret[i] = elem;
    arr = ret.value;
}

pragma(inline)
void clear(T)(ref T arr)
    if (isIndexable!T)
{
    Enumerable!A ret = arr;
    foreach (i; 0..ret.length)
        ret[i] = ElementType!T.init;
    arr = ret.value;
}

pragma(inline)
void alienate(T)(ref T arr, size_t i, size_t length)
{
    Enumerable!T ret = arr;
    ret = ret[0..i]~ret[(i + length)..$];
    arr = ret.value;
}

pragma(inline)
void insert(A, B)(ref A arr, size_t i, B elem)
    if (isIndexable!A)
{
    Enumerable!A ret = arr;
    static if (isIndexable!B)
        ret = ret[0..i]~cast(A)elem~ret[i..$];
    else
        ret = ret[0..i]~cast(ElementType!A)elem~ret[(i + 1)..$];
    arr = ret.value;
}

void copy(A, B)(A src, ref B dst)
{
    Enumerable!A esrc = src;
    Enumerable!B edst = dst;
    edst[0..$] = esrc[0..$];
    dst = edst.value;
}