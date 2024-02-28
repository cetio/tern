module tests.integer;

import tern.integer;

unittest
{
    hept a;
    uint b = 14;
    a -= 9;
    assert(a == -9);
    assert(a * 2 == -18);
    assert(a += b == -4);

    UInt!(32) c;
    assert(c.max == uint.max);
    c += 14;
    a = c;
    assert(c == b);
    assert(a == c);
}