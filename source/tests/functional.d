module tests.functional;

import tern.functional;
import std.traits;

int toInt(bool state) => cast(int)state;
ubyte toByte(bool state) => cast(ubyte)state;

unittest
{
    int[] a = [1, 2, 3, 4];
    assert((a.plane!((i, ref x, ref y) => x += ++y, (i, x) => x < 3)) == 5);
    assert(a == [2, 5, 3, 4]);

    auto tup = juxt!(toInt, toByte)(true);
    assert(tup[0] == 1 && tup[1] == 1);

    auto _ = denature!(() => 1)();
}

unittest
{
    size_t index = 0;
    int elem = 42;
    assert(barter!(() => 1)(index, elem) == 1);
    assert(barter!((ref i) => i)(index, elem) == index);
    assert(barter!((ref size_t i) => i)(index, elem) == index);
    assert(barter!((ref const i) => i)(index, elem) == index);
    assert(barter!((ref scope const i) => i)(index, elem) == index);
    alias FOLD = (x, y) => x + y;
    assert(barter!FOLD(elem) == 42);
    assert(barter!FOLD(elem) == 84);
    assert(is(ReturnType!(barter!(FOLD, size_t, int, void)) == ulong));
    assert(is(ReturnType!(barter!((int x, int y) => x + y, int, int, void)) == typeof(1 + 2)));
}