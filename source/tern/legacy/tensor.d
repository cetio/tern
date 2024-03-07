/// Arbitrary indexable SIMD optimized tensor implementation.
module tern.legacy.tensor;

import tern.legacy.matrix;
import std.conv;

/// Arbitrary tensor implementation, allows any row length less than or equal to 256 bits in total and can be interacted with as an array.
public struct Tensor(T, size_t ROWS, size_t COLUMNS, size_t DEPTH)
{
public:
final:
    Matrix!(T, ROWS, COLUMNS)[DEPTH] data;

    this(Matrix!(T, ROWS, COLUMNS)[DEPTH] data)
    {
        this.data = data;
    }

    auto opBinary(string op, R)(const R rhs)
    {
        auto data = this.data;
        foreach (i; 0..COLUMNS)
            mixin("data[i] "~op~"= rhs;");
        return Tensor!(T, ROWS, COLUMNS, DEPTH)(data);
    }

    auto opBinary(string op, R)(const R rhs) shared
    {
        auto data = this.data;
        foreach (i; 0..COLUMNS)
            mixin("data[i] "~op~"= rhs;");
        return Tensor!(T, ROWS, COLUMNS, DEPTH)(data);
    }

    auto opBinaryRight(string op, L)(const L lhs)
    {
        auto data = this.data;
        foreach (i; 0..COLUMNS)
            mixin("lhs "~op~"= data[i];");
        return Tensor!(T, ROWS, COLUMNS, DEPTH)(data);
    }

    auto opBinaryRight(string op, L)(const L lhs) shared
    {
        auto data = this.data;
        foreach (i; 0..COLUMNS)
            mixin("lhs "~op~"= data[i];");
        return Tensor!(T, ROWS, COLUMNS, DEPTH)(data);
    }

    auto opOpAssign(string op, A)(A ahs) 
    {
        foreach (i; 0..COLUMNS)
            mixin("data[i] "~op~"= ahs;");
        return this;
    }

    auto opOpAssign(string op, A)(A ahs) shared
    {
        foreach (i; 0..COLUMNS)
            mixin("data[i] "~op~"= ahs;");
        return this;
    }

    string toString() const shared
    {
        return data.to!string;
    }

    string toString() const
    {
        return data.to!string;
    }
}