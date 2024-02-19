module main;

import tern;
import std.stdio;
import std.datetime;
import avocet;

void main()
{
    writeln(X86.assemble("
        add dword gs:[0], dword 10
    "));
}