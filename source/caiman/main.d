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

    void test() shared => writeln(a);
}
void main()
{
    ubyte[] a = new ubyte[32];
    shared AtomicStream stream = new shared AtomicStream(a);
    stream.write!uint(1);
    stream.position -= uint.sizeof;
    writeln(stream.read!uint);
}