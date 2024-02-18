/// Algorithms for finding some kind of sequence or element in an array
module tern.algorithm.searching;

import tern.traits;

public:
static:
pure:
/** 
 * Portions `arr` into blocks of `blockSize`, with optional padding.
 *
 * Params:
 *  arr = The array to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the array be padded? Defaults to true.
 *
 * Returns: 
 *  `arr` portioned into blocks of `blockSize`
 */
T[] portionBy(T)(ref T arr, size_t blockSize, bool pad = true)
    if (isDynamicArray!T)
{
    if (pad)
        arr ~= new ElementType!T[blockSize - (arr.length % blockSize)];
    
    T[] ret;
    foreach (i; 0..((arr.length / 8) - 1))
        ret ~= arr[(i * 8)..((i + 1) * 8)];
    return ret;
}

/** 
 * Portions `arr` into blocks of `blockSize`.
 *
 * Params:
 *  arr = The array to be portioned.
 *  blockSize = The size of the blocks to be portioned.
 *  pad = Should the array be padded? Defaults to true.
 *
 * Returns: 
 *  `arr` portioned into blocks of `blockSize`
 */
P[] portionTo(P, T)(ref T arr)
    if (isDynamicArray!T)
{
    arr ~= new ElementType!T[P.sizeof - (arr.length % P.sizeof)];
    
    P[] ret;
    foreach (i; 0..((arr.length / P.sizeof) - 1))
        ret ~= *cast(P*)(arr[(i * P.sizeof)..((i + 1) * P.sizeof)].ptr);
    return ret;
}

size_t levenshteinDistance(string str1, string str2)
{
    auto m = str1.length + 1;
    auto n = str2.length + 1;

    size_t[][] dp;

    dp.length = m;
    foreach (i; 0..m)
        dp[i].length = n;

    for (auto i = 0; i < m; ++i)
        dp[i][0] = i;

    for (auto j = 0; j < n; ++j)
        dp[0][j] = j;

    for (auto i = 1; i < m; ++i)
    {
        for (auto j = 1; j < n; ++j)
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