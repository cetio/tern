/// Templates for blitting arbitrary functions or other comptime data onto a type
module caiman.typecons.blit;

import std.array;
import std.ascii;
import std.algorithm;
import caiman.traits;
import caiman.conv;
import caiman.string;

/// Attribute signifying an enum uses flags
public enum flags;
/// Attribute signifying an enum should not have properties made
public enum exempt;

/** 
 * Sets `T` as an inherited type, this can be anything, so long as it isn't an intrinsic type.  
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
 * Sets up all inherits for the type that mixes this in.  
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

/// Template mixin for auto-generating properties.  
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values)  
/// Assumes standardized postfixes! (MASK or Mask for masks)  
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