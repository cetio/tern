/// Simple seeded compile-time randomization implementation
module tern.ctrand;

import std.meta;
import std.traits;

/** 
 * Generates a random boolean with the odds `1/max`
 *
 * Params:
 *  max = Maximum odds, this is what the chance is out of.
 */
public alias randomBool(uint max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__) 
    = Alias!(random!(uint, 0, max, seed, R0, R1, R2, R3) == 0);

/** 
 * Generates a random floating point value.
 *
 * Params:
 *  min = Minimum value.
 *  max = Maximum value.
 *  seed = The seed to generate with, useful if you do multiple random generations in one line, as it causes entropy.
 */
public template random(T, T min, T max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__) 
    if (is(T == float) || is(T == double))
{
    pure T random()
    {
        return random!(ulong, cast(ulong)(min * cast(T)1000), cast(ulong)(max * cast(T)1000), seed, R0, R1, R2, R3) / cast(T)1000;
    }
}

/** 
 * Generates a random integral value.
 *
 * Params:
 *  min = Minimum value.
 *  max = Maximum value.
 *  seed = The seed to generate with, useful if you do multiple random generations in one line, as it causes entropy.
 */
public template random(T, T min, T max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)
    if (isIntegral!T)
{
    pure T random()
    {
        static if (min == max)
            return min;

        ulong s0 = (seed * R0) || 1;
        ulong s1 = (seed * R0) || 1;
        ulong s2 = (seed * R0) || 1;
        
        static foreach (c; R1)
            s0 *= (c * (R0 ^ seed)) || 1;
        static foreach (c; R2)
            s1 *= (c * (R0 - seed)) || 1;
        static foreach (c; R3)
            s2 *= (c * (R0 ^ seed)) || 1;
        
        ulong o = s0 + s1 + s2;
        return min + (cast(T)o % (max - min));
    }
}