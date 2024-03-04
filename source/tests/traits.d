module tests.traits;

import tern.traits;
import tern.meta;

unittest
{
    class A { int a; final @system void foo() { } }
    struct B { int a; }
    abstract class C { int a;  abstract @safe void foo() { } }

    assert(isClass!A);
    assert(isClass!C);
    assert(!isClass!B);
    assert(isStruct!B);

    assert(!isAbstract!A);
    assert(!isAbstract!B);
    assert(isAbstract!C);

    assert(isSafe!(C.foo));
    assert(isUnsafe!(A.foo));
    assert(isAbstract!(C.foo));
    assert(isFinal!(A.foo));

    assert(isSame!(Package!A, tests));
    assert(isSame!(Module!A, tests.traits));

    assert(isReinterpretable!(int, const(int)));
    assert(isReinterpretable!(uint, long));
    assert(!isReinterpretable!(int, void));
    assert(!isReinterpretable!(string, void*));
    assert(isReinterpretable!(char, void));
    assert(!isReinterpretable!(A, B));
    assert(isReinterpretable!(A, void*));
    assert(!isReinterpretable!(A, B*));
    assert(isReinterpretable!(B, int));
}