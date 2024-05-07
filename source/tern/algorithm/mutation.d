/// Algorithms for mutating ranges and other various range functions.
module tern.algorithm.mutation;

public import tern.algorithm.lazy_filter;
public import tern.algorithm.lazy_map;
public import tern.algorithm.lazy_substitute;
import tern.traits;
import tern.typecons;
import tern.object;
import tern.functional;

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
 * Maps `range` to `F`, where every value will become the output of `F`.
 * 
 * Params:
 *  F = The function to map `range` to.
 *  range = The range to be mapped to `F`.
 *
 * Returns:
 *  A lazy map of `range` using `F`.
 */
LazyMap!(F, T) map(alias F, T)(T range)
    if (isForward!T && isCallable!F)
{
    return LazyMap!(F, T)(range);
}

/**
 * Filters `range` by predicate `F`, where values will removed if `F` is false.
 * 
 * Params:
 *  F = The function predicate to filter `range` by.
 *  range = The range to be filtered by `F`.
 *
 * Returns:
 *  A lazy filter of `range` using `F`.
 */
LazyFilter!(F, T) filter(alias F, T)(T range)
    if (isForward!T && isCallable!F)
{
    return LazyFilter!(F, T)(range);
}

/**
 * Substitutes all instances of `from` in `range` with `to`.
 * 
 * Params:
 *  range = The range to be substituted in.
 *  from = The value to be replaced.
 *  to = The value to replace `from` with.
 *
 * Returns:
 *  A lazy substitute of `range` using `from` and `to`.
 */
LazySubstitute!(A, B, C) substitute(A, B, C)(A range, B from, C to)
    if (isForward!T && isIndexable!T)
{
    return LazySubstitute!(A, B, C)(range, from, to);
}

/**
 * Replaces all instances of `from` in `range`
 * 
 * Params:
 *  range = The range to replace `from` in.
 *  to = The value to replace `from` with.
 *  from = The value to be replaced in `range`.
 *
 * Returns:
 *  The new range after all replaces.
 */
A replace(A, B, C)(A range, B from, C to)
    if (isIndexable!A && isElement!(A, B) && isElement!(A, C))
{
    Range!A ret = range;
    ret.plane!((ref i) {
        ret[i] = from;
    })(from);
    return ret.value;
}

/// ditto
A replace(A, B, C)(A range, B from, C to)
    if (isIndexable!A && isIndexable!B && isIndexable!C && !isElement!(A, B) && !isElement!(A, C))
{
    Range!A ret = range;
    ret.plane!((ref i) {
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
    })(from);
    return ret.value;
}

/**
 * Replaces all values in `from` with `to` in `range`.
 * 
 * Params:
 *  range = The range to replace `from` in.
 *  to = The value to replace all values in `from` with.
 *  from = The values to be replaced in `range`.
 *
 * Returns:
 *  The new range after all replaces.
 */
A replaceMany(A, B, C...)(A range, B to, C from)
    if (isIndexable!A)
{
    foreach (u; from)
        range.replace(u, to);
    return range;
}

/**
 * Removes `val` from `range`.
 * 
 * Params:
 *  range = The range to remove `vals` from.
 *  vals = The value to be removed from `range`.
 *
 * Returns:
 *  The new range after `val` has been removed.
 */
A remove(A, B)(A range, B val)
    if (isIndexable!A)
{
    Range!A ret = range;
    ret.plane!((ref i) {
        ret.alienate(i, val.loadLength);
        i -= val.loadLength;
    })(val);
    return ret.value;
}

/**
 * Removes many `vals` from `range`.
 * 
 * Params:
 *  range = The range to remove `vals` from.
 *  vals = The values to be removed from `range`.
 *
 * Returns:
 *  The new range after all `vals` have been removed.
 */
A removeMany(A, B...)(A range, B vals)
    if (B.length > 1 && isIndexable!A)
{
    foreach (u; vals)
        range = range.remove(u);
    return range;
}

/**
 * Joins an array of `ranges` by an element `by`.
 *
 * Params:
 *  ranges = The ranges to be joined `by`.
 *  by = The element to join each range in `ranges` by.
 *
 * Returns:
 *  A joined range with `by` as the delimiter.
 */
A join(A, B)(A[] ranges, B by)
    if (isIndexable!A)
{
    A ret;
    foreach (range; ranges)
    {
        static if (isIndexable!B)
            ret ~= range~cast(A)by;
        else
            ret ~= range~cast(ElementType!A)by;
    }
    return ret;
}

