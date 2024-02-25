/// Algorithms for mutating or searching based on iteration of an array
module tern.algorithm.iteration;

import tern.traits;
import std.range.primitives : isBidirectionalRange, isInputRange;
public import tern.algorithm.lazy_filter;
public import tern.algorithm.lazy_map;

public:
LazyMap!(F, T) map(alias F, T)(T arr)
    if (isInputRange!T)
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
    if (isInputRange!T)
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
    if (isInputRange!A)
{
    A ret;
    foreach (arr; arrs)
        ret ~= arr~by;
    return ret;
}