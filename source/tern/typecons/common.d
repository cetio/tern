module tern.typecons.common;

import tern.memory : memcpy;
import tern.traits;
import tern.object : qdup, factory;
import std.conv;

/// Implements all functions of an abstract class with an default/empty function.
public class BlackHole(T)
    if (isAbstractClass!T)
{
    mixin(fullIdentifier!T~" val;
    alias val this;");
    static foreach (func; Functions!T)
    {
        static if (isAbstractFunction!(getChild!(T, func)))
        {
            static if (isNoReturn!(getChild!(T, func)))
                mixin(FunctionSignature!(getChild!(T, func))~" { return "~fullIdentifier!(ReturnType!(getChild!(T, func)))~".init; }");
            else
                mixin(FunctionSignature!(getChild!(T, func))~" { }");
        }
    }
}

/// Implements all functions of an abstract class with an assert trap.
public class WhiteHole(T)
    if (isAbstractClass!T)
{
    mixin(fullIdentifier!T~" val;
    alias val this;");
    static foreach (func; Functions!T[0..$-5])
    {
        static if (isAbstractFunction!(getChild!(T, func)))
            mixin(FunctionSignature!(getChild!(T, func))~" { assert(0); }");
    }
}

/**
 * Wraps `T` to allow it to be defined as null.  
 * No, this is not actually an optional, it is literally backed by a pointer and thus *actually* nullable.
 *
 * Remarks:
 *  - `opOpAssign` is not supported for fields of `T`.
 *  - const Nullable(T) is not supported, but shared Nullable(T) is.
 */
private alias NULL = typeof(null);
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

    this(NULL val)
    {

    }

    auto opAssign(A)(A ahs)
    {
        value = ahs;
        ptr = &value;
        return this;
    }

    auto opAssign(A)(A ahs) shared
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
        static if (is(A == NULL))
            return ptr == null;
        else
            return value == ahs;
    }

    auto opEquals(A)(A ahs) const shared
    {
        static if (is(A == NULL))
            return ptr == null;
        else
            return value == ahs;
    }

    int opCmp(A)(A ahs) const
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (isScalar!T)
            return cast(int)(value - ahs);
        else
            return mixin("value.opCmp(ahs)");
    }

    int opCmp(A)(A ahs) const shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (isScalar!T)
            return cast(int)(value - ahs);
        else
            return mixin("value.opCmp(ahs)");
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

    template opDispatch(string member) 
    {
        template opDispatch(TARGS...) 
        {
            auto opDispatch(string member, ARGS...)(ARGS args)
            {
                if (ptr == null)
                    throw new Throwable("Null object reference T.T");

                static if (seqContains!(member, Fields!T))
                    mixin("return value."~member~" = args[0];");
                else static if (seqContains!(member, Functions!T))
                    mixin("return value."~member~"(args);");
            }

            auto opDispatch(string member, ARGS...)(ARGS args) shared
            {
                if (ptr == null)
                    throw new Throwable("Null object reference T.T");

                else static if (seqContains!(member, Functions!T) || 
                    __traits(compiles, { mixin("return value."~member~"(args);"); }) ||
                    !__traits(compiles, { mixin("return value."~member~" = args[0];"); }))
                    mixin("return value."~member~"(args);");
                else
                    mixin("return value."~member~" = args[0];");
            }
        }
    }

    string toString() const
    {
        if (ptr == null)
            return "null";

        return to!string(value);
    }

    string toString() const shared
    {
        if (ptr == null)
            return "null";

        return to!string(value);
    }

    void nullify()
    {
        ptr = null;
    }

    void unnullify()
    {
        ptr = &value;
    }
}

/// Helper function for creating a nullable.
Nullable!T nullable(T)(T val)
{
    return Nullable!T(val);
}

/// Helper function for creating a nullable.
Nullable!T nullable(T)(NULL val)
{
    return Nullable!T(null);
}

/// Highly mutable range wrapper for working with any indexable or sliceable type.
public struct Range(T)
{
    T value;
    alias value this;

public:
final:
    this(T val)
    {
        value = val.qdup;
    }

    auto opAssign(T)(T val)
    {
        return value = val.qdup;
    }

    void popFront()
    {
        value = this[1..$];
    }

    void popBack()
    {
        value = this[0..$-1];
    }

    string toString()
    {
        return value.to!string;
    }

@nogc:
    A opCast(A)()
    {
        return cast(A)value;
    }
    
    size_t length()
    {
        static if (__traits(compiles, { auto _ = opDollar(); }))
            return opDollar();
        static assert("Range!"~T.stringof~" has no length!");
    }

    ref auto opIndex(size_t index)
    {
        static if (__traits(compiles, { auto _ = value[0]; }))
            return value[index];
        static assert("Range!"~T.stringof~" has no indexing!");
    }

    auto opIndexAssign(A)(A ahs, size_t index)
        if (A.sizeof <= ElementType!T.sizeof)
    {
        static if (__traits(compiles, { auto _ = (value[0] = ahs); }))
            return value[index] = ahs;
        else static if (__traits(compiles, { auto _ = value[0]; }))
        {
            memcpy(cast(void*)&ahs, cast(void*)&value[index], A.sizeof);
            return value[index];
        }
        static assert("Range!"~T.stringof~" has no indexing!");
    }

    auto opSlice(size_t start, size_t end)
    {
        static if (__traits(compiles, { auto _ = value[start..end]; }))
            return value[start..end];
        static assert("Range!"~T.stringof~" has no slicing!");
    }

    auto opSliceAssign(A)(A ahs, size_t start, size_t end) 
        if (ElementType!A.sizeof <= ElementType!T.sizeof)
    {
        static if (__traits(compiles, { auto _ = (value[start..end] = ahs); }))
            return value[start..end] = ahs;
        else static if (__traits(compiles, { auto _ = value[start]; }))
        {
            memcpy(cast(void*)ahs.ptr, cast(void*)&value[start], ElementType!A.sizeof * ahs.length);
            return value[start..end];
        }
        return value;
    }

    size_t opDollar(size_t DIM : 0)()
    {
        static if (__traits(compiles, { auto _ = value.opDollar!DIM; }))
            return value.opDollar!DIM;
        else static if (DIM == 0)
            return opDollar();
        else
        {
            size_t length;
            foreach (u; value[DIM])
                length++;
            return length;
        }
        static assert("Range!"~T.stringof~" has no length!");
    }

    size_t opDollar()
    {
        static if (__traits(compiles, { auto _ = value.opDollar(); }))
            return value.opDollar();
        else static if (__traits(compiles, { auto _ = value.length; }))
            return value.length;
        else
        {
            size_t length;
            foreach (u; value)
                length++;
            return length;
        }
        static assert("Range!"~T.stringof~" has no length!");
    }

    auto front()
    {
        return this[0];
    }

    auto back()
    {
        return this[$-1];
    }

    bool empty()
    {
        return length == 0;
    }
}