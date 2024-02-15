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
    import caiman.digest.anura;
    import caiman.digest.tea;
    import caiman.digest.hight;
    import caiman.digest.cityhash;
    import caiman.digest.gimli;
    string key128 = "9ydZafSdHSivjFAh";
    string key256 = "SpWc5m7uednxBqV2YrKk83tZ6UayFEPR";
    string key512 = "Eepf6WDvoztoKhjTfyuc3Q4AMmdyJvZpaAoHAdZ2h3KA5gdJHriTDVB8RGqpKtaJ";
    string key1024 = "GmtLDXR7RZdavKmq9vrLm2jafq2JexPHysH2r5rxZtzUpVfKZxps4K8AeZn9P3AZxkE3jfAuZNWWqfkXpbu7jp4mJzWQgx2pndW9uenJR9urJQwp7dvGdgBXkqPa8K8a";
    ubyte[] bytes = cast(ubyte[])std.file.read(r"C:\Users\stake\Downloads\VSCodeUserSetup-x64-1.86.1.exe");
    ubyte[] tbytes = bytes.dup;
    writeln("Size: ", bytes.length / 1024 / 1024, "MB");

    writeln(digest!Berus(bytes, null).toHexString);
    auto start = Clock.currTime();
    Anura.encrypt(bytes, key1024);
    writeln(Clock.currTime() - start);
    writeln(digest!Berus(bytes, null).toHexString);

    start = Clock.currTime();
    Anura.decrypt(bytes, key1024);
    writeln(Clock.currTime() - start);

    ptrdiff_t diff = tbytes.length - bytes.length;
    if (bytes.length == tbytes.length)
    foreach (i; 0..bytes.length)
    {
        if (bytes[i] != tbytes[i])
            diff++;
    }

    writeln("Corrupted? ", bytes != tbytes, ", diff: ", diff);
}