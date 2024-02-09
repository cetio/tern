module caiman.main;

import caiman;
import std.stdio;
import std.meta;
import std.algorithm;
import std.traits;

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

void f()
{
    writeln("guh");
}

void main()
{
    Nullable!D a;
    a = D.init;
    a.a = 3;
    a.test(); // 3
    writeln(a); // const(D)(3)
    Nullable!int b;
    writeln(b == null); // true
    b = 0;
    b += 2;
    writeln(b); // 2
    writeln(b == null); // false
}