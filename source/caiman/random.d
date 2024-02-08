/// Comptime random number generation, supports all integral types, floats, and boolean
module caiman.random;

import std.traits;
import std.meta;
import caiman.traits;

/** 
 * Generates a random boolean with the odds `1/max`
 *
 * Params:
 *  max = Maximum odds, this is what the chance is out of.
 */
public alias randomBool(uint max, uint seed = uint.max, uint r0 = __LINE__, string r1 = __TIMESTAMP__, string r2 = __FILE_FULL_PATH__, string r3 = __FUNCTION__, string r4 = __MODULE__) 
    = Alias!(random!(uint, 0, max, seed, r0, r1, r2, r3, r4) == 0);

/** 
 * Generates a random floating point value.
 *
 * Params:
 *  min = Minimum value.
 *  max = Maximum value.
 *  seed = The seed to generate with, useful if you do multiple random generations in one line, as it causes entropy.
 */
public template random(T, T min, T max, uint seed = uint.max, uint r0 = __LINE__, string r1 = __TIMESTAMP__, string r2 = __FILE_FULL_PATH__, string r3 = __FUNCTION__, string r4 = __MODULE__) 
    if (is(T == float) || is(T == double))
{
    public pure T random()
    {
        return random!(ulong, cast(ulong)(min * cast(T)1000), cast(ulong)(max * cast(T)1000), seed, r0, r1, r2, r3, r4) / cast(T)1000;
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
public template random(T, T min, T max, uint seed = uint.max, uint r0 = __LINE__, string r1 = __TIMESTAMP__, string r2 = __FILE_FULL_PATH__, string r3 = __FUNCTION__, string r4 = __MODULE__)
    if (isIntegral!T)
{
    public pure T random()
    {
        pragma(msg, TypeNames!(mixin(r4)).stringof);
        static if (min == max)
            return min;

        ulong s0 = (seed * r0) || 1;
        ulong s1 = (seed * r0) || 1;
        ulong s2 = (seed * r0) || 1;
        
        static foreach (c; r1)
            s0 *= (c * (r0 ^ seed)) || 1;
        static foreach (c; r2)
            s1 *= (c * (r0 - seed)) || 1;
        static foreach (c; r3)
            s2 *= (c * (r0 ^ seed)) || 1;
        
        ulong o = s0 + s1 + s2;
        return min + (cast(T)o % (max - min));
    }
}