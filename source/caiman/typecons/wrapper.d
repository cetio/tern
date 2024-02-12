/// General-purpose wrapper/construct types for interacting with types
module caiman.typecons.wrapper;

import caiman.conv;
import caiman.traits;
import caiman.meta;
import core.atomic;
import core.sync.mutex;

/** 
 * Implements all functions of an abstract class with an default/empty function.
 */
public class BlackHole(T)
    if (isAbstractClass!T)
{
    mixin(fullyQualifiedName!T~" val;
    alias val this;");
    static foreach (func; FunctionNames!T)
    {
        static if (isAbstractFunction!(__traits(getMember, T, func)))
        {
            static if (!is(ReturnType!(__traits(getMember, T, func)) == void))
            {
                static if (isReferenceType!(ReturnType!(__traits(getMember, T, func))))
                    mixin(FunctionSignature!(__traits(getMember, T, func))~" { return new "~fullyQualifiedName!(ReturnType!(__traits(getMember, T, func)))~"(); }");
                else 
                    mixin(FunctionSignature!(__traits(getMember, T, func))~" { "~fullyQualifiedName!(ReturnType!(__traits(getMember, T, func)))~" ret; return ret; }");
            }
            else
                mixin(FunctionSignature!(__traits(getMember, T, func))~" { }");
        }
    }
}

/** 
 * Implements all functions of an abstract class with an assert trap.
 */
public class WhiteHole(T)
    if (isAbstractClass!T)
{
    mixin(fullyQualifiedName!T~" val;
    alias val this;");
    static foreach (func; FunctionNames!T[0..$-5])
    {
        static if (isAbstractFunction!(__traits(getMember, T, func)))
            mixin(FunctionSignature!(__traits(getMember, T, func))~" { assert(0); }");
    }
}

/** 
 * Wraps a type with modified or optional fields. \
 * Short for VariadicType.
 *
 * Remarks:
 *  Cannot wrap an intrinsic type (ie: `string`, `int`, `bool`)
 *  Accepts syntax `VadType!A(TYPE, NAME, CONDITION...)` or `VadType!A(TYPE, NAME...)` interchangably.
 *  Use `VadType.as!T` to extract `T` in the original layout.
 *  Does not support functions for local/voldemort types.
 * 
 * Example:
 * ```d
 * struct A { int a; }
 * VadType!(A, long, "a", false, int, "b") k1; // a is still a int, but now a field b has been added
 * VadType!(A, long, "a", true, int, "b") k2; // a is now a long and a field b has been added
 * ```
 */
 // TODO: Static fields
 //       Preserve variant fields after a call!!!!!!!!!!!!
public struct VadType(T, ARGS...)
    if (hasChildren!T)
{
    // Import all the types for functions so we don't have any import errors
    static foreach (func; FunctionNames!T)
    {
        static if (hasParents!(ReturnType!(__traits(getMember, T, func))))
            mixin("import "~moduleName!(ReturnType!(__traits(getMember, T, func)))~";");
    }

    // Define overrides (ie: VadType!A(uint, "a") where "a" is already a member of A)
    static foreach (field; FieldNames!T)
    {
        static foreach (i, ARG; ARGS)
        {
            static if (i % 3 == 1)
            {
                static assert(is(typeof(ARG) == string),
                    "Field name expected, found " ~ ARG.stringof); 

                static if (i == ARGS.length - 1 && ARG == field)
                {
                    static if (hasParents!(ARGS[i - 1]))
                        mixin("import "~moduleName!(ARGS[i - 1])~";");

                    mixin(fullyQualifiedName!(ARGS[i - 1])~" "~ARG~";");
                }
            }
            else static if (i % 3 == 2)
            {
                static assert(is(typeof(ARG) == bool) || isType!ARG,
                    "Type or boolean value expected, found " ~ ARG.stringof);
                    
                static if (is(typeof(ARG) == bool) && ARGS[i - 1] == field && ARG == true)
                {
                    static if (hasParents!(ARGS[i - 2]))
                        mixin("import "~moduleName!(ARGS[i - 2])~";");

                    mixin(fullyQualifiedName!(ARGS[i - 2])~" "~ARGS[i - 1]~";");
                }
                else static if (isType!ARG && is(typeof(ARGS[i - 1]) == string) && ARGS[i - 1] == field)
                {
                    static if (hasParents!(ARGS[i - 2]))
                        mixin("import "~moduleName!(ARGS[i - 2])~";");

                    mixin(fullyQualifiedName!(ARGS[i - 2])~" "~ARGS[i - 1]~";");
                }
            }
        }

        static if (hasParents!(TypeOf!(T, field)))
            mixin("import "~moduleName!(TypeOf!(T, field))~";");

        static if (!seqContains!(field, ARGS))
            mixin(fullyQualifiedName!(TypeOf!(T, field))~" "~field~";");
    }

    // Define all of the optional fields
    static foreach (i, ARG; ARGS)
    {
        static if (i % 3 == 1)
        {
            static assert(is(typeof(ARG) == string),
                "Field name expected, found " ~ ARG.stringof); 

            static if (i == ARGS.length - 1 && is(typeof(ARG) == string))
            {
                static if (hasParents!(ARGS[i - 1]))
                    mixin("import "~moduleName!(ARGS[i - 1])~";");

                static if (!seqContains!(ARG, FieldNames!T))
                    mixin(fullyQualifiedName!(ARGS[i - 1])~" "~ARG~";");
            }
        }
        else static if (i % 3 == 2)
        {
            static assert(is(typeof(ARG) == bool) || isType!ARG,
                "Type or boolean value expected, found " ~ ARG.stringof);
            
            static if (is(typeof(ARG) == bool) && ARG == true)
            {
                static if (hasParents!(ARGS[i - 2]))
                    mixin("import "~moduleName!(ARGS[i - 2])~";");

                static if (!seqContains!(ARGS[i - 1], FieldNames!T))
                    mixin(fullyQualifiedName!(ARGS[i - 2])~" "~ARGS[i - 1]~";");
            }
            else static if (isType!ARG && is(typeof(ARGS[i - 1]) == string))
            {
                static if (hasParents!(ARGS[i - 2]))
                    mixin("import "~moduleName!(ARGS[i - 2])~";");

                static if (!seqContains!(ARGS[i - 1], FieldNames!T))
                    mixin(fullyQualifiedName!(ARGS[i - 2])~" "~ARGS[i - 1]~";");
            }
        }
    }

    /**
     * Extracts the content of this VadType as `X` in its original layout.
     *
     * Returns:
     *  Contents of this VadType as `X` in its original layout.
     */
    X as(X)() const => this.conv!X;
    // idgaf, this is just so local/voldemort types don't get pissy
    static if (__traits(compiles, { mixin(functionMap!(T, true)); }))
        mixin(functionMap!(T, true));
}

unittest
{
    struct Person 
    {
        string name;
        int age;
    }

    VadType!(Person, long, "age", true, bool, "isStudent") modifiedPerson;

    modifiedPerson.name = "Bob";
    modifiedPerson.age = 30;
    modifiedPerson.isStudent = false;

    Person originalPerson = modifiedPerson.as!Person();

    assert(modifiedPerson.name == "Bob");
    assert(modifiedPerson.age == 30);
    assert(is(typeof(modifiedPerson.age) == long));
    assert(modifiedPerson.isStudent == false);

    assert(originalPerson.name == "Bob");
    assert(originalPerson.age == 30);
}

/**
 * Wraps `T` to allow it to be defined as null. \
 * No, this is not actually an optional, it is literally backed by a pointer and thus *actually* nullable.
 *
 * Remarks:
 *  `opOpAssign` is not supported for fields of `T`
 *  const Nullable(T) is not supported, but shared Nullable(T) is.
 *
 * Example:
 * ```d
 * Nullable!int b;
 * writeln(b == null); // true
 * b = 0;
 * b += 2;
 * writeln(b); // 2
 * writeln(b == null); // false
 * ```
 */
public struct Nullable(T)
{
    T value;
    alias value this;

public:
final:
    T* ptr;

    this(T val)
    {
        value = val;
        ptr = &value;
    }

    auto opAssign(R)(R ahs)
    {
        value = ahs;
        ptr = &value;
        return this;
    }

    auto opAssign(R)(R ahs) shared
    {
        value = ahs;
        ptr = &value;
        return this;
    }

    A opCast(A)() const
    {
        return Nullable!A(cast(A)value);
    }
    
    A opCast(A)() const shared
    {
        return Nullable!A(cast(A)value);
    }

    auto opUnary(string op)()
    {
        static if (op.length == 2)
            ptr = &value;

        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)("~op~"value))");
    }

    auto opUnary(string op)() shared
    {
        static if (op.length == 2)
            ptr = &value;

        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)("~op~"value))");
    }

    auto opEquals(A)(A ahs) const
    {
        alias N = typeof(null);
        static if (is(R == N))
            return ptr == null;
        else
            return value == ahs;
    }

    auto opEquals(A)(A ahs) const shared
    {
        alias N = typeof(null);
        static if (is(R == N))
            return ptr == null;
        else
            return value == ahs;
    }

    int opCmp(R)(const R other) const
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (isScalarType!T)
            return cast(int)(value - other);
        else
            return mixin("value.opCmp(other)");
    }

    int opCmp(R)(const R other) const shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (isScalarType!T)
            return cast(int)(value - other);
        else
            return mixin("value.opCmp(other)");
    }

    auto opOpAssign(string op, R)(R rhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("value "~op~"= rhs;");
        return this;
    }

    auto opOpAssign(string op, R)(R rhs) shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("value "~op~"= rhs;");
        return this;
    }

    auto opBinary(string op, R)(const R rhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)(value "~op~" rhs))");
    }

    auto opBinary(string op, R)(const R rhs) shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)(value "~op~" rhs))");
    }

    auto opBinaryRight(string op, L)(const L lhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)(lhs "~op~" value));");
    }

    auto opBinaryRight(string op, L)(const L lhs) shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        return mixin("Nullable!T(cast(T)(lhs "~op~" value));");
    }

    // TODO: Support template args
    auto opDispatch(string member, ARGS...)(ARGS args)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (seqContains!(member, FieldNames!T))
            mixin("return value."~member~" = args[0];");
        else static if (seqContains!(member, FunctionNames!T))
            mixin("return value."~member~"(args);");
    }

    auto opDispatch(string member, ARGS...)(ARGS args) shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        else static if (seqContains!(member, FunctionNames!T) || 
            __traits(compiles, { mixin("return value."~member~"(args);"); }) ||
            !__traits(compiles, { mixin("return value."~member~" = args[0];"); }))
            mixin("return value."~member~"(args);");
        else
            mixin("return value."~member~" = args[0];");
    }

    string toString() const
    {
        if (ptr == null)
            return "null";

        return value.to!string;
    }

    string toString() const shared
    {
        if (ptr == null)
            return "null";

        return value.to!string;
    }
}

