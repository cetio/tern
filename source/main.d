module main;

import std.stdio;
import caiman;

void main()
{
    Regex re = regex!(r"a").ctor();
    re.match("abc").writeln;
}