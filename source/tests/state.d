module tests.state;

import tern.state;

enum A
{
    A = 1,
    B = 2,
    C = 4,
    D = 8
}

unittest
{
    A a = A.A | A.D;
    assert(a.hasFlag(A.A));
    assert(!a.hasFlag(A.B));
    assert(!a.hasFlag(A.C));
    assert(a.hasFlag(A.D));
    a.toggleFlag(A.C);
    assert(a.hasFlag(A.C));
    a.setFlag(A.A, false);
    assert(!a.hasFlag(A.A));
}