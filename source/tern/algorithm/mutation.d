/// Algorithms for mutating ranges.
module tern.algorithm.mutation;

public import tern.algorithm.lazy_filter;
public import tern.algorithm.lazy_map;
public import tern.algorithm.lazy_substitute;
import tern.traits;
import tern.typecons;
import tern.blit;
import tern.algorithm.searching;
import tern.algorithm.range;

public:
LazyMap!(F, T) map(alias F, T)(T range)
    if (isForward!T && isCallable!F)
{
    return LazyMap!(F, T)(range);
}

LazyFilter!(F, T) filter(alias F, T)(T range)
    if (isForward!T && isCallable!F)
{
    return LazyFilter!(F, T)(range);
}

LazySubstitute!(A, B, C) substitute(A, B, C)(A range, B from, C to)
    if (isForward!T && isIndexable!T)
{
    return LazySubstitute!(A, B, C)(range, from, to);
}

A replace(A, B, C)(A range, B from, C to)
    if (isIndexable!A && isElement!(A, B) && isElement!(A, C))
{
    Enumerable!A ret = range;
    ret.plane!((ref i) {
        ret[i] = from;
    })(from);
    return ret.value;
}

A replace(A, B, C)(A range, B from, C to)
    if (isIndexable!A && isIndexable!B && isIndexable!C && !isElement!(A, B) && !isElement!(A, C))
{
    Enumerable!A ret = range;
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

A replaceMany(A, B, C...)(A range, B to, C from)
    if (isIndexable!A)
{
    foreach (u; from)
        range.replace(u, to);
    return range;
}

A remove(A, B)(A range, B val)
    if (isIndexable!A)
{
    Enumerable!A ret = range;
    ret.plane!((ref i) {
        ret.alienate(i, val.loadLength);
        i -= val.loadLength;
    })(val);
    return ret.value;
}

A removeMany(A, B...)(A range, B vals)
    if (B.length > 1 && isIndexable!A)
{
    foreach (u; vals)
        range = range.remove(u);
    return range;
}

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