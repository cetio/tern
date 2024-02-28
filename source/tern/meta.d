/// Comptime algorithm templates for working with `AliasSeq`.
module tern.meta;

public import std.meta : Alias, AliasSeq, aliasSeqOf, Erase, EraseAll, NoDuplicates, Stride,
    DerivedToFront, MostDerived, Repeat, Replace, ReplaceAll, Reverse, staticSort,
    templateAnd, templateNot, templateOr, ApplyLeft, ApplyRight;
import tern.traits;
import tern.state;
import tern.serialization;

/**
 * Checks if an `AliasSeq` contains an alias.
 *
 * Example:
 * ```d
 * static assert(seqContains!(string, AliasSeq!(int, float, string)) == true);
 * ```
 */
public template seqContains(A...)
{
    enum seqContains =
    {
        static if (A.length != 0)
        static foreach (C; A[1..$])
        {
            static if (isSame!(C, A[0]))
                return true;
        }
        return false;
    }();
}


/**
 * Filters over an `AliasSeq` based on a predicate.
 *
 * Example:
 * ```d
 * alias S = seqFilter!(isFloatingPoint, AliasSeq!(int, float, string));
 * static assert(is(S == AliasSeq!(float)));
 * ```
 */
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


/**
 * Filters over an `AliasSeq` based on a string predicate.
 *
 * Example:
 * ```d
 * alias S = seqFilter!("isFloatingPoint!A", AliasSeq!(int, float, string));
 * static assert(is(S == AliasSeq!(float)));
 * ```
 */
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


/**
 * Maps a template over an `AliasSeq`, returning an `AliasSeq` of all of the return values.
 *
 * Example:
 * ```d
 * alias S = seqMap!(isIntegral, AliasSeq!(int, float, string));
 * static assert(is(S == AliasSeq!(true, false, false)));
 * ```
 */
public template seqMap(A...)
{
    alias seqMap = AliasSeq!();
    alias F = A[0];

    static if (A.length != 0)
    static foreach (B; A[1..$])
        seqMap = AliasSeq!(seqMap, F!B);
}


/**
 * Maps a string over an `AliasSeq`, returning an `AliasSeq` of all of the return values.
 *
 * Example:
 * ```d
 * alias S = seqMap!("A.sizeof", AliasSeq!(int, byte, long));
 * static assert(is(S == AliasSeq!(4, 1, 8)));
 * ```
 */
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


/**
 * Finds the index of an alias in an `AliasSeq`.
 *
 * Example:
 * ```d
 * static assert(seqIndexOf!(string, AliasSeq!(int, float, string)) == 2);
 * ```
 */
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

/// True if all elements in `A` meet the first given predicate.
public template seqAll(A...)
{
    enum seqAll =
    {
        return seqFilter!A.length == A.length - 1;
    }();
}

/// True if any elements in `A` meet the first given predicate.
public template seqAny(A...)
{
    enum seqAny =
    {
        return seqFilter!A.length != 0;
    }();
}

/** 
 * Creates a string representing `A` using the given separator.  
 * Avoids weird behavior with `stringof` by not using `stringof` for values.
 */
public template seqStringOf(string SEPARATOR, A...)
{
    enum seqStringOf =
    {
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
}

/**
 * Checks if two aliases are identical.
 *
 * Example:
 * ```d
 * static assert(isSame!(A, B));
 * ```
 */
 // Ripped from `std.meta`.
public template isSame(alias A, alias B)
{
    static if (!is(typeof(&A && &B)) // at least one is an rvalue
            && __traits(compiles, { enum isSame = A == B; })) // c-t comparable
        enum isSame = A == B;
    else
        enum isSame = __traits(isSame, A, B);
}


public template Prerequirement(A...)
{
    enum Prerequirement =
    {
        static assert(A.length >= 3, "You stupid");
        alias L = A[0];
        alias R = A[2];
        static if (!__traits(compiles, { enum _ = R!L == A[1]; }))
            return false;
        else static if (R!L != A[1])
            return false;
        else
        {
            static if (A.length > 3)
            foreach (i, B; A[3..$])
            {
                static if (!isTemplate!B)
                    continue;
                else static if (B!L != A[i + 3 - 1])
                    return false;
            }
            return true;
        }
    }();
}

public template Derequirement(A...)
{
    enum Derequirement =
    {
        static assert(A.length >= 3, "You stupid");
        alias L = A[0];
        alias R = A[2];
        static if (!__traits(compiles, { enum _ = R!L == A[1]; }))
            return true;
        else static if (R!L == A[1])
            return true;
        else
        {
            static if (A.length > 3)
            foreach (i, B; A[3..$])
            {
                static if (!isTemplate!B)
                    continue;
                else static if (B!L != A[i + 3 - 1])
                    return false;
            }
            return true;
        }
    }();
}