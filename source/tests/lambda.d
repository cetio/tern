module tests.lambda;

import tern.lambda;
import std.traits;

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
}