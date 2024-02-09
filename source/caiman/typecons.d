module caiman.typecons;

import std.string;
import std.array;
import std.ascii;
import std.algorithm;
import caiman.conv;
import caiman.traits;
import caiman.meta;

/// Attribute signifying an enum uses flags
public enum flags;
/// Attribute signifying an enum should not have properties made
public enum exempt;

public static pure string mangle(string str) 
{
    size_t idx = str.lastIndexOf('.');
    if (idx != -1)
        str = str[(idx + 1)..$];
    str = str.replace("*", "PTR")
        .replace("[", "OPBRK")
        .replace("]", "CLBRK")
        .replace(",", "COMMA")
        .replace("!", "EXCLM");
    return str.filter!(c => isAlphaNum(c) || c == '_').array.to!string;
}

public class BlackHole(T)
    if (isAbstractClass!T)
{
    mixin(fullyQualifiedName!T~" val;
    alias val this;");
    static foreach (func; FunctionNames!T[0..$-5])
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

public class WhiteHole(T)
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
 * Sets `T` as an inherited type, this can be anything, so long as it isn't an intrinsic type. \
 * This is an attribute and should be used like `@inherit!T`
 *
 *  Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *   mixin apply;
 *
 *   string y() => "yohoho!";
 *  }
 *  ```
 */
public template inherit(T)
    if (hasChildren!T)
{
    alias inherit = T;
}

/** 
 * Sets up all inherits for the type that mixes this in. \
 * Must set inherited types by using `inherit(T)` beforehand.
 *
 *  Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *   mixin applyInherits;
 *
 *   string y() => "yohoho!";
 *  }
 *  ```
 */
// TODO: Use opDispatch to allow for multiple class/struct inherits
//       Find a faster way to do this, do not regenerate every call
//       Apply changes on parent to self
public template applyInherits()
{
    static foreach (i, A; seqFilter!(isType, __traits(getAttributes, typeof(this))))
    {
        static assert(!hasModifiers!A, "Type with modifier cannot inherit from another type, must be a normal aggregate.");
        
        static foreach (field; FieldNames!A)
        {
            static if (hasParents!(TypeOf!(A, field)))
                mixin("import "~moduleName!(TypeOf!(A, field)));

            static if (!hasMember!(typeof(this), field) && (seqFilter!("isType!X && hasMember!(X, \""~field~"\")", __traits(getAttributes, typeof(this))).length == 0 ||
                is(seqFilter!("isType!X && hasMember!(X, \""~field~"\")", __traits(getAttributes, typeof(this)))[0] == A)))
                mixin(FieldSignature!(__traits(getMember, A, field))~';');
            else
            {
                static assert(is(TypeOf!(typeof(this), field) == TypeOf!(A, field)), "Type mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
                static assert(isImmutable!(__traits(getMember, typeof(this), field)) && !isImmutable!(__traits(getMember, A, field)), "Mutability mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
                static assert(isStatic!(__traits(getMember, typeof(this), field)) == isStatic!(__traits(getMember, A, field)), "Static mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
            }
        }

        static foreach (func; FunctionNames!A)
        {
            static if (hasParents!(ReturnType!(TypeOf!(A, func))))
                mixin("import "~moduleName!(ReturnType!(TypeOf!(A, func)))~';'); 
        }

        mixin("X as(X : "~fullyQualifiedName!A~")() const => this.conv!X;");
        mixin(functionMap!(A, i == 0));
    }
}

/* unittest
{
    struct A
    {
        int b;

        int x() => b;
    }

    interface B
    {
        string y();
    }

    @inherit!A @inherit!B struct C
    {
        mixin apply;

        string y() => "yohoho!";
    }

    C c;
    c.b = 2;
    assert(c.x() == 2);
    assert(c.y() == "yohoho!");
} */

/// Template mixin for auto-generating properties. \
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values) \
/// Assumes standardized postfixes! (MASK or Mask for masks) \
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
//       Clean up with caiman.meta
/// Does not support multiple fields with the same enum type!
public template accessors()
{
    import std.traits;
    import std.string;
    import std.meta;

    static foreach (string member; __traits(allMembers, typeof(this)))
    {
        static if (member.startsWith("m_") && !__traits(compiles, { enum _ = mixin(member); }) &&
            isMutable!(TypeOf!(typeof(this), member)) &&
            (isFunction!(__traits(getMember, typeof(this), member)) || staticIndexOf!(exempt, __traits(getAttributes, __traits(getMember, typeof(this), member))) == -1))
        {
            static if (!__traits(hasMember, typeof(this), member[2..$]))
            {
                static if (!__traits(hasMember, typeof(this), member[2..$]))
                {
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_"~member[2..$]~"_get\") extern (C) export final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"() { return "~member~"; }");
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_"~member[2..$]~"_set\") extern (C) export final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"("~fullyQualifiedName!(TypeOf!(typeof(this), member))~" val) { "~member~" = val; return "~member~"; }");
                }

                // Flags
                static if (is(TypeOf!(typeof(this), member) == enum) &&
                    !seqContains!(exempt, __traits(getAttributes, TypeOf!(typeof(this), member))) &&
                    seqContains!(flags, __traits(getAttributes, TypeOf!(typeof(this), member))))
                {
                    static foreach (string flag; __traits(allMembers, TypeOf!(this, member)))
                    {
                        static if (flag.startsWith('k'))
                        {
                            static foreach_reverse (string mask; __traits(allMembers, TypeOf!(this, member))[0..staticIndexOf!(flag, __traits(allMembers, TypeOf!(this, member)))])
                            {
                                static if (mask.endsWith("Mask") || mask.endsWith("MASK"))
                                {
                                    static if (!__traits(hasMember, typeof(this), "is"~flag[1..$]))
                                    {
                                        // @property bool isEastern()...
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag[1..$]~"_get\") extern (C) export final @property bool is"~flag[1..$]~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                        // @property bool isEastern(bool state)...
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag[1..$]~"get\") extern (C) export final @property bool is"~flag[1..$]~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member))~")(state ? ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") | "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~" : ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") & ~"~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~")) == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                    }
                                }

                            }
                        }
                        else
                        {  
                            static if (!__traits(hasMember, typeof(this), "is"~flag))
                            {
                                // @property bool isEastern()...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") != 0; }");
                                // @property bool isEastern(bool state)...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member))~")(state ? ("~member[2..$]~" | "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") : ("~member[2..$]~" & ~"~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"))) != 0; }");
                            }
                        }
                    }
                }

                // Non-flags
                static if (is(TypeOf!(typeof(this), member) == enum) &&
                    !seqContains!(exempt, __traits(getAttributes, TypeOf!(typeof(this), member))) &&
                    !seqContains!(flags, __traits(getAttributes, TypeOf!(typeof(this), member))))
                {
                    static foreach (string flag; __traits(allMembers, TypeOf!(this, member)))
                    {
                        static if (!__traits(hasMember, typeof(this), "is"~flag))
                        {
                            // @property bool Eastern()...
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return "~member[2..$]~" == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                            // @property bool Eastern(bool state)...
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).mangle()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                        }
                    }
                }
            }
        }
    }
}

