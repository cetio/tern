module tern.main;

import tern;
import std.stdio;
import avocet;

void main()
{
   Box a = 2;
   writeln(a.value);
    writeln(X86.assemble("
        add dword gs:[0], dword 10
    "));
}