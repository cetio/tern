/// Provides 24 bit integers
module tern.tri;

import std.conv;
import std.traits;
import std.bitmanip;

/// Represents an unsigned 24 bit integer.
public struct utri
{
private:
final:
    ubyte[3] data;

public:
    enum max = 2 ^^ 24 - 1;
    enum min = 0;

    string toString() const
    {
        return (cast(uint)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        static assert(T.sizeof <= 4, "Cannot implicitly demote "~T.stringof~" to utri!");
        this = cast(uint)val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        data[0..3] = this.data;
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        static assert(A.sizeof <= 4, "Cannot implicitly demote "~A.stringof~" to utri!");

        static if (A.sizeof == 4)
            data[0..3] = (cast(ubyte*)&ahs)[0..3];
        else
            data[0..A.sizeof] = (cast(ubyte*)&ahs)[0..A.sizeof];
            
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return utri(cast(R)this + rhs);
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return utri(lhs + cast(R)this);
    }

    auto opUnary(string op)()
    {
        return mixin("utri("~op~"cast(uint)this)");
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

/// Represents a signed 24 bit integer.
public struct tri
{
private:
final:
    ubyte[3] data;

public:
    enum max = 2 ^^ 23 - 1;
    enum min = -(2 ^^ 23 - 1);
    
    string toString() const
    {
        return (cast(int)this).to!string;
    }

@nogc:
    this(T)(T val)
        if (isIntegral!T)
    {
        static assert(T.sizeof <= 4, "Cannot implicitly demote "~T.stringof~" to tri!");
        this = cast(int)val;
    }

    T opCast(T)() const
    {
        ubyte[T.sizeof] data;
        data[0..3] = this.data;

        static if (isSigned!T)
        {
            if (data[2] & 128)
                return -(2 ^^ 24 - (*cast(T*)&data));
        }
        data[2] &= ~128;
        return *cast(T*)&data;
    }

    auto opAssign(A)(A ahs)
    {
        static assert(A.sizeof <= 4, "Cannot implicitly demote "~A.stringof~" to tri!");

        static if (A.sizeof == 4)
        {
            data[0..3] = (cast(ubyte*)&ahs)[0..3];
            data[2] >>= 1;
            static if (isSigned!A)
            if (ahs < 0)
                data[2] |= 128;
        }
        else
        {
            data[0..A.sizeof] = (cast(ubyte*)&ahs)[0..A.sizeof];
            data[2] >>= 1;
            static if (isSigned!A)
            if (ahs < 0)
                data[2] |= 128;
        }
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        return tri(cast(R)this + rhs);
    }

    auto opBinaryRight(string op, L)(const L lhs) const
    {
        return tri(lhs + cast(R)this);
    }

    auto opUnary(string op)()
    {
        return mixin("tri("~op~"cast(int)this)");
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