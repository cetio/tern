module caiman.main;

import caiman;
import std.stdio;
import std.meta;
import std.algorithm;
import std.traits;
import std.array;
import std.datetime;
import std.file;

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
    //ubyte[] bytes = cast(ubyte[])std.file.read(r"C:\Users\stake\Downloads\VSCodeUserSetup-x64-1.86.1.exe");
    ubyte[] bytes = cast(ubyte[])"Hello World!";
    auto start = Clock.currTime();
    writeln(cast(string)bytes);
    mira_encrypt(bytes, "YTvF4J2XHSbiZSWQ5uZfQqwyn8NNJkyd");
    writeln(cast(string)bytes);
    std.file.write(r"C:\Users\stake\Downloads\out.exe", bytes);
    //writeln(cast(string)bytes);
    writeln(Clock.currTime() - start);
    //mira_decrypt(bytes, "YTvF4J2XHSbiZSWQ5uZfQqwyn8NNJkyd");
    //writeln(cast(string)bytes);
}