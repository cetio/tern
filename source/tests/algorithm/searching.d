module tests.algorithm.searching;

import tern.algorithm.searching;

unittest
{
    string[][] a = [["a", "d", "e"], ["b", "c", "f", "g"]];
    assert(a.indexOf!(x => x.contains("d")) == 0);
}
