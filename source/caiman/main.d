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
    ubyte[] a = new ubyte[128];
    BinaryStream stream = new BinaryStream(a);
    stream.putString!(wchar, true)("Hello World!");
    writeln(stream.peekString!(wchar, true));
    writeln(stream.position);
}