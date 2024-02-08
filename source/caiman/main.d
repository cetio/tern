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
    /* import std.datetime : Clock, SysTime;
    mixin("writeln("~Clock.currStdTime().to!string~");");
    writeln(stackNew!(int[])(1).ptr); writeln(stackNew!(int[])(1).ptr);
    
    auto a = stackNew!B(); 
    auto b = stackNew!B();
    writeln(&a);
    writeln(&b); */  
    Kin!(B, uint, "a") a;
    B b = a.asOriginal;
    a.test(); 
    writeln(isStackAllocated(a.asOriginal));
    a = a.makeEndian(Endianness.BigEndian);
    b = a.asOriginal;
    b.a.writeln;
}