module tests.atomic;

import tern.atomic;
import std.parallelism;

unittest
{
    shared int val = 10;
    assert(val.atomicLoad == 10);
}

unittest
{
    shared int val = 10;
    val.atomicStore(7);
    assert(val.atomicLoad == 7);
}

unittest
{
    shared int val = 10;
    shared int val2 = 1;
    val.atomicExchange(val2);
    assert(val.atomicLoad == 1);
}

unittest
{
    shared int val = 10;
    assert(val.atomicOp!"+"(1) == 11);
}

unittest
{
    // This is THE worst way to use atomic variables!
    static shared ulong count = 0;
    static void addUp()
    {
        foreach(_ ; 0..1_000_000)
            atomicOp!"+="(count, 1);
    }  

    auto pool = new TaskPool(75);
    foreach(_; 0..150)
        pool.put(task!addUp());

    pool.finish(true);

    assert(count.atomicLoad == 150 * 1_000_000);
}