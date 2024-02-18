/// Constructions for `SumType`, `UnionType`, and `VadType` (variadic)
module tern.typecons.variant;

import std.traits;
import std.conv;
import tern.codegen;
import tern.meta;

// TODO: Fix
/* public struct SumType(T...)
{
    static foreach (B; T)
    {
        static if (isIntegral!B && !isUnsigned!B)
            mixin(fullyQualifiedName!B~" i"~(B.sizeof * 8).to!string~';');
        else static if (isIntegral!B && isUnsigned!B)
            mixin(fullyQualifiedName!B~" u"~(B.sizeof * 8).to!string~';');
        else static if (isFloatingPoint!B)
            mixin(fullyQualifiedName!B~" f"~(B.sizeof * 8).to!string~';');
        else static if (B.stringof[0].isLower)
            mixin(fullyQualifiedName!B~" "~B.stringof.toCamelCase~';');
        else
            mixin(fullyQualifiedName!B~" _"~B.stringof.toCamelCase~';');
    }
}

public struct UnionType(T...)
{
    union
    {
        static foreach (B; T)
        {
            static if (isIntegral!B && !isUnsigned!B)
                mixin(fullyQualifiedName!B~" i"~(B.sizeof * 8).to!string~';');
            else static if (isIntegral!B && isUnsigned!B)
                mixin(fullyQualifiedName!B~" u"~(B.sizeof * 8).to!string~';');
            else static if (isFloatingPoint!B)
                mixin(fullyQualifiedName!B~" f"~(B.sizeof * 8).to!string~';');
            else static if (B.stringof[0].isUpper)
                mixin(fullyQualifiedName!B~" _"~B.stringof.toCamelCase~';');
            else
                mixin(fullyQualifiedName!B~" "~B.stringof.toCamelCase~';');
        }
    }
} */

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