pragma(inline)
Nullable!T nullable(T)(T val)
{
    return Nullable!T(val);
}

/**
 * Wraps `T` to make every operation atomic, if possible.
 *
 * Remarks:
 *  `opOpAssign` is not supported for fields of `T`
 */
 // There are some shenanigans with operator overloading that seems to cause a segfault,
 // not sure how to make a good check for this, so for safety mutexes are sometimes used instead of
 // `core.atomic` if `T` isn't a scalar.
public struct Atomic(T, MemoryOrder M = MemoryOrder.seq)
{
    shared T value;
    alias value this;

public:
final:
    shared Mutex mutex;

    auto opAssign(R)(R ahs) shared
    {
        static if (isScalarType!T)
            value.atomicStore!M(ahs);
        else
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                value = cast(shared(T))ahs;");
        }
        return this;
    }

    A opCast(A)() const shared
    {
        return Atomic!(A, M)(cast(shared(A))value);
    }

    auto opUnary(string op)() shared
    {
        static if (isScalarType!T)
            return mixin("Atomic!(T, M)("~op~"value.atomicLoad!M())");
        else
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                return Atomic!(T, M)(cast(shared(T))("~op~"value));");
        }
    }

    static if (isScalarType!T)
    auto opEquals(A)(A ahs) const
    {
        return mixin("value.atomicLoad!M() == ahs");
    }

    static if (isScalarType!T)
    auto opEquals(A)(A ahs) const shared
    {
        return mixin("value.atomicLoad!M() == ahs");
    }

    static if (!isScalarType!T)
    auto opEquals(A)(A ahs)
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value == ahs;");
    }

    static if (!isScalarType!T)
    auto opEquals(A)(A ahs) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value == ahs;");
    }

    static if (isScalarType!T)
    int opCmp(R)(const R other) const
    {
        return cast(int)(value.atomicLoad() - other);
    }

    static if (isScalarType!T)
    int opCmp(R)(const R other) const shared
    {
        return cast(int)(value.atomicLoad() - other);
    }

    static if (!isScalarType!T)
    int opCmp(R)(const R other)
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value.opCmp(other);");
    }

    static if (!isScalarType!T)
    int opCmp(R)(const R other) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value.opCmp(other);");
    }

    public auto opOpAssign(string op, R)(R rhs) shared
    {
        static if (isScalarType!T)
            return value.atomicOp!(op~'=')(cast(shared(T))rhs);
        else static if (op == "~")
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                return value ~= rhs;");
        }
        else
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                return Atomic!(T, M)(cast(shared(T))(value "~op~" rhs));");
        }
    }

    auto opBinary(string op, R)(const R rhs) shared
    {
        static if (isScalarType!T)
            return mixin("Atomic!(T, M)(value.atomicLoad!M() "~op~" rhs)");
        else
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                return Atomic!(T, M)(cast(shared(T))(value "~op~" rhs));");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) shared
    {
        static if (isScalarType!T)
            return mixin("Atomic!(T, M)(cast(shared(T))(lhs "~op~" value.atomicLoad!M()))");
        else
        {
            mixin("if (mutex is null)
                    mutex = new shared Mutex();
                mutex.lock();
                scope (exit) mutex.unlock();
                return Atomic!(T, M)(cast(shared(T))(lhs "~op~" value));");
        }
    }

    static if (__traits(compiles, { return value[index]; }))
    ref auto opIndex(size_t index) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[index];");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opIndexAssign(A)(A ahs, size_t index) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[index] = ahs;");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opIndexOpAssign(string op, A)(A ahs, size_t index) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[index] "~op~"= ahs;");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opIndexUnary(string op)(size_t index) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return "~op~"value[index];");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opSlice(size_t start, size_t end) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[start..end];");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opSliceAssign(A)(A ahs, size_t start, size_t end) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[start..end] = ahs;");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opSlice(size_t DIM : 0)(size_t start, size_t end) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[DIM][start..end];");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opSliceOpAssign(string op, A)(A ahs, size_t start, size_t end) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[start..end] "~op~"= ahs;");
    }

    static if (__traits(compiles, { return value[index]; }))
    auto opSliceUnary(string op)(size_t start, size_t end) shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return "~op~"value[start..end];");
    }

    static if (__traits(compiles, { return value[index]; }))
    size_t opDollar() shared
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value.length;");
    }

    static if (__traits(compiles, { return value[index]; }))
    size_t opDollar(size_t DIM : 0)() 
    {
        mixin("if (mutex is null)
                mutex = new shared Mutex();
            mutex.lock();
            scope (exit) mutex.unlock();
            return value[DIM].length;");
    }

    template opDispatch(string member) 
    {
        template opDispatch(TARGS...) 
        {
            auto opDispatch(ARGS...)(ARGS args) shared
            {
                static if (seqContains!(member, FunctionNames!T) || 
                    __traits(compiles, { mixin("return value.atomicLoad!M()."~member~"!TARGS(args);"); }) ||
                    (__traits(compiles, { mixin("return value.atomicLoad!M()."~member~';'); }) && ARGS.length == 0) ||
                    !__traits(compiles, { mixin("return value."~member~" = args[0];"); }))
                {
                    static if (TARGS.length == 0 && ARGS.length == 0)
                    {
                        mixin("if (mutex is null)
                                mutex = new shared Mutex();
                            mutex.lock();
                            scope (exit) mutex.unlock();
                            return value."~member~";");
                    }
                    else
                    {
                        mixin("if (mutex is null)
                                mutex = new shared Mutex();
                            mutex.lock();
                            scope (exit) mutex.unlock();
                            return value."~member~"!TARGS(args);");
                    }
                }
                else
                {
                    mixin("if (mutex is null)
                                mutex = new shared Mutex();
                            mutex.lock();
                            scope (exit) mutex.unlock();
                            return value."~member~" = args[0];");
                }
            }
        }
    }

    string toString() const shared
    {
        return value.to!string;
    }
}

pragma(inline)
Atomic!(T, M) atomic(MemoryOrder M = MemoryOrder.seq, T)(T val)
    if (!is(T == shared))
{
    return Atomic!(T, M)(cast(shared(T))val);
}

pragma(inline)
Atomic!(T, M) atomic(MemoryOrder M = MemoryOrder.seq, T)(T val)
    if (is(T == shared))
{
    return Atomic!(T, M)(val);
}

struct Compound(T...)
{
    T value;
    alias value this;
}

pragma(inline)
Compound!T compound(T...)(T args)
{
    return Compound!T(args);
}