/// Provides 48 bit integers
module tern.sex;

import std.conv;
import std.traits;
import std.bitmanip;

/// Represents an unsigned 48 bit integer.
public struct usex
{
private:
final:
    ubyte[6] data;

public:
    enum max = 2 ^^ 48 - 1;
    enum min = 0;

    string toString() const
    {
        return (cast(ulong)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        static assert(T.sizeof <= 8, "Cannot implicitly demote "~T.stringof~" to usex!");
        this = cast(ulong)val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        data[0..6] = this.data;
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        static assert(A.sizeof <= 8, "Cannot implicitly demote "~A.stringof~" to usex!");

        static if (A.sizeof == 8)
            data[0..6] = (cast(ubyte*)&ahs)[0..6];
        else
            data[0..A.sizeof] = (cast(ubyte*)&ahs)[0..A.sizeof];
            
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return usex(cast(R)this + rhs);
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return usex(lhs + cast(R)this);
    }

    auto opUnary(string op)()
    {
        return mixin("usex("~op~"cast(ulong)this)");
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        this = mixin("cast(A)this "~op~" ahs");
        return this;
    }

    auto opEquals(A)(const A ahs) const
    {
        return cast(A)this == ahs;
    }

    int opCmp(A)(const A ahs) const
    {
        return cast(int)(cast(A)this - ahs);
    }
}

/// Represents a signed 48 bit integer.
public struct sex
{
private:
final:
    ubyte[6] data;

public:
    enum max = 2UL ^^ 47UL - 1;
    enum min = -(2L ^^ 47L - 1);
    
    string toString() const
    {
        return (cast(long)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        static assert(T.sizeof <= 8, "Cannot implicitly demote "~T.stringof~" to sex!");
        this = cast(long)val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        data[0..6] = this.data;

        static if (isSigned!T)
        {
            if (data[5] & 128)
                return -(2UL ^^ 48UL - (*cast(T*)&data));
        }
        data[5] &= ~128;
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        static assert(A.sizeof <= 8, "Cannot implicitly demote "~A.stringof~" to sex!");

        static if (A.sizeof == 8)
        {
            data[0..6] = (cast(ubyte*)&ahs)[0..6];
            data[5] >>= 1;
            static if (isSigned!A)
            if (ahs < 0)
                data[5] |= 128;
        }
        else
        {
            data[0..A.sizeof] = (cast(ubyte*)&ahs)[0..A.sizeof];
            data[5] >>= 1;
            static if (isSigned!A)
            if (ahs < 0)
                data[5] |= 128;
        }    
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return sex(cast(R)this + rhs);
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return sex(lhs + cast(R)this);
    }

    auto opUnary(string op)()
    {
        return mixin("sex("~op~"cast(long)this)");
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        this = mixin("cast(A)this "~op~" ahs");
        return this;
    }

    auto opEquals(A)(const A ahs) const
    {
        return cast(A)this == ahs;
    }

    int opCmp(A)(const A ahs) const
    {
        return cast(int)(cast(A)this - ahs);
    }
}