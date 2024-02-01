module caiman.main;

import caiman;
import std;

void main()
{
    simplifyEq("x ^^ (2 & 1)").writeln;
    writeln(ElementType!(caiman.meta.traits.ElementType!string).stringof);
}