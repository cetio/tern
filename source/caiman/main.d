module caiman.main;

import caiman;
import std.stdio;
import std.meta;
import std.algorithm;
import std.traits;

public abstract class A
{
    abstract void a();
    abstract int b();
}

public class B
{
    int a;
    ushort b;
    int c;
}

public class C
{
    int a;
    ushort b;
    int c;
}

void main()
{
    B a = stackNew!B;
    writeln(a); // caiman.main.B
}