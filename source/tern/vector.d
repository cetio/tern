/// Arbitrary vector implementation and utilities for working with vectors.
module tern.vector;

import tern.traits;
import core.simd;
import tern.blit;

/// Arbitrary vector implementation, allows any length vector less than or equal to 256 bits and can be interacted with as an array.
public struct Vector(T)
    if (is(T U : U[L], size_t L) && (isIntegral!U || isFloatingPoint!U))
{
    enum is256 = length * ElementType!T.sizeof > 16;
    static if (is256)
    {
        static if (ElementType!T.sizeof % 8 == 0)
            ElementType!T[4] data;
        else static if (ElementType!T.sizeof % 4 == 0)
            ElementType!T[8] data;
        else static if (ElementType!T.sizeof % 2 == 0)
            ElementType!T[16] data;
        else
            ElementType!T[32] data;
    }
    else
    {
        static if (ElementType!T.sizeof % 8 == 0)
            ElementType!T[2] data;
        else static if (ElementType!T.sizeof % 4 == 0)
            ElementType!T[4] data;
        else static if (ElementType!T.sizeof % 2 == 0)
            ElementType!T[8] data;
        else
            ElementType!T[16] data;
    }
    alias data this;

public:
final:
    enum length = Length!T;
    static if (ElementType!T.sizeof == 1)
        alias P = mixin(ElementType!T.stringof~"16");
    else static if (ElementType!T.sizeof == 2)
        alias P = mixin(ElementType!T.stringof~"8");
    else static if (ElementType!T.sizeof == 4)
        alias P = mixin(ElementType!T.stringof~"4");
    else static if (ElementType!T.sizeof == 8)
        alias P = mixin(ElementType!T.stringof~"2");

    auto opAssign(A)(A ahs)
    {
        data.blit(ahs);
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
    }

    auto opBinary(string op, R)(const R rhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const 
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;");
        }
        return this;
    }

    auto opOpAssign(string op, A)(A ahs) shared
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;");
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