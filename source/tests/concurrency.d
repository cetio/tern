module tests.concurrency;

import tern.concurrency;
import std.stdio;
import core.thread;

bool isEven(int x)
{
    return x % 2 == 0;
}

unittest
{
    assert(await!isEven(6));

    int[] data = [1, 2, 3, 4, 5];
    parallelForeach!((i, ref x) 
    { 
        x *= 2; 
    })(data);
    assert(data == [2, 4, 6, 8, 10]);

    int sumFor = 0;
    parallelFor!((i) 
    { 
        sumFor += i; 
    })(1, 11, 1);
    assert(sumFor == 55);

    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    parallelForeachReverse!((i, x) 
    { 
        sumFor -= x; 
    })(data);
    assert(sumFor == 0);
}