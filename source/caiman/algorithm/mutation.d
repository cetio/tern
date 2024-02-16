/// Algorithms for mutating arrays
module caiman.algorithm.mutation;

import caiman.traits;

public:
static:
/**
 * Swaps elements `i0` and `i1` in `arr`
 *
 * Params:
 *  arr = The array.
 *  i0 = First index to swap.
 *  i1 = Second index to swap.
 */
void swap(T)(ref T arr, ptrdiff_t i0, ptrdiff_t i1)
    if (isDynamicArray!T)
{
    ubyte d = arr[i0];
    arr[i0] = arr[i1];
    arr[i1] = d;
}