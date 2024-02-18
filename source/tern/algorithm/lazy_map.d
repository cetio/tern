/// Lazy map-based range (mutate on function)
module tern.algorithm.lazy_map;

import tern.traits;

public struct LazyMap(alias F, T)
{
public:
final:
pure:
    T array;

    this(T arr)
    {
        array = arr;
    }

    T opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        T slice;
        foreach (ref u; array)
        {
            slice ~= opIndex(++start);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        return F(array[index]);
        throw new Throwable("Lazy filter index out of bounds!");
    }
}