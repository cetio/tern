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
    byte num = 0x61;
    string str = "Hello world!";
    {
        mixin(prep!5);
        // RCX
        mixin(mov!(a0, string, "string byref!", INOUT));
        // RDX
        mixin(mov!(a1, str, INOUT));
        // R8
        mixin(mov!(a2, num));
        // R9
        mixin(mov!(a3, int[], [1337, 1227, 1117, 1007]));
        // STACK 40
        mixin(mov!(a4, num, REFERENCE));
    }
    asm
    {
        call test1;
    }
    mixin(rest!5);
    // "Goodbye world!"
    str.writeln;
    // 13
    num.writeln;
}

extern (Windows) void test1(ref string a, ref string b, char c, int[] d, ref ubyte e)
{
    b = "Goodbye world!";
    e = 56;
    writeln(a, " ", b, " ", c, " ", d, " ", e);
}

extern (Windows) void test6(int a, int b, int c, int d, int e, int f)
{
    writeln(a, b, c, d, e, f);
}