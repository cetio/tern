module main;

import std.stdio;
import caiman;

void main()
{
    Regex re = regex!(r"^abc$").ctor();
    re.match("ababc").writeln;
}