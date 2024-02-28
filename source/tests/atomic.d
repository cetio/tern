module tests.atomic;
import tern.atomic;

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