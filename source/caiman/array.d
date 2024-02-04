/// Wrapper for stack arrays and popping/pushing on arrays with support for LIFO and FILO
// TODO: caiman.memory.op makeArray for @nogc
module caiman.array;

/**
 * Last In First Out
 *
 * ```d
 * [] -> push(1) push(2) -> [1, 2] // Order doesn't change between LIFO vs FILO
 * [1, 2] -> pop() -> [1] // Value pushed last gets popped
 * ```
 */
enum LIFO;
/**
 * First In Last Out
 *
 * ```d
 * [] -> push(1) push(2) -> [1, 2] // Order doesn't change between LIFO vs FILO
 * [1, 2] -> pop() -> [2] // Value pushed first gets popped
 * ```
 */
enum FILO;

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
 * Remarks:
 *  Defaults to `LIFO`
 */
pure U pop(O = LIFO, T : U[], U)(ref T arr)
    if (is(O == LIFO) || is(O == FILO))
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
pure U peek(O, T : U[], U)(ref T arr)
    if (is(O == LIFO) || is(O == FILO))
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
pure void swap(O = LIFO, T : U[], U)(ref T arr)
    if (is(O == LIFO) || is(O == FILO))
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
pure nothrow void push(T : U[], U)(ref T arr, U val)
{
    arr ~= val;
}

unittest 
{
    {
        Stack!int stack;
        stack.push(7);
        stack.push(13);
        assert(stack.pop() == 13);
        assert(stack.pop() == 7);
    }

    {
        Stack!(int, FILO) stack;
        stack.push(7);
        stack.push(13);
        assert(stack.pop() == 7);
        assert(stack.pop() == 13);
    }

    {
        int[] arr;
        arr ~= 1;
        arr ~= 2;
        arr ~= 3;
        arr ~= 4;
        assert(arr.pop!FILO() == 1);
        assert(arr.pop!FILO() == 2);
        assert(arr.pop() == 4);
        assert(arr.pop!LIFO() == 3);
    }

    {
        Stack!int stack;
        stack.push(5);
        stack.push(10);
        assert(stack.length() == 2);

        stack.swap();
        assert(stack.pop() == 5);
        assert(stack.pop() == 10);
    }
}