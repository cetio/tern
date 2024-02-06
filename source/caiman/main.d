module caiman.main;

import caiman;
import std.stdio;
import std.meta;

alias to = caiman.conv.to;

public abstract class A
{
    abstract void a();
    abstract int b();
}

void main()
{
    writeln(new WhiteHole!A().b);
}