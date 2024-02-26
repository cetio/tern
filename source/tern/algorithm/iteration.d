/// Algorithms for mutating or searching based on iteration of an array
module tern.algorithm.iteration;

public import tern.algorithm.lazy_filter;
public import tern.algorithm.lazy_map;
import tern.traits;
import tern.algorithm.searching;
import tern.blit;

public:
LazyMap!(F, T) map(alias F, T)(T arr)
    if (isForward!T && isCallable!F)
{
    return LazyMap!(F, T)(arr);
}

unittest
{
    int[] arr = [1, 2, 3];
    assert(arr.map!(x => x > 2)[0] == false);
    assert(arr.map!(x => x > 2)[2] == true);
}

LazyFilter!(F, T) filter(alias F, T)(T arr)
    if (isForward!T && isCallable!F)
{
    return LazyFilter!(F, T)(arr);
}

LazyFilter!(F, T) sieve(alias F, T)(T arr)
    if (isForward!T && isCallable!F)
{
    return LazyFilter!(F, T)(arr);
}

unittest
{
    int[] arr = [1, 2, 3];
    assert(arr.filter!(x => x > 2)[0] == 3);
}

size_t levenshteinDistance(A, B)(A str1, B str2)
    if (isSomeString!A && isSomeString!B)
{
    auto m = str1.length + 1;
    auto n = str2.length + 1;

    size_t[][] dp;

    dp.length = m;
    foreach (i; 0..m)
        dp[i].length = n;

    foreach (i; 0..m)
        dp[i][0] = i;

    foreach (j; 0..n)
        dp[0][j] = j;

    foreach (i; 1..m)
    {
        foreach (j; 1..n)
        {
            int cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1;
            dp[i][j] = dp[i - 1][j] + 1;

            if (dp[i][j - 1] + 1 < dp[i][j])
                dp[i][j] = dp[i][j - 1] + 1;

            if (dp[i - 1][j - 1] + cost < dp[i][j])
                dp[i][j] = dp[i - 1][j - 1] + cost;
        }
    }

    return dp[m - 1][n - 1];
}

A join(A, B)(A[] arrs, B by)
    if (isIndexable!A)
{
    A ret;
    foreach (arr; arrs)
    {
        static if (isIndexable!B)
            ret ~= arr~cast(A)by;
        else
            ret ~= arr~cast(ElementType!A)by;
    }
    return ret;
}

A[] split(A, B)(A arr, B by)
    if (isIndexable!A)
{
    A[] ret;
    size_t index = arr.indexOf(by);
    while (index != -1)
    {
        ret ~= arr[0..index];
        arr = arr[(index + 1)..$];
        index = arr.indexOf(by);
    }
    return ret;
}

A[] split(alias F, A)(A arr)
    if (isIndexable!A && isCallable!F)
{
    A[] ret;
    size_t index = arr.indexOf!F;
    while (index != -1)
    {
        if (index != 0)
            ret ~= arr[0..index];

        arr = arr[(index + 1)..$];
        index = arr.indexOf!F;
    }
    return ret;
}

ElementType!T sum(T)(T arr)
    if (isForward!T && isIntegral!(ElementType!T))
{
    ElementType!T sum;
    foreach (u; arr)
        sum += u;
    return sum;
}

ElementType!T mean(T)(T arr)
    if (isIndexable!T && isIntegral!(ElementType!T))
{
    return arr.sum / arr.loadLength;
}

auto fold(alias F, T)(T arr)
    if (isIndexable!T && isCallable!F)
{
    auto ret = F(arr[0], arr[1]);
    foreach (u; arr[2..$])
        F(u, ret);
}

ElementType!T[] uniq(T)(T arr)
    if (isIndexable!T)
{
    bool[ElementType!T] ret;
    foreach (u; arr)
    {
        if (u !in ret)
            ret[u] = true;
    }
    return ret.keys;
}

ElementType!T lastOrDefault(alias F, T)(T arr)
    if (isIndexable!T && isCallable!F)
{
    auto ret = arr.filter!F;
    return ret.length == 0 ? factory!T : ret[$-1];
}

ElementType!T firstOrDefault(alias F, T)(T arr)
    if (isIndexable!T && isCallable!F)
{
    auto ret = arr.filter!F;
    return ret.length == 0 ? factory!T : ret[0];
}

T repeat(T)(T arr, size_t iter)
{
    T ret = arr;
    foreach (i; 0..iter)
        ret ~= arr;
    return ret;
}

size_t difference(A, B)(A comparer, B comparee)
    if (isIndexable!A && isIndexable!B)
{
    size_t ret = comparer.loadLength - comparee.length;
    foreach (i; 0..comparee.loadLength)
    {
        if (i >= comparer.length)
            return ret;

        if (comparee[i] != comparer[i])
            ret++;
    }
    return ret;
}