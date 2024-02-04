/**
    Templates for custom inheritance, accessor generation, and arbitrary duck-typing
    WHAT THE FUCK IS INHERITANCE
                                                               __..-'
                                                         _.--''
                                               _...__..-'
                                             .'
                                           .'
                                         .'
                                       .'
            .------._                 ;
      .-"""`-.<')    `-._           .'
     (.--. _   `._       `'---.__.-'
      `   `;'-.-'         '-    ._
        .--'``  '._      - '   .
         `""'-.    `---'    ,
 ''--..__      `\
         ``''---'`\      .'
              jgs  `'. '
                     `'.
 */
module caiman.experimental.inheritance;

import std.traits;
import std.string;
import std.array;
import std.ascii;
import std.algorithm;
import caiman.traits;
import caiman.meta;

/// Attribute signifying an enum uses flags
enum flags;
/// Attribute signifying an enum should not have properties made
enum exempt;

public static pure string pragmatize(string str) 
{
    import std.ascii;
    import std.conv;
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
 *   mixin transparens;
 *
 *   string y() => "yohoho!";
 *  }
 *  ```
 */
public template inherit(T)
    if (isOrganic!T)
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
 *   mixin transparens;
 *
 *   string y() => "yohoho!";
 *  }
 *  ```
 */
// TODO: Use opDispatch to allow for multiple class/struct inherits
//       Find a faster way to do this, do not regenerate every call
//       Apply changes on parent to self
public template transparens(bool ignoreConflicts = false)
{
    static foreach (i, A; seqFilter!(isType, __traits(getAttributes, typeof(this))))
    {
        static assert(!hasModifiers!A, "Type with modifier cannot inherit from another type, must be a normal aggregate.");

        static foreach (field; FieldNames!A)
        {
            static if (hasParents!(TypeOf!(A, field)))
                mixin("import "~moduleName!(TypeOf!(A, field))~";");

            static if (!seqContains!(field, FieldNames!(typeof(this))))
                mixin(fullyQualifiedName!(TypeOf!(A, field))~" "~field~";");
            else static if (!ignoreConflicts)
                static assert(is(TypeOf!(typeof(this), field)) == TypeOf!(A, field), 
                    "Expected type of '"~TypeOf!(A, field).stringof~"' for inherited field '"~field~"' but got '"~TypeOf!(typeof(this), field).stringof~"'");
        }

        static foreach (func; FunctionNames!A)
        {
            static if (hasParents!(ReturnType!(__traits(getMember, A, func))))
                mixin("import "~moduleName!(ReturnType!(__traits(getMember, A, func)))~";");
        }

        static if (is(A == interface))
        {
            static foreach (func; FunctionNames!A)
            {
                static assert(seqContains!(func, FunctionNames!(typeof(this))) &&
                    is(ReturnType!(__traits(getMember, typeof(this), func)) == ReturnType!(__traits(getMember, A, func))) &&
                    is(Parameters!(__traits(getMember, typeof(this), func)) == Parameters!(__traits(getMember, A, func))) &&
                    functionAttributes!(__traits(getMember, typeof(this), func)) == functionAttributes!(__traits(getMember, A, func)) &&
                    functionLinkage!(__traits(getMember, typeof(this), func)) == functionLinkage!(__traits(getMember, A, func)), 
                    typeof(this).stringof~" does not implement function '"~__traits(identifier, __traits(getMember, A, func))~" "~__traits(getFunctionAttributes, __traits(getMember, A, func)).stringof~"' from "~A.stringof);
            }
        }
        else
        {   
            mixin("private "~A.stringof~" asParent"~A.stringof.pragmatize()~"() const {
            static if (is(T == class) || is(T == interface))
                "~A.stringof~" val = new "~A.stringof~"();
            else 
                "~A.stringof~" val;
            static if (hasChildren!("~A.stringof~"))
            import caiman.core.traits;
            static foreach (field; FieldNames!("~A.stringof~"))
                __traits(getMember, val, field) = mixin(field);
            return val; }");

            /* mixin("private "~A.stringof~" fromParent"~A.stringof.pragmatize()~"() const {
            static if (is(T == class) || is(T == interface))
                "~A.stringof~" val = new "~A.stringof~"();
            else 
                "~A.stringof~" val;
            static if (hasChildren!("~A.stringof~"))
            import caiman.core.traits;
            static foreach (field; FieldNames!("~A.stringof~"))
                __traits(getMember, val, field) = mixin(field);
            return val; }"); */

            static if (i == 0)
                mixin("alias asParent"~A.stringof.pragmatize()~" this;");
            else
            {
                /* mixin("import caiman.core.algorithm;
                import caiman.core.traits;
                auto opDispatch(string name, ARGS...)(ARGS args) 
                    if (seqContains!(name, FunctionNames!("~A.stringof~"))) {
                        mixin(\"return asParent"~A.stringof.pragmatize()~".\"~name~\"(\"~args.stringof~\");\");
                }"); */
            }
        }
    }

    /* static foreach (C; seqFilter!("X.stringof.length > 9 && X.stringof[0..9] == \"coalesced\"", __traits(getAttributes, typeof(this))))
    {
        static foreach (field; FieldNames!(TypeOf!(C, "dummy"))))
        {
            static if (hasParents!(TypeOf!((TypeOf!(C, "dummy"))), field))))
                mixin("import "~moduleName!(TypeOf!((TypeOf!(C, "dummy"))), field)))~";");

            static if (!seqContains!(field, FieldNames!(typeof(this))))
                mixin(fullyQualifiedName!(TypeOf!((TypeOf!(C, "dummy"))), field)))~" "~field~";");
            else static if (!ignoreConflicts)
                static assert(is(TypeOf!(typeof(this), field)) == TypeOf!((TypeOf!(C, "dummy"))), field))), 
                    "Expected type of '"~TypeOf!((TypeOf!(C, "dummy"))), field)).stringof~"' for coalesced field '"~field~"' but got '"~TypeOf!(typeof(this), field)).stringof~"'");
        }
    } */
}