/**
 * Splits `range` by a given element to split `by`.
 *
 * Params:
 *  range = The range to be split.
 *  by = The element to have `range` split by.
 *
 * Returns:
 *  An array of `A` containing `range` after split `by`.
 */
A[] split(A, B)(A range, B by)
    if (isIndexable!A)
{
    A[] ret;
    range.plane!((ref i) {
        if (i != 0)
            ret ~= range[0..i];

        range = range[(i + by.loadLength)..$];
        i = 0;
    })(by);
    ret ~= range[0..$];
    return ret;
}

/**
 * Splits `range` by a given predicate `F`.
 *
 * Params:
 *  F = The function predicate to split `range` by.
 *  range = The range to be split by the predicate `F`.
 *
 * Returns:
 *  An array of `A` containing `range` after split by `F`.
 */
A[] split(alias F, A)(A range)
    if (isIndexable!A && isCallable!F)
{
    A[] ret;
    range.plane!((ref i) {
        if (i != 0)
            ret ~= range[0..i];

        range = range[(i + 1)..$];
        i = 0;
    }, F);
    ret ~= range[0..$];
    return ret;
}

/**
 * Swaps elements `i0` and `i1` in `range`.
 *
 * Params:
 *  range = The range.
 *  i0 = First i to swap.
 *  i1 = Second i to swap.
 */
pragma(inline, true)
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
 *  Defaults to `LIFO`.
 */
pragma(inline, true)
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
 *  Defaults to `LIFO`.
 */
pragma(inline, true)
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
 *  Defaults to `LIFO`.
 */
pragma(inline, true)
void swap(O = LIFO, T)(ref T range)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!T)
{
    static if (is(O == LIFO))
        range.swap(range.loadLength - 1, range.loadLength - 2);
    else
        range.swap(0, 1);
}

/**
 * Pushes a value onto `range`.
 *
 * Params:
 *  range = The range being pushed to.
 *  val = The value to push onto the range.
 */
pragma(inline, true)
nothrow void push(A, B)(ref A range, B val)
    if ((is(O == LIFO) || is(O == FILO)) && isIndexable!A && isElement!(A, B))
{
    range ~= val;
}

/**
 * Reverses the contents of `range`.
 *
 * Params:
 *  range = The range to be reversed.
 */
pragma(inline, true)
void reverse(T)(ref T range) 
    if (isIndexable!T)
{
    for (size_t i = 0; i < range.loadLength / 2; i++) 
        range.swap(i, range.loadLength - i - 1);
}

/**
 * Fills all elements in `range` with `elem`.
 *
 * Params:
 *  range = The range to be filled.
 *  elem = The range to fill all elements with.
 */
pragma(inline, true)
void fill(A, B)(ref A range, B elem)
    if (isIndexable!A && isElement!(A, B))
{
    Range!A ret = range;
    foreach (i; 0..ret.length)
        ret[i] = elem;
    range = ret.value;
}

/**
 * Clears all elements in `range` without modifying length.
 *
 * Elements will be set to `ElementType!T.init` after clearing.
 *
 * Params:
 *  range = The range to be cleared.
 */
pragma(inline, true)
void clear(T)(ref T range)
    if (isIndexable!T)
{
    Range!A ret = range;
    foreach (i; 0..ret.length)
        ret[i] = ElementType!T.init;
    range = ret.value;
}

/**
 * Alienates `i..length` in `range`, removing it.
 *
 * Params:
 *  range = The range to alienate at.
 *  index = Start index of the elements to be alienated.
 *  length = The length of the section to be alienated.
 */
pragma(inline, true)
void alienate(T)(ref T range, size_t index, size_t length)
    if (isSliceable!T)
{
    Range!T ret = range;
    ret = ret[0..index]~ret[(index + length)..$];
    range = ret.value;
}

/**
 * Inserts `elem` in `range` at `index`.
 *
 * Params:
 *  range = The range to insert into.
 *  index = The index where `elem` will be inserted.
 *  elem = The element to insert.
 */
pragma(inline, true)
void insert(A, B)(ref A range, size_t index, B elem)
    if (isSliceable!A && (isElement!(B, A) || isIndexable!B))
{
    Range!A ret = range;
    static if (isIndexable!B)
    {
        if (index >= ret.length)
            ret = ret[0..index]~cast(A)elem;
        else
            ret = ret[0..index]~cast(A)elem~ret[index..$];
    }
    else
    {
        if (index >= ret.length)
            ret = ret[0..index]~cast(ElementType!A)elem;
        else
            ret = ret[0..index]~cast(ElementType!A)elem~ret[(index + 1)..$];
    }
    range = ret.value;
}