module main;

import std.stdio;
import caiman.mem.abi;
import std.traits;
import std.meta;

public class A
{

}

public class X : A
{

}

public class B : X
{

}

public class C
{
    B b;
    alias b this;
}

void main()
{
    //Regex re = regex!(r"^abc$").ctor();
    //re.match("ababc").writeln;
    /* Regex re = regex!(r"\[.{2}\]").ctor();
    re.match("a[12]").writeln;
    Regex re = regex!(r".+").ctor();
    re.match("a[123]").writeln; */
    string str = "Hello world!";
    {
        // RCX
        mixin(mov!(a0, int, 1));
        // RDX
        mixin(mov!(a1, str, INOUT));
        // R8
        mixin(mov!(a2, int, 3));
        // R9
        mixin(mov!(a3, int, 4));
    }
    asm
    {
        call test1;
    }
    // "Goodbye world!"
    str.writeln;
}

extern (Windows) void test1(int a, ref string b, int c, int d)
{
    b = "Goodbye world!";
    writeln(a, " ", b, " ", c, " ", d);
}

extern (Windows) void test6(int a, int b, int c, int d, int e, int f)
{
    writeln(a, b, c, d, e, f);
}