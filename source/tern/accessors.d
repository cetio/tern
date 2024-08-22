/// Automated accessor/property generation with support for flags.
module tern.accessors;

import tern.traits;

/// Attribute signifying an enum uses flags.
public enum flags;
/// Attribute signifying an enum should not have properties made.
public enum exempt;

/// Template mixin for auto-generating properties.  
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values)  
/// Assumes standardized postfixes! (MASK or Mask for masks)  
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
/// Does not support multiple fields with the same enum type!
public template accessors()
{
    import tern.traits;
    import std.traits : fullyQualifiedName;
    import std.string;
    import tern.meta;

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
                    mixin("final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"() { return "~member~"; }");
                    mixin("final @property "~fullyQualifiedName!(TypeOf!(typeof(this), member))~" "~member[2..$]~"("~fullyQualifiedName!(TypeOf!(typeof(this), member))~" val) { "~member~" = val; return "~member~"; }");
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
                                        mixin("final @property bool is"~flag[1..$]~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                        // @property bool isEastern(bool state)...
                                        mixin("final @property bool is"~flag[1..$]~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member))~")(state ? ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") | "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~" : ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~mask~") & ~"~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~")) == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                                    }
                                }

                            }
                        }
                        else
                        {  
                            static if (!__traits(hasMember, typeof(this), "is"~flag))
                            {
                                // @property bool isEastern()...
                                mixin("final @property bool is"~flag~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") != 0; }");
                                // @property bool isEastern(bool state)...
                                mixin("final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(TypeOf!(this, member))~")(state ? ("~member[2..$]~" | "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") : ("~member[2..$]~" & ~"~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"))) != 0; }");
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
                            mixin("final @property bool is"~flag~"() { return "~member[2..$]~" == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                            // @property bool Eastern(bool state)...
                            mixin("final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~") == "~fullyQualifiedName!(TypeOf!(this, member))~"."~flag~"; }");
                        }
                    }
                }
            }
        }
    }
}