/** 
 * Wraps a type with modified or optional fields. \
 * Short for VariadicType.
 *
 * Remarks:
 * - Cannot wrap an intrinsic type (ie: `string`, `int`, `bool`)
 * - Accepts syntax `VadType!A(TYPE, NAME, CONDITION...)` or `VadType!A(TYPE, NAME...)` interchangably.
 * - Use `VadType.asOriginal()` to extract `T` in the original layout.
 * 
 * Example:
 * ```d
 * struct A { int a; }
 * VadType!(A, long, "a", false, int, "b") k1; // a is still a int, but now a field b has been added
 * VadType!(A, long, "a", true, int, "b") k2; // a is now a long and a field b has been added
 * ```
 */
 // TODO: \Static fields
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

    Person originalPerson = modifiedPerson.asOriginal();

    assert(modifiedPerson.name == "Bob");
    assert(modifiedPerson.age == 30);
    assert(is(typeof(modifiedPerson.age) == long));
    assert(modifiedPerson.isStudent == false);

    assert(originalPerson.name == "Bob");
    assert(originalPerson.age == 30);
}

/**
 * Very barebones implementation for nullable types. \
 * Does not support UFCS unfortunately.
 */
public struct Nullable(T)
    if (!isReferenceType!T)
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

    auto opAssign(R)(R val)
    {
        value = val;
        ptr = &value;
        return this;
    }

    auto opUnary(string op)()
    {
        static if (op.length == 2)
            ptr = &value;

        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("return Nullable!T("~op~"value);");
    }

    auto opEquals(R)(R val) const
    {
        alias N = typeof(null);
        static if (is(R == N))
            return ptr == null;
        else
            return value == val;
    }

    public auto opOpAssign(string op, ORASS)(ORASS rhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("return Nullable!T(value "~op~"= rhs);");
    }

    auto opBinary(string op, ORASS)(const ORASS rhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("return Nullable!T(value "~op~" rhs);");
    }

    auto opBinaryRight(string op, OLASS)(const OLASS lhs)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        mixin("return Nullable!T(lhs "~op~" value);");
    }

    auto opDispatch(string member, ARGS...)(ARGS args)
    {
        if (ptr == null)
            throw new Throwable("Null object reference T.T");

        static if (seqContains!(member, FieldNames!T))
            mixin("return value."~member~" = args[0];");
        else static if (seqContains!(member, FunctionNames!T))
            mixin("return value."~member~"(args);");
    }

    string toString() const
    {
        if (ptr == null)
            return "null";
        return value.to!string;
    }
}