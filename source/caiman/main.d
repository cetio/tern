module caiman.main;

import caiman;
import std;

alias ElementType = caiman.meta.traits.ElementType;

void main()
{
    simplifyEq("x ^^ (2 & 1)").writeln;
    writeln(ElementType!(caiman.meta.traits.ElementType!string).stringof);
}