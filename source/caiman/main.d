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

struct test
{
    struct test2
    {
        short[2] a;
    }

    int a;
    double b;
    float c;
    void[16] d;

    void fun()
    {

    }
}

void main()
{
    /* PE pe = PE.read(r"C:\Users\stake\Documents\source\repos\Squire-Obfuscator\bin\x64\Release\net6.0-windows10.0.22621.0\Core.dll");
    //PE pe = PE.read(r"C:\Users\stake\source\repos\godwit\Tests\bin\Debug\net6.0\Tests.dll");
    writeln(pe.storageStreams[2].name); */
}