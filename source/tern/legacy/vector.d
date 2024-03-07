/// Arbitrary indexable SIMD optimized vector implementation.
module tern.legacy.vector;

import core.simd;

/// Arbitrary vector implementation, allows any length vector less than or equal to 256 bits and can be interacted with as an array.
public struct Vector(T, size_t LENGTH)
    if (isIntegral!T || isFloatingPoint!T)
{
    enum is256 = LENGTH * T.sizeof > 16;
    static if (is256)
    {
        static if (T.sizeof % 8 == 0)
            T[4] data;
        else static if (T.sizeof % 4 == 0)
            T[8] data;
        else static if (T.sizeof % 2 == 0)
            T[16] data;
        else
            T[32] data;
    }
    else
    {
        static if (T.sizeof % 8 == 0)
            T[2] data;
        else static if (T.sizeof % 4 == 0)
            T[4] data;
        else static if (T.sizeof % 2 == 0)
            T[8] data;
        else
            T[16] data;
    }
    alias data this;

public:
final:
    static if (T.sizeof == 1)
        alias P = mixin(T.stringof~"16");
    else static if (T.sizeof == 2)
        alias P = mixin(T.stringof~"8");
    else static if (T.sizeof == 4)
        alias P = mixin(T.stringof~"4");
    else static if (T.sizeof == 8)
        alias P = mixin(T.stringof~"2");

    this(A)(A ahs)
    {
        this = ahs;
    }

    auto opAssign(A)(A ahs)
    {
        foreach (i, u; ahs)
            data[i] = cast(T)u;
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(T)rhs;
                return vec;");
        }
    }

    auto opBinary(string op, R)(const R rhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(T)rhs;
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const 
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(T)ahs;");
        }
        return this;
    }

    auto opOpAssign(string op, A)(A ahs) shared
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(T)ahs;");
        }
        return this;
    }

    auto opEquals(A)(A ahs) const
    {
        return (*cast(T*)&data) == ahs;
    }

    auto opEquals(A)(A ahs) const shared
    {
        return (*cast(T*)&data) == ahs;
    }

    size_t opDollar() const
    {
        return length;
    }

    size_t opDollar() const shared
    {
        return length;
    }

    string toString() const
    {
        return (*cast(T*)&data).to!string;
    }

    string toString() const shared
    {
        return (*cast(T*)&data).to!string;
    }
}