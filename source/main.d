module source.main;

import std.stdio;
import caiman;

void main()
{
    Regex re = regex!(r"ab++c").ctor();
    re.match("ababbcc").writeln;
}