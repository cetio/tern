module tests.memory;
import tern.memory;

unittest
{
    int a = 0;
    int b = 1;
    copy(&b, &a, 4);
    assert(a == b);
}