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
    Nullable!C b;
    writeln(b == null); // true
    b = new C();
    writeln(b == null); // false
}