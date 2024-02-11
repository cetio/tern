module caiman.main;

import caiman;
import std.stdio;
import std.meta;
import std.algorithm;
import std.traits;
import std.array;

public class A
{
    int a;

    auto opOpAssign(string op, T)(T val) => writeln("A");
}

public class B
{
    enum int a = 0;

    auto opOpAssign(string op, T)(T val) => writeln("B");
}

public @inherit!B @inherit!A class C { mixin applyInherits; }

public struct D
{
    int a;

    void test() => writeln(a);
}

void main()
{
    /* Atomic!(Nullable!int) a;
    a = 0;
    writeln(a); */
    Atomic!(Nullable!(constexpr!D)) a;
    writeln(a);
    a = D.init;
    a.test();
    writeln(a);
    Vector!(int[8]) vec;
    writeln(vec + 1); // [1, 1, 1, 1, 1, 1, 1, 1]
    Vector!(ubyte[4]) vec2;
    vec2 = [1, 2, 3, 4];
    writeln(vec2 += 10); // [11, 12, 13, 14]
    import core.simd;
    ubyte16 vec3 = [1, 2, 3, 4];
    // Error: incompatible types for `(vec3) * (cast(__vector(ubyte[16]))cast(ubyte)4u)`: both operands are of type `__vector(ubyte[16])`
    writeln(vec3 * 4);
}