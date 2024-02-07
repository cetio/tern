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

    @nogc this(int a, ushort b, int c)
    {
        this.a = a;
        this.b = b;
        this.c = c;
    }
}

void main()
{
    StackArray!int arr;
    assert(arr.ptr is null);
    arr ~= 1;
    debug writeln(arr);
    arr ~= 2;
    arr.popBack();
    arr ~= 3;
    arr ~= 4;
    arr.popFront();
    arr[0..2] = [1, 2];
    debug writeln(arr);
    foreach_reverse (u; arr)
        debug writeln(u, " elem");

    B b = stackNew!B();
    writeln(b.a); // 17
    writeln(b.__monitor); // null
    b.createMonitor();
    writeln(b.__monitor); // valid monitor pointer (trust me)
}