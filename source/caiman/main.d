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
    Atomic!(Nullable!uint) a;
    a = 1;
    writeln(a > 0);
}