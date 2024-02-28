/// Algorithms for doing calculations on a range.
module tern.algorithm.iteration;

import tern.traits;
import tern.algorithm.searching;
import tern.blit;

public:
/**
 * Calculates the distance between `comparer` and `comparee`.
 *
 * Params:
 *  comparee = The string to calculate from.
 *  comparee = The string to calculate against.
 *
 * Returns:
 *  The distance between `comparer` and `comparee`.
 *
 * Remarks:
 *  `A` and `B` must both be string types.
 */
size_t levenshteinDistance(A, B)(A comparer, B comparee)
    if (isSomeString!A && isSomeString!B)
{
    auto m = comparer.length + 1;
    auto n = comparee.length + 1;

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
            int cost = (comparer[i - 1] == comparee[j - 1]) ? 0 : 1;
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

/**
 * Calculates the difference between `comparer` and `comparee`.
 *
 * Params:
 *  comparee = The range to calculate from.
 *  comparee = The range to calculate against.
 *
 * Returns:
 *  The difference between `comparer` and `comparee`.
 */
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

/**
 * Calculates the sum of all values in `range`.
 *
 * Params:
 *  range = The range to sum.
 *
 * Returns:
 *  The sum of all values in `range`.
 */
ElementType!T sum(T)(T range)
    if (isForward!T && isIntegral!(ElementType!T))
{
    ElementType!T sum;
    foreach (u; range)
        sum += u;
    return sum;
}

/**
 * Calculates the mean of all values in `range`.
 *
 * Params:
 *  range = The range to mean.
 *
 * Returns:
 *  The mean of all values in `range`.
 */
ElementType!T mean(T)(T range)
    if (isIndexable!T && isIntegral!(ElementType!T))
{
    return range.sum / range.loadLength;
}

/**
 * Folds all values in `range` based on a predicate.
 *
 * Params:
 *  F = The function to use for folding.
 *  range = The range to fold.
 *
 * Returns:
 *  Return value of `F` after folding.
 */
auto fold(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    return range.plane!(F, () => true);
}

/**
 * Creates an array of all unique values in `range`.
 *
 * Params:
 *  range = The range to search for uniques in.
 *
 * Returns:
 *  An array of all unique values in `range`.
 */
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

/**
 * Gets the last value in `range` that abides by `F`, or the default value of `T`.
 *
 * Params:
 *  F = The function predicate.
 *  range = The range to be predicated.
 *
 * Returns:
 *  The last value in `range` that abides by `F`, or the default value of `T`.
 */
ElementType!T lastOrDefault(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    auto ret = range.filter!F;
    return ret.length == 0 ? T.init : ret[$-1];
}

/**
 * Gets the first value in `range` that abides by `F`, or the default value of `T`.
 *
 * Params:
 *  F = The function predicate.
 *  range = The range to be predicated.
 *
 * Returns:
 *  The first value in `range` that abides by `F`, or the default value of `T`.
 */
ElementType!T firstOrDefault(alias F, T)(T range)
    if (isIndexable!T && isCallable!F)
{
    auto ret = range.filter!F;
    return ret.length == 0 ? T.init : ret[0];
}

/**
 * Concats `range` to itself `iter` times.
 *
 * Params:
 *  range = The range to repeat.
 *  iter = The number of iterations to repeat.
 *
 * Returns:
 *  The new repeated form of `range`.
 */
T repeat(T)(T range, size_t iter)
{
    T ret = range;
    foreach (i; 0..iter)
        ret ~= range;
    return ret;
}