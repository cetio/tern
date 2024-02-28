module tests.eval;

import tern.eval;
import tern.string;

unittest
{
    import std.stdio;
    assert(eval("1 + 2").strip == "3");
    assert(eval("1 + 2 ^^ 8").strip == "257");
    assert(eval("x + 2 * 2").strip == "x + 4");
    assert(eval("x * y + 1").strip == "x * y + 1");
}