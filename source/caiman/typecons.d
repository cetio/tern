module caiman.typecons;

import caiman.conv;
import caiman.traits;
import std.traits;

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
 * Wraps a type with modified or optional fields.
 *
 * Remarks:
 * - Cannot wrap an intrinsic type (ie: `string`, `int`, `bool`)
 * - Accepts syntax `Kin!A(TYPE, NAME, CONDITION...)` or `Kin!A(TYPE, NAME...)` interchangably.
 * - Use `Kin.asOriginal()` to extract `T` in the original layout.
 * 
 * Example:
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
    T asOriginal() => this.conv!T;
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