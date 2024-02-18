module tern.main;

import tern;
import std.stdio;
import avocet;

void main()
{
    b32 a;
    writeln(a.numNextOps);
    a = 1;
    writeln(a.numNextOps);
    writeln(a + 1);
    writeln(a.numNextOps);
    writeln(a + 1);
    writeln(a.numNextOps);
    writeln(X86.assemble("
        add dword gs:[0], dword 10
    "));
}