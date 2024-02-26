/// Templates for code generation, accessors, inheritance, etc.
module tern.codegen;

import std.array;
import std.ascii;
import std.algorithm;
import tern.traits;
import tern.serialize;
import tern.string;

/// Attribute signifying an enum uses flags
public enum flags;
/// Attribute signifying an enum should not have properties made
public enum exempt;

/** 
 * Sets `T` as an inherited type, this can be anything, so long as it isn't an intrinsic type.  
 *
 * This is an attribute and should be used like `@inherit!T`
 *
 * Example:
 * ```d
 * struct A {int b; int x() => b; }
 *
 * interface B { string y(); }
 *
 * @inherit!A @inherit!B struct C 
 * {
 *     mixin apply;
 *
 *     string y() => "yohoho!";
 * }
 * ```
 */
public template inherit(T)
    if (hasChildren!T)
{
    alias inherit = T;
}

/** 
 * Sets up all inherits for the type that mixes this in. 
 * 
 * Must set inherited types by using `inherit(T)` beforehand.
 *
 * Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *      mixin apply;
 *
 *      string y() => "yohoho!";
 *  }
 * ```
 */
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
                static assert(!isMutable!(__traits(getMember, typeof(this), field)) && isMutable!(__traits(getMember, A, field)), "Mutability mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
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

/// Template mixin for auto-generating properties.  
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values)  
/// Assumes standardized postfixes! (MASK or Mask for masks)  
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
//       Clean up with tern.meta
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
 * Generates a mixin for implementing all possible functions of `T`
 * 
 * Remarks:
 *  - Any function that returns true for `isDImplDefined` is discarded.  
 *  - `nothrow`, `pure`, and `const` attributes are discarded.  
 *  - `opCall`, `opAssign`, `opIndex`, `opSlice`, `opCast` and `opDollar` are discarded even if `mapOperators` is true.
 */
 // TODO: typeof(this) attributes (ie: shared)
public template functionMap(T, bool mapOperators = false)
    if (hasChildren!T)
{
    enum functionMap =
    {
        string str = "import "~moduleName!T~";
            import tern.blit;";
        static foreach (func; FunctionNames!T)
        {
            static if (!isDImplDefined!(TypeOf!(T, func)))
            {
                static if (is(ReturnType!(TypeOf!(T, func)) == void))
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" {
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        orig."~FunctionCallableSignature!(TypeOf!(T, func))~";  }\n");
                else
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" {
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this))); 
                        return orig."~FunctionCallableSignature!(TypeOf!(T, func))~"; }\n");
            }
        }
        static if (mapOperators)
            str ~= "public auto opOpAssign(string op, ORASS)(ORASS rhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opOpAssign!op(rhs);
                }

                public auto opBinary(string op, ORASS)(const ORASS rhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opBinary!op(rhs);
                }

                public auto opBinaryRight(string op, OLASS)(const OLASS lhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opBinaryRight!op(lhs);
                }
                
                static if (is(typeof(this) == class))
                {
                    public override int opCmp(Object other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }
                }
                else
                {
                    public int opCmp(ORCMP)(const ORCMP other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }

                    public int opCmp(Object other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }
                }

                static if (is(typeof(this) == class))
                {
                    public override bool opEquals(Object other) 
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }
                }
                else
                {
                    public bool opEquals(OREQ)(const OREQ other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }

                    public bool opEquals(Object other) 
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }
                }

                public auto opIndexAssign(OTIASS)(OTIASS value, size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexAssign(value, index);
                }

                public auto opIndexOpAssign(string op, OTIASS)(OTIASS value, size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexOpAssign!op(value, index);
                }

                public auto opIndexUnary(string op)(size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexUnary(index);
                }

                public auto opSliceAssign(OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign(value, start, end);
                }

                public auto opSlice(size_t DIM : 0)(size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSlice!DIM(start, end);
                }

                public auto opSliceAssign(size_t DIM : 0, OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign!DIM(value, start, end);
                }

                public auto opSliceOpAssign(string op, OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign!op(value, start, end);
                }

                public auto opSliceUnary(string op)(size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceUnary!op(start, end);
                }

                public auto opUnary(string op)()
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opUnary!op();
                }";
        return str;
    }();
}

/** 
 * Generates a random boolean with the odds `1/max`
 *
 * Params:
 *  max = Maximum odds, this is what the chance is out of.
 */
public alias randomBool(uint max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__) 
    = Alias!(random!(uint, 0, max, seed, R0, R1, R2, R3) == 0);

/** 
 * Generates a random floating point value.
 *
 * Params:
 *  min = Minimum value.
 *  max = Maximum value.
 *  seed = The seed to generate with, useful if you do multiple random generations in one line, as it causes entropy.
 */
public template random(T, T min, T max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__) 
    if (is(T == float) || is(T == double))
{
    pure T random()
    {
        return random!(ulong, cast(ulong)(min * cast(T)1000), cast(ulong)(max * cast(T)1000), seed, R0, R1, R2, R3) / cast(T)1000;
    }
}

/** 
 * Generates a random integral value.
 *
 * Params:
 *  min = Minimum value.
 *  max = Maximum value.
 *  seed = The seed to generate with, useful if you do multiple random generations in one line, as it causes entropy.
 */
public template random(T, T min, T max, uint seed = uint.max, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)
    if (isIntegral!T)
{
    pure T random()
    {
        static if (min == max)
            return min;

        ulong s0 = (seed * R0) || 1;
        ulong s1 = (seed * R0) || 1;
        ulong s2 = (seed * R0) || 1;
        
        static foreach (c; R1)
            s0 *= (c * (R0 ^ seed)) || 1;
        static foreach (c; R2)
            s1 *= (c * (R0 - seed)) || 1;
        static foreach (c; R3)
            s2 *= (c * (R0 ^ seed)) || 1;
        
        ulong o = s0 + s1 + s2;
        return min + (cast(T)o % (max - min));
    }
}