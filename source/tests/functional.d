module tests.functional;

import tern.functional;

int toInt(bool state) => cast(int)state;
ubyte toByte(bool state) => cast(ubyte)state;

unittest
{
    int[] a = [1, 2, 3, 4];
    assert((a.plane!((i, ref x, ref y) => x += ++y, (i, x) => x < 3)) == 5);
    assert(a == [2, 5, 3, 4]);

    auto tup = juxt!(toInt, toByte)(true);
    assert(tup[0] == 1 && tup[1] == 1);
}