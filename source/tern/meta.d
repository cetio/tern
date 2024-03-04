module tern.meta;

public import std.meta : Alias, AliasSeq, aliasSeqOf, Erase, EraseAll, NoDuplicates, Stride,
    DerivedToFront, MostDerived, Repeat, Replace, ReplaceAll, Reverse, staticSort,
    templateAnd, templateNot, templateOr, ApplyLeft, ApplyRight;
import tern.traits;
import std.string;
import std.conv;

// TODO: Function map try reinterpret

public template seqLoad(A...)
{
    auto seqLoad(size_t index)
    {
        switch (index)
        {
            static foreach (j, B; A)
            {
                mixin("case "~j.to!string~":
                return A["~j.to!string~"];");
            }
            default: assert(0);
        }
    }
}

/// Checks if an `AliasSeq` contains an alias.
enum seqContains(A...) =
{
    static if (A.length != 0)
    static foreach (C; A[1..$])
    {
        static if (isSame!(C, A[0]))
            return true;
    }
    return false;
}();

public template seqIndexOf(A...)
{
    enum seqIndexOf =
    {
        static if (A.length != 0)
        static foreach (i, C; A[1..$])
        {
            static if (isSame!(C, A[0]))
                return i;
        }
        return -1;
    }();
}

/// Filters over an `AliasSeq` based on a predicate.
public template seqFilter(A...)
{
    alias seqFilter = AliasSeq!();
    alias F = A[0];

    static if (A.length != 0)
    static foreach (B; A[1..$])
    {
        static if (F!B)
            seqFilter = AliasSeq!(seqFilter, B);
    }
}

/// Filters over an `AliasSeq` based on a string predicate.
public template seqFilter(string F, A...)
{
    alias seqFilter = AliasSeq!();
    
    private template filter(size_t I, alias X) 
    { 
        static if (mixin(F)) 
            alias filter = X; 
        else
            alias filter = AliasSeq!();
    }

    static foreach (i, B; A)
        seqFilter = AliasSeq!(seqFilter, filter!(i, B));
}

/// Maps a template over an `AliasSeq`, returning an `AliasSeq` of all of the return values.
public template seqMap(A...)
{
    alias seqMap = AliasSeq!();
    alias F = A[0];

    static if (A.length != 0)
    static foreach (B; A[1..$])
        seqMap = AliasSeq!(seqMap, F!B);
}

/// Maps a string over an `AliasSeq`, returning an `AliasSeq` of all of the return values.
public template seqMap(string F, A...)
{
    alias seqMap = AliasSeq!();

    private template map(size_t I, alias X) 
    { 
        static if (__traits(compiles, { alias map = mixin(F); }))
            alias map = mixin(F);
        else
            enum map = mixin(F);
    }

    static foreach (i, B; A)
        seqMap = AliasSeq!(seqMap, map!(i, B));
}

/// True if all elements in `A` meet the first given predicate.
public enum seqAny(A...) =
{
    return seqFilter!A.length == A.length - 1;
}();

/// True if any elements in `A` meet the first given predicate.
public enum seqAny(A...) =
{
    return seqFilter!A.length != 0;
}();

/// Creates a string representing `A` using the given separator.
enum seqStringJoin(string SEPARATOR, A...) =
{
    pragma(msg, A);
    static if (A.length == 0)
        return "";

    string ret;
    foreach (i, B; A)
    {
        static if (__traits(compiles, { enum _ = B; }))
            ret ~= B.to!string~(i == A.length - 1 ? null : SEPARATOR);
        else
            ret ~= B.stringof~(i == A.length - 1 ? null : SEPARATOR);
    }
    return ret[0..$];
}();

/// Checks if two aliases are identical.
// Ripped from `std.meta`.
public template isSame(alias A, alias B)
{
    static if (!is(typeof(&A && &B)) // at least one is an rvalue
            && __traits(compiles, { enum isSame = A == B; })) // c-t comparable
        enum isSame = A == B;
    else
        enum isSame = __traits(isSame, A, B) || A.stringof == B.stringof;
}

/** 
 * Generates a random boolean with the odds `1/max`.
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