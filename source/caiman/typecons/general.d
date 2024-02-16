/// General-purpose wrapper/construct types for interacting with types
module caiman.typecons.general;

import caiman.conv;
import caiman.traits;
import caiman.meta;

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
 * Wraps a type with modified or optional fields.  
 * Short for VariadicType.
 *
 * Remarks:
 *  - Cannot wrap an intrinsic type (ie: `string`, `int`, `bool`)
 *  - Accepts syntax `VadType!A(TYPE, NAME, CONDITION...)` or `VadType!A(TYPE, NAME...)` interchangably.
 *  - Use `VadType.as!T` to extract `T` in the original layout.
 *  - Does not support functions for local/voldemort types.
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

/// Arbitrary length tuple-type construct allowing for any number of values to be stored of any type.
struct Compound(T...)
{
    T value;
    alias value this;
}

/// Helper function for creating a compound with arguments
pragma(inline)
Compound!T compound(T...)(T args)
{
    return Compound!T(args);
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
public struct Nullable(T)
{
    T value;
    alias value this;

public:
final:
    alias NULL = typeof(null);
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

    Nullable!T opImplicitCastFrom(A)(A ahs)
    {
        static if (is(A == NULL))
            return Nullable!T.init;
        else
            return Nullable!T(cast(T)ahs);
    }

    Nullable!T opImplicitCastFrom(A)(A ahs) shared
    {
        static if (is(A == NULL))
            return Nullable!T.init;
        else
            return Nullable!T(cast(T)ahs);
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

    bool isNull()
    {
        return ptr == null;
    }

    void nullify()
    {
        ptr = null;
    }
}

/// Arbitrary vector implementation, allows any length vector less than or equal to 256 bits and can be interacted with as an array.
public struct Vector(T)
    if (is(T U : U[L], ptrdiff_t L) && (isIntegral!U || isFloatingPoint!U))
{
    enum is256 = length * ElementType!T.sizeof > 16;
    static if (is256)
    {
        static if (ElementType!T.sizeof % 8 == 0)
            ElementType!T[4] data;
        else static if (ElementType!T.sizeof % 4 == 0)
            ElementType!T[8] data;
        else static if (ElementType!T.sizeof % 2 == 0)
            ElementType!T[16] data;
        else
            ElementType!T[32] data;
    }
    else
    {
        static if (ElementType!T.sizeof % 8 == 0)
            ElementType!T[2] data;
        else static if (ElementType!T.sizeof % 4 == 0)
            ElementType!T[4] data;
        else static if (ElementType!T.sizeof % 2 == 0)
            ElementType!T[8] data;
        else
            ElementType!T[16] data;
    }
    alias data this;

public:
final:
    enum length = Length!T;
    static if (ElementType!T.sizeof == 1)
        alias P = mixin(ElementType!T.stringof~"16");
    else static if (ElementType!T.sizeof == 2)
        alias P = mixin(ElementType!T.stringof~"8");
    else static if (ElementType!T.sizeof == 4)
        alias P = mixin(ElementType!T.stringof~"4");
    else static if (ElementType!T.sizeof == 8)
        alias P = mixin(ElementType!T.stringof~"2");

    auto opAssign(A)(A ahs)
    {
        data.blit(ahs);
        return this;
    }

    auto opBinary(string op, R)(const R rhs) const
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
    }

    auto opBinary(string op, R)(const R rhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                (cast(P*)&vec)[1] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                (cast(P*)&vec)[0] "~op~"= cast(ElementType!T)rhs;
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const 
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opBinaryRight(string op, L)(const L lhs) const shared
    {
        static if (is256)
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[1];
                return vec;");
        }
        else
        {
            mixin("Vector!T vec = this;
                cast(ElementType!T)lhs "~op~"= (cast(P*)&vec)[0];
                return vec;");
        }
    }

    auto opOpAssign(string op, A)(A ahs)
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;");
        }
        return this;
    }

    auto opOpAssign(string op, A)(A ahs) shared
    {
        static if (is256)
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;
                (cast(P*)&this)[1] "~op~"= (cast(P*)&this)[1];");
        }
        else
        {
            mixin("(cast(P*)&this)[0] "~op~"= cast(ElementType!T)ahs;");
        }
        return this;
    }

    auto opEquals(A)(A ahs) const
    {
        return (*cast(T*)&data) == ahs;
    }

    auto opEquals(A)(A ahs) const shared
    {
        return (*cast(T*)&data) == ahs;
    }

    size_t opDollar() const
    {
        return length;
    }

    size_t opDollar() const shared
    {
        return length;
    }

    string toString() const
    {
        return (*cast(T*)&data).to!string;
    }

    string toString() const shared
    {
        return (*cast(T*)&data).to!string;
    }
}