/// Arbitrary size integer implementation (must be 0<x<=64)
module tern.integer;

import tern.meta : isSame;
import std.conv;
import std.traits;

/// Represents the shorthand for an integer
public alias utri = UInt!24;
/// ditto
public alias tri = Int!24;
/// ditto
public alias upent = UInt!40;
/// ditto
public alias pent = Int!40;
/// ditto
public alias usex = UInt!48;
/// ditto
public alias sex = Int!48;
/// ditto
public alias uhept = UInt!56;
/// ditto
public alias hept = Int!56;

/// Represents the shorthand for a non-promoting integer
public alias npubyte = UInt!8;
/// ditto
public alias npbyte = Int!8;
/// ditto
public alias npushort = UInt!16;
/// ditto
public alias npshort = Int!16;
/// ditto
public alias nputri = UInt!24;
/// ditto
public alias nptri = Int!24;
/// ditto
public alias npuint = UInt!32;
/// ditto
public alias npint = Int!32;
/// ditto
public alias npupent = UInt!40;
/// ditto
public alias nppent = Int!40;
/// ditto
public alias npusex = UInt!48;
/// ditto
public alias npsex = Int!48;
/// ditto
public alias npuhept = UInt!56;
/// ditto
public alias nphept = Int!56;
/// ditto
public alias npulong = UInt!64;
/// ditto
public alias nplong = Int!64;

/// Represents an arbitrary unsigned integer of `SIZE`.
public struct UInt(size_t SIZE)
    if (SIZE <= 64 && SIZE >= 8 && SIZE % 8 == 0)
{
private:
final:
    enum size = SIZE / 8;
    ubyte[size] data;

public:
    enum max = 2 ^^ cast(ulong)SIZE - 1;
    enum min = 0;

    string toString() const
    {
        return (cast(ulong)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        this = val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        static if (T.sizeof < size)
            data[0..T.sizeof] = this.data[0..T.sizeof];
        else
            data[0..size] = this.data[0..size];
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        ulong val = cast(ulong)ahs;
        data[0..size] = (cast(ubyte*)&val)[0..size];  
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return mixin("UInt!SIZE(cast(ulong)this "~op~" cast(ulong)rhs)");
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return mixin("UInt!SIZE(cast(ulong)rhs "~op~" cast(ulong)this)");
    }

    auto opUnary(string op)()
    {
        return mixin("UInt!SIZE("~op~"cast(ulong)this)");
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        this = mixin("cast(A)this "~op~" cast(ulong)ahs");
        return this;
    }

    bool opEquals(A)(const A ahs) const
    {
        static if (!isSame!(Unqual!A, Unqual!(typeof(this))))
            return cast(A)this == ahs;
        else
        {
            static if (isSigned!A)
                return cast(long)this == ahs;
            else
                return cast(ulong)this == ahs;
        }
    }

    int opCmp(A)(const A ahs) const
    {
        return cast(int)(cast(A)this - ahs);
    }
}

/// Represents an arbitrary signed integer of `SIZE`.
public struct Int(size_t SIZE)
    if (SIZE <= 64 && SIZE >= 8 && SIZE % 8 == 0)
{
private:
final:
    enum size = SIZE / 8;
    ubyte[size] data;

public:
    enum max = 2UL ^^ (cast(ulong)SIZE - 1) - 1;
    enum min = -(2L ^^ (cast(long)SIZE - 1) - 1);
    
    string toString() const
    {
        return (cast(long)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        this = val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        static if (T.sizeof < size)
            data[0..T.sizeof] = this.data[0..T.sizeof];
        else
            data[0..size] = this.data[0..size];

        static if (isSigned!T)
        {
            if (this.data[$-1] & 128)
                return cast(T)(-(2L ^^ cast(long)SIZE - (*cast(T*)&data)));
        }
        static if (T.sizeof == size)
            data[$-1] &= ~128;
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        long val = cast(long)ahs;
        data[0..size] = (cast(ubyte*)&val)[0..size];
        data[$-1] >>= 1;
        static if (isSigned!A)
        if (val < 0)
            data[$-1] |= 128;  
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return mixin("Int!SIZE(cast(ulong)this "~op~" cast(ulong)rhs)");
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return mixin("Int!SIZE(cast(ulong)rhs "~op~" cast(ulong)this)");
    }

    auto opUnary(string op)()
    {
        return mixin("Int!SIZE("~op~"cast(long)this)");
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        this = mixin("cast(A)this "~op~" ahs");
        return this;
    }

    bool opEquals(A)(const A ahs) const
    {
        static if (!isSame!(Unqual!A, Unqual!(typeof(this))))
            return cast(A)this == ahs;
        else
        {
            static if (isSigned!A)
                return cast(long)this == ahs;
            else
                return cast(ulong)this == ahs;
        }
    }

    int opCmp(A)(const A ahs) const
    {
        return cast(int)(cast(A)this - ahs);
    }
}