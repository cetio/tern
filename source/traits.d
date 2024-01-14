module caiman.traits;

import std.string;
import std.algorithm;
import std.array;
import std.meta;
import std.traits;

/// Attribute signifying an enum uses flags
enum flags;
/// Attribute signifying an enum should not have properties made
enum exempt;

public:
static:
/// True if `T` is a class, interface, pointer, or a wrapper for a pointer (like arrays.)
public alias isIndirection(T) = Alias!(is(T == class) || is(T == interface) || isPointer!T || wrapsIndirection!T);
/// True if `T` is an indirection, otherwise, false.
public alias isReference(T) = isIndirection!T;
/// True if `T` is not an indirection, otherwise, false.
public alias isValueType(T) = Alias!(!isIndirection!T);
/// True if `func` is exported, otherwise, false.
public alias isExport(alias func) = Alias!(__traits(getVisibility, func) == "export");
/// True if `T` acts as a native integer, otherwise, false.
public alias isNative(T) = Alias!(__traits(isScalar, T) || ((is(T == struct) || is(T == union) || is(T == enum)) && (T.sizeof == 1 || T.sizeof == 2 || T.sizeof == 4 || T.sizeof == 8)));

public template wrapsIndirection(T)
{
    static if (__traits(compiles, __traits(allMembers, T)))
        enum wrapsIndirection = hasIndirections!T && __traits(allMembers, T).length <= 2;
    else
        enum wrapsIndirection = isArray!T;
}

/// Gets the element type of T, if applicable.
public template elementType(T) 
{
    static if (is(T == U[], U))
        alias elementType = elementType!U;
    else
        alias elementType = T;
}

/// Gets an AliasSeq of all modules publicly imported by `mod`
public template imports(alias mod)
{
    pure string[] _imports()
    {
        string[] ret;
        foreach (line; import((__traits(identifier, mod)).replace("", "") ~ ".d").splitter('\n'))
        {
            long ii = line.indexOf("public import ");
            if (ii != -1)
            {
                long si = line.indexOf(";", ii + 13);
                if (si != -1)
                    ret ~= line[(ii + 13).. si].strip;
            }
        }
        return ret;
    }

    mixin("alias Imports = AliasSeq!("~ 
        _imports.join(", ")~ 
    ");");
}

/// Gets a `void*[]` of all indirections contained in `T val`
pure void*[] indirections(T)(T val)
{
    void*[] ptrs;
    static foreach (field; FieldNameTuple!T)
    {
        static if (isIndirection!T)
            ptrs ~= cast(void*)&__traits(getMember, val, field);
    }
    return ptrs;
}

pure string pragmatize(string str) 
{
    // holy import, is there a better way?
    import std.algorithm;
    import std.ascii;
    import std.array;
    import std.conv;
    import std.string;
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

/// Template mixin for auto-generating properties.\
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values) \
/// Assumes standardized postfixes! (MASK or Mask for masks) \
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
/// Does not support multiple fields with the same enum type!
public template accessors()
{
    import std.traits;
    import std.string;
    import std.meta;

    static foreach (string member; __traits(allMembers, typeof(this)))
    {
        static if (member.startsWith("m_") && !__traits(compiles, { enum _ = mixin(member); }) &&
            isMutable!(typeof(__traits(getMember, typeof(this), member))) &&
            (isFunction!(__traits(getMember, typeof(this), member)) || staticIndexOf!(exempt, __traits(getAttributes, __traits(getMember, typeof(this), member))) == -1))
        {
            static if (!__traits(hasMember, typeof(this), member[2..$]))
            {
                static if (!__traits(hasMember, typeof(this), member[2..$]))
                {
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_"~member[2..$]~"_get\") extern (C) export final @property "~fullyQualifiedName!(typeof(__traits(getMember, typeof(this), member)))~" "~member[2..$]~"() { return "~member~"; }");
                    mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_"~member[2..$]~"_set\") extern (C) export final @property "~fullyQualifiedName!(typeof(__traits(getMember, typeof(this), member)))~" "~member[2..$]~"("~fullyQualifiedName!(typeof(__traits(getMember, typeof(this), member)))~" val) { "~member~" = val; return "~member~"; }");
                }

                // Flags
                static if (is(typeof(__traits(getMember, typeof(this), member)) == enum) &&
                    staticIndexOf!(exempt, __traits(getAttributes, typeof(__traits(getMember, typeof(this), member)))) == -1 &&
                    staticIndexOf!(flags, __traits(getAttributes, typeof(__traits(getMember, typeof(this), member)))) != -1)
                {
                    static foreach (string flag; __traits(allMembers, typeof(__traits(getMember, this, member))))
                    {
                        static if (flag.startsWith('k'))
                        {
                            static foreach_reverse (string mask; __traits(allMembers, typeof(__traits(getMember, this, member)))[0..(staticIndexOf!(flag, __traits(allMembers, typeof(__traits(getMember, this, member)))))])
                            {
                                static if (mask.endsWith("Mask") || mask.endsWith("MASK"))
                                {
                                    static if (!__traits(hasMember, typeof(this), "is"~flag[1..$]))
                                    {
                                        // @property bool isEastern()...
                                        mixin("@property bool is"~flag[1..$]~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                                        // @property bool isEastern(bool state)...
                                        mixin("@property bool is"~flag[1..$]~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~")(state ? ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") | "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~" : ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") & ~"~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~")) == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                                    }
                                }

                            }
                        }
                        else
                        {  
                            static if (!__traits(hasMember, typeof(this), "is"~flag))
                            {
                                // @property bool isEastern()...
                                mixin("@property bool is"~flag~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") != 0; }");
                                // @property bool isEastern(bool state)...
                                mixin("@property bool is"~flag~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~")(state ? ("~member[2..$]~" | "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") : ("~member[2..$]~" & ~"~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"))) != 0; }");
                            }
                        }
                    }
                }

                // Non-flags
                static if (is(typeof(__traits(getMember, typeof(this), member)) == enum) &&
                    staticIndexOf!(exempt, __traits(getAttributes, typeof(__traits(getMember, typeof(this), member)))) == -1 &&
                    staticIndexOf!(flags, __traits(getAttributes, typeof(__traits(getMember, typeof(this), member)))) == -1)
                {
                    static foreach (string flag; __traits(allMembers, typeof(__traits(getMember, this, member))))
                    {
                        static if (!__traits(hasMember, typeof(this), "is"~flag))
                        {
                            // @property bool Eastern()...
                            mixin("@property bool is"~flag~"() { return "~member[2..$]~" == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                            // @property bool Eastern(bool state)...
                            mixin("@property bool is"~flag~"(bool state) { return ("~member[2..$]~" = "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                        }
                    }
                }
            }
        }
    }
}