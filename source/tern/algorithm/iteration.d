/// Algorithms for mutating or searching based on iteration of an array
module tern.algorithm.iteration;

import tern.traits;

public:
static:
size_t indexOf(A, B)(A arr, B elem)
    if (is(ElementType!A == B))
{
    foreach (i, u; arr)
    {
        if (u == elem)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A, B)(A arr, B elem)
    if (is(ElementType!A == B))
{
    foreach_reverse (i, u; arr)
    {
        if (u == elem)
            return i;
    }
    return -1;
}

size_t indexOf(A)(A arr, A subarr)
{
    if (subarr.length > arr.length)
        return -1;

    foreach (i, u; arr)
    {
        if (arr[i..i + subarr.length] == subarr)
            return i;
    }
    return -1;
}

size_t lastIndexOf(A)(A arr, A subarr)
{
    if (subarr.length > arr.length)
        return -1;

    foreach_reverse (i, u; arr)
    {
        if (i + subarr.length > arr.length)
            continue;

        if (arr[i .. i + subarr.length] == subarr)
            return i;
    }
    return -1;
}

bool contains(A, B)(A arr, B elem) if (is(ElementType!A == B)) => indexOf(arr, elem) != -1;
bool contains(A)(A arr, A subarr) => indexOf(arr, subarr) != -1;