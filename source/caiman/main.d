module main;

import caiman;
import std;

void printHex(ubyte[] arr) {
    foreach (ubyte value; arr) 
        writef("%02X ", value);
    writeln();
}

    //Regex re = regex!(r"^abc$").ctor();
    //re.match("ababc").writeln;
    /* Regex re = regex!(r"\[.{2}\]").ctor();
    re.match("a[12]").writeln;
    Regex re = regex!(r".+").ctor();
    re.match("a[123]").writeln; */
    /* assemble("
        mov [1], rax
    ").printHex; */

struct A
{
    int b;

    int x() => b;
}

interface B
{
    string y();
}

struct D
{
    void print()
    {
        writeln(this);
    }
}

@inherit!A @inherit!B @inherit!D struct C
{
    mixin liberty;

    string y() => "yohoho!";
}

void main()
{
    /* C c;
    c.b = 2;
    c.print();
    c.x().writeln;
    c.y().writeln; */
    /* ubyte16 vec;
    vec = vec + cast(ubyte)1;
    vec.writeln; */
    foreach (i; 0..1_000_000)
        malloc(32);
}


    //PE pe = PE.read(r"C:\Users\stake\Documents\source\repos\Squire-Obfuscator\bin\x64\Release\net6.0-windows10.0.22621.0\Core.dll");
    /* PE pe = PE.read(r"C:\Users\stake\source\repos\godwit\Tests\bin\Debug\net6.0\Tests.dll");
    writeln(pe.clrMetadata.mmodule);
    writeln(pe.clrMetadata.mmodule[0].mvid.drip.to!string(16)); */