/// Template mixin for auto-generating properties.\
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values) \
/// Assumes standardized postfixes! (MASK or Mask for masks) \
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
//       Clean up with caiman.core.algorithm
/// Does not support multiple fields with the same enum type!
// TODO: REWORK ASAP!!
/* public template accessors()
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
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_"~member[2..$]~"_get\") extern (C) export final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"() { return "~member~"; }");
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_"~member[2..$]~"_set\") extern (C) export final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"("~fullyQualifiedName!(TypeOf!(typeof(this), member))~" val) { "~member~" = val; return "~member~"; }");
                }

                // Flags
                static if (is(TypeOf!(typeof(this), member)) == enum) &&
                    staticIndexOf!(exempt, __traits(getAttributes, TypeOf!(typeof(this), member))) == -1 &&
                    staticIndexOf!(flags, __traits(getAttributes, TypeOf!(typeof(this), member))) != -1)
                {
                    static foreach (string flag; __traits(allMembers, TypeOf!(this, member)))
                    {
                        static if (flag.startsWith('k'))
                        {
                            static foreach_reverse (string mask; __traits(allMembers, TypeOf!(this, member)))[0..(staticIndexOf!(flag, __traits(allMembers, TypeOf!(this, member)))])
                            {
                                static if (mask.endsWith("Mask") || mask.endsWith("MASK"))
                                {
                                    static if (!__traits(hasMember, typeof(this), "is"~flag[1..$]))
                                    {
                                        // @property bool isEastern()...
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag[1..$]~"_get\") extern (C) export final @property bool is"~flag[1..$]~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                        // @property bool isEastern(bool state)...
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag[1..$]~"get\") extern (C) export final @property bool is"~flag[1..$]~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member))~")(state ? ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") | "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~" : ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") & ~"~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~")) == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                    }
                                }

                            }
                        }
                        else
                        {  
                            static if (!__traits(hasMember, typeof(this), "is"~flag))
                            {
                                // @property bool isEastern()...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~") != 0; }");
                                // @property bool isEastern(bool state)...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member)))~")(state ? ("~member[2..$]~" | "~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~") : ("~member[2..$]~" & ~"~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~"))) != 0; }");
                            }
                        }
                    }
                }

                // Non-flags
                static if (is(TypeOf!(typeof(this), member)) == enum) &&
                    staticIndexOf!(exempt, __traits(getAttributes, TypeOf!(typeof(this), member)))) == -1 &&
                    staticIndexOf!(flags, __traits(getAttributes, TypeOf!(typeof(this), member)))) == -1)
                {
                    static foreach (string flag; __traits(allMembers, TypeOf!(this, member))))
                    {
                        static if (!__traits(hasMember, typeof(this), "is"~flag))
                        {
                            // @property bool Eastern()...
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return "~member[2..$]~" == "~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~"; }");
                            // @property bool Eastern(bool state)...
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = "~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~") == "~fullyQualifiedName!(TypeOf!(this, member)))~"."~flag~"; }");
                        }
                    }
                }
            }
        }
    }
} */

unittest
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
        mixin transparens;

        string y() => "yohoho!";
    }

    C c;
    c.b = 2;
    assert(c.x() == 2);
    assert(c.y() == "yohoho!");
}

/** 
 * Wraps a type with modified or optional fields.
 *
 * Remarks:
 * - Cannot wrap an intrinsic type (ie: `string`, `int`, `bool`)
 * - Accepts syntax `Kin!A(TYPE, NAME, CONDITION...)` or `Kin!A(TYPE, NAME...)` interchangably.
 * - Use `Kin.asOriginal()` to extract `T` in the original layout.
 * 
 * Examples:
 * ```d
 * struct A { int a; }
 * Kin!(A, long, "a", false, int, "b") k1; // a is still a int, but now a field b has been added
 * Kin!(A, long, "a", true, int, "b") k2; // a is now a long and a field b has been added
 * ```
 */
// TODO: Find a faster way to do this, do not regenerate every call
//       Apply changes on parent to self
public struct Kin(T, ARGS...)
    if (isOrganic!T)
{
    // Import all the types for functions so we don't have any import errors
    static foreach (func; FunctionNames!T)
    {
        static if (hasParents!(ReturnType!(__traits(getMember, T, func))))
            mixin("import "~moduleName!(ReturnType!(__traits(getMember, T, func)))~";");
    }

    // Define overrides (ie: Kin!A(uint, "a") where "a" is already a member of A)
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
            }/* 
            static if (i % 2 == 0)
            {
                static assert(isType!ARG,
                    "Type expected, found " ~ ARG.stringof); 
            }
            else static if (i % 2 == 1 && ARG == field)
            {
                static assert(is(typeof(ARG) == string),
                    "Field name expected, found " ~ ARG.stringof); 

                static if (hasParents!(ARGS[i - 1]))
                    mixin("import "~moduleName!(ARGS[i - 1])~";");

                mixin(fullyQualifiedName!(ARGS[i - 1])~" "~ARG~";");
            } */
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
     * Extracts the content of this Kin as `T` in its original layout.
     *
     * Returns:
     * Contents of this Kin as `T` in its original layout.
     */
    T asOriginal()
    {
        static if (is(T == class) || is(T == interface))
            T val = new T();
        else 
            T val;
        static if (hasChildren!T)
        static foreach (field; FieldNames!T)
        {
            __traits(getMember, val, field) = cast(TypeOf!(val, field))mixin(field);
        }
        return val;
        /* ubyte[] bytes;
        static foreach (field; FieldNames!T)
        {
            static if (staticIndexOf!(field, FieldNames!T) > 0)
            {
                // Account for alignment, this is a huge block of code but it really is just
                // (last offset - current offset) - last sizeof
                // (8 - 4) - 2 = 2 (padded by 2)
                bytes ~= new ubyte[
                    (__traits(getMember, T, field).offsetof - __traits(getMember, T, FieldNames!T[staticIndexOf!(field, FieldNames!T) - 1]).offsetof)
                     - TypeOf!(T, FieldNames!T[staticIndexOf!(field, FieldNames!T) - 1])).sizeof];
            }

            {
                auto val = cast(TypeOf!(T, field)))__traits(getMember, this, field);
                bytes ~= (cast(ubyte*)&val)[0..TypeOf!(T, field)).sizeof];
            }
        }
        return *cast(T*)bytes.ptr; */
    }

    // Define the original type as an alias so operators & function calls work like normal
    alias asOriginal this;
}

unittest
{
    struct Person 
    {
        string name;
        int age;
    }

    Kin!(Person, long, "age", true, bool, "isStudent") modifiedPerson;

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