/// Intrinsic atomic type wrapping and side-channel blinding
module tern.typecons.atomic;

public import core.atomic;
import core.sync.mutex;
import core.thread;
import tern.traits;
import tern.meta;
import tern.object;

public alias a8 = shared Atomic!ubyte;
public alias a16 = shared Atomic!ushort;
public alias a32 = shared Atomic!uint;
public alias a64 = shared Atomic!ulong;
public alias af16 = shared Atomic!float;
public alias af32 = shared Atomic!double;

public alias b8 = Blind!ubyte;
public alias b16 = Blind!ushort;
public alias b32 = Blind!uint;
public alias b64 = Blind!ulong;

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

    this(T val)
    {
        value = cast(shared(T))val;
    }

    auto opAssign(A)(A ahs) shared
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
        if (mutex is null)
            mutex = new shared Mutex();

        mutex.lock();
        scope (exit) mutex.unlock();
        return value == ahs;
    }

    static if (!isScalarType!T)
    auto opEquals(A)(A ahs) shared
    {
        if (mutex is null)
            mutex = new shared Mutex();
            
        mutex.lock();
        scope (exit) mutex.unlock();
        return value == ahs;
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
    int opCmp(A)(const A ahs)
    {
        if (mutex is null)
            mutex = new shared Mutex();
            
        mutex.lock();
        scope (exit) mutex.unlock();
        return value.opCmp(ahs);
    }

    static if (!isScalarType!T)
    int opCmp(A)(const A ahs) shared
    {
        if (mutex is null)
            mutex = new shared Mutex();

        mutex.lock();
        scope (exit) mutex.unlock();
        return value.opCmp(ahs);
    }

    public auto opOpAssign(string op, R)(R rhs) shared
    {
        static if (isScalarType!T)
            return value.atomicOp!(op~'=')(cast(shared(T))rhs);
        else static if (op == "~")
        {
            if (mutex is null)
                    mutex = new shared Mutex();
                    
            mutex.lock();
            scope (exit) mutex.unlock();
            return value ~= rhs;
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
        return to!string(value);
    }
}

/// Helper function for creating an atomic
shared(Atomic!T) atomic(T)(T val)
{
    return Atomic!T(cast(shared(T))val);
}

/**
 * Prevents timing and power side channel attacks by obfuscating the processing of `T`
 *
 * This also makes `T` atomic.
 *
 * Remarks:
 *  - This obviously has performance impacts and is designed to be used in cryptography.
 *  - Only supports integral types for simplicity.
 */
 // TODO: This is NOT cryptographically secure
public struct Blind(T)
    if (isIntegral!T)
{
    T value;
    alias value this;

public:
final:
    ulong basis = uint.max;

    this(T val)
    {
        value = val;
    }

    ulong numNextOps()
    {
        ulong t = basis;
        ulong ops = 3;
        while (t % 32 != 0)
        {
            ops++;
            t -= 3;
        }
        return ops;
    }

    void obscure()
    {
        while (basis % 32 != 0)
            basis -= 3;

        basis += value;
        basis ^= 0xFFAC1ABB9;
        basis ^^= (value % basis) | 4;
    }

    auto opAssign(A)(A ahs)
    {
        scope (exit) obscure();
        value = ahs;
        return this;
    }

    auto opAssign(A)(A ahs) shared
    {
        scope (exit) obscure();
        value = ahs;
        return this;
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        scope (exit) obscure();
        mixin("value "~op~"= ahs;");
        return this;
    }

    auto opBinary(string op, R)(const R rhs)
    {
        scope (exit) obscure();
        return mixin("Blind!T(value "~op~" rhs)");
    }

    auto opBinary(string op, R)(const R rhs) shared
    {
        scope (exit) obscure();
        return mixin("Blind!T(value "~op~" rhs)");
    }

    auto opBinaryRight(string op, L)(const L lhs)
    {
        scope (exit) obscure();
        return mixin("Blind!T(lhs "~op~" value)");
    }

    auto opBinaryRight(string op, L)(const L lhs) shared
    {
        scope (exit) obscure();
        return mixin("Blind!T(lhs "~op~" value)");
    }

    auto opUnary(string op)() 
    {
        scope (exit) obscure();
        return mixin("Blind!T("~op~"value)");
    }

    auto opUnary(string op)() shared
    {
        obscure();
        return mixin("Blind!T("~op~"value)");
    }

    bool opEquals(A)(const A ahs)
    {
        obscure();
        return value == ahs;
    }

    bool opEquals(A)(const A ahs) shared
    {
        obscure();
        return value == ahs;
    }

    int opCmp(A)(const A ahs)
    {
        obscure();
        return cast(int)(value - ahs);
    }

    int opCmp(A)(const A ahs) shared
    {
        obscure();
        return cast(int)(value - ahs);
    }

    string toString() const
    {
        return to!string(value);
    }

    string toString() const shared
    {
        return to!string(value);
    }
}

/// Helper function for creating a blind.
Blind!T blind(T)(T val)
{
    return Blind!T(val);
}