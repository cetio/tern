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
        a = 17;
    }

    void test()
    {
        writeln(a);
        a = 3;
    }
}

void main()
{
    struct TEST { }
    B[] a;
    foreach (i; 0..10)
    {
        auto _a = dsNew!B();
        _a.b = cast(ushort)a.length;
        a ~= _a;
    }
    foreach (_a; a)
        writeln(_a.b);
}