module tern.algorithm.range;

import tern.typecons;
import tern.traits;

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
/**
 * Swaps elements `i0` and `i1` in `range`
 *
 * Params:
 *  range = The range.
 *  i0 = First i to swap.
 *  i1 = Second i to swap.
 */
pragma(inline)
void swap(T)(ref T range, size_t i0, size_t i1)
    if (isIndexable!T)
{
    auto d = range[i0];
    range[i0] = range[i1];
    range[i1] = d;
}

/**
 * Pops a value off of `range`.
 *
 * Params:
 *  O = Stack order to pop the value using.
 *  range = The range being popped from.
 *
 * Returns: 
 *  The value that was popped off the stack.
 *
 * Remarks:returns:
 *  Defaults to `LIFO`
 */
pragma(inline)
ElementType!T pop(O = LIFO, T)(ref T range)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
    {
        scope (exit) range = range[0..$-1];
        return range[$-1];
    }
    else
    {
        scope (exit) range = range[1..$];
        return range[0];
    }
}

/**
 * Duplicates the top value of `range` without modifying the stack.
 *
 * Params:
 *  O = Stack order to duplicate the value using.
 *  range = The range.
 *
 * Returns: 
 *  The duplicated value from the top of the stack.
 *
 * Remarks:
 *  Defaults to `LIFO`
 */
pragma(inline)
ElementType!T peek(O, T)(ref T range)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
        return range[$-1];
    else
        return range[0];
}

/**
 * Swaps the top two values on the stack.
 *
 * Params:
 *  O = Stack order to perform the swap on.
 *  range = The range.
 *
 * Remarks:
 *  Defaults to `LIFO`
 */
pragma(inline)
void swap(O = LIFO, T)(ref T range)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
        range.swap(range.loadLength - 1, range.loadLength - 2);
    else
        range.swap(0, 1);
}

/**
 * Pushes a value onto `range`
 *
 * Params:
 *  range = The range being pushed to.
 *  val = The value to push onto the range.
 */
pragma(inline)
nothrow void push(A, B)(ref A range, B val)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!A && isElement!(A, B))
{
    range ~= val;
}

pragma(inline)
void reverse(T)(ref T range) 
    if (isIndexable!T)
{
    for (size_t i = 0; i < range.loadLength / 2; i++) 
        range.swap(i, range.loadLength - i - 1);
}

pragma(inline)
void fill(A, B)(ref A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    Enumerable!A ret = range;
    foreach (i; 0..ret.length)
        ret[i] = elem;
    range = ret.value;
}

pragma(inline)
void clear(T)(ref T range)
    if (isIndexable!T)
{
    Enumerable!A ret = range;
    foreach (i; 0..ret.length)
        ret[i] = ElementType!T.init;
    range = ret.value;
}

pragma(inline)
void alienate(T)(ref T range, size_t i, size_t length)
{
    Enumerable!T ret = range;
    ret = ret[0..i]~ret[(i + length)..$];
    range = ret.value;
}

pragma(inline)
void insert(A, B)(ref A range, size_t i, B elem)
    if (isIndexable!A)
{
    Enumerable!A ret = range;
    static if (isIndexable!B)
        ret = ret[0..i]~cast(A)elem~ret[i..$];
    else
        ret = ret[0..i]~cast(ElementType!A)elem~ret[(i + 1)..$];
    range = ret.value;
}

pragma(inline)
void copy(A, B)(A src, ref B dst)
{
    Enumerable!A esrc = src;
    Enumerable!B edst = dst;
    edst[0..$] = esrc[0..$];
    dst = edst.value;
}