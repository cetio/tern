/// Algorithms for mutating or searching based on iteration of an range
module tern.algorithm.iteration;

import tern.traits;
import tern.algorithm.searching;
import tern.blit;

public:
size_t levenshteinDistance(A, B)(A str1, B str2)
    if (isSomeString!A && isSomeString!B)
{
    auto m = str1.length + 1;
    auto n = str2.length + 1;

    size_t[] dp;

    dp.length = n;

    foreach (j; 0..n)
        dp[j] = j;

    size_t diag;
    size_t top;
    size_t left;

    foreach (i; 1..m)
    {
        diag = i - 1;
        top = i;

        foreach (j; 1..n)
        {
            left = dp[j];
            int cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1;
            dp[j] = top + 1;

            if (dp[j - 1] + 1 < dp[j])
                dp[j] = dp[j - 1] + 1;

            if (diag + cost < dp[j])
                dp[j] = diag + cost;

            diag = left;
            top = dp[j];
        }
    }

    return dp[n - 1];
}

ElementType!T sum(T)(T range)
    if (isForward!T && isIntegral!(ElementType!T))
{
    ElementType!T sum;
    foreach (u; range)
        sum += u;
    return sum;
}

ElementType!T mean(T)(T range)
    if (isIndexable!T && isIntegral!(ElementType!T))
{
    return range.sum / range.loadLength;
}

auto fold(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    plane!(F)(range);
}

ElementType!T[] uniq(T)(T range)
    if (isIndexable!T)
{
    bool[ElementType!T] ret;
    foreach (u; range)
    {
        if (u !in ret)
            ret[u] = true;
    }
    return ret.keys;
}

ElementType!T lastOrDefault(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    auto ret = range.filter!F;
    return ret.length == 0 ? factory!T : ret[$-1];
}

ElementType!T firstOrDefault(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    auto ret = range.filter!F;
    return ret.length == 0 ? factory!T : ret[0];
}

T repeat(T)(T range, size_t iter)
{
    T ret = range;
    foreach (i; 0..iter)
        ret ~= range;
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