module tests.memory;
import tern.memory;

unittest
{
    void* ptr = malloc(10);
    assert(ptr !is null);
    void* oldPtr = ptr;
    realloc(ptr, 20);
    assert(oldPtr == ptr);
    free(ptr);
}

unittest
{
    int a = 0;
    int b = 1;
    copy(&b, &a, 4);
    assert(a == b);
}

unittest
{
    int c = 42;
    zeroSecureMemory(&c, c.sizeof);
    assert(c == 0);
}