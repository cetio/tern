/// Algorithms for mutating or searching based on iteration of an array
module tern.algorithm.iteration;

import tern.traits;
import tern.algorithm.searching;
public import tern.algorithm.lazy_filter;
public import tern.algorithm.lazy_map;

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
        ret ~= arr~by;
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
    if (isIndexable!T && isIntegral!(ElementType!T))
{
    ElementType!T sum;
    foreach (u; arr)
        sum += u;
    return sum;
}

ElementType!T average(T)(T arr)
    if (isIndexable!T && isIntegral!(ElementType!T))
{
    return arr.sum / arr.length;
}