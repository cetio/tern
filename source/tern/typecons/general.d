/// General-purpose wrapper/construct types for interacting with types
module tern.typecons.general;

import tern.serialization;
import tern.traits;
import tern.meta;

/// Implements all functions of an abstract class with an default/empty function.
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

/// Implements all functions of an abstract class with an assert trap.
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
 * Wraps `T` to allow it to be defined as null.  
 * No, this is not actually an optional, it is literally backed by a pointer and thus *actually* nullable.
 *
 * Remarks:
 *  - `opOpAssign` is not supported for fields of `T`
 *  - const Nullable(T) is not supported, but shared Nullable(T) is.
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

        static if (isScalarType!T)
            return cast(int)(value - ahs);
        else
            return mixin("value.opCmp(ahs)");
    }

    int opCmp(A)(A ahs) const shared
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (isScalarType!T)
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

public struct Singleton(T)
{
    static T value;
    alias value this;

public:
final:
    this(T val)
    {
        value = val;
    }
}