module caiman.main;

import caiman;
import std.stdio;
import std.meta;
import std.algorithm;
import std.traits;

public interface A
{

}

public class B : A
{
    int a;
    ushort b;
    int c;

    @nogc this()
    {
    }

    void test()
    {
        writeln(a);
        a = 3;
    }

    auto opOpAssign(string op, T)(T val)
    {
        pragma(msg, op);
    }
}

void main()
{
    // Create new variadic type that extends B and changes B.b from ushort to uint
    VicType!(B, uint, "b") a;
    B b = new B();
    a.b = uint.max;
    b.b = cast(ushort)uint.max;
    a.b.writeln; // 4294967295
    b.b.writeln; // 65535
}