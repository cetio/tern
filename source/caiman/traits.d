/// Largely fills in any gaps of std.traits, while also providing some unique reflection.
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
/// True if `F` is exported, otherwise, false.
public alias isExport(alias F) = Alias!(__traits(getVisibility, func) == "export");
/// True if `A` is a template, otherwise, false.
public alias isTemplate(alias A) = Alias!(__traits(isTemplate, A));
/// True if `A` is a module, otherwise, false.
public alias isModule(alias A) = Alias!(__traits(isModule, A));
/// True if `A` is a package, otherwise, false.
public alias isPackage(alias A) = Alias!(__traits(isPackage, A));
/// True if `A` is a field, otherwise false. \
/// This is functionally equivalent to `!isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A`
public alias isField(alias A) = Alias!(!isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A);
/// True if `A` has any parents, otherwise, false.
public alias hasParents(alias A) = Alias!(__traits(compiles, __traits(parent, A)));
/// True if `A` has any children, otherwise, false.
public alias hasChildren(alias A) = Alias!(__traits(allMembers, A).length != 0);

/// True if `T` wraps indirection, like an array or wrapper for a pointer, otherwise, false.
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

/**
    Gets an `AliasSeq` all types that `T` implements.

    This is functionally very similar to `InterfacesTuple(T)` from `std.traits`, but is more advanced and \
    includes *all* implements, including class inherits and alias this.
*/
public template getImplements(T)
{
    /* private template Flatten(H, T...)
    {
        static if (T.length)
        {
            alias Flatten = AliasSeq!(Flatten!H, Flatten!T);
        }
        else
        {
            static if ((is(H == interface) || is(H == class)) && !is(H == Object))
                alias Flatten = AliasSeq!(H, getImplements!H);
            else
                alias Flatten = getImplements!H;
        }
    } */

    // Checks if T has any inherit, if so, calls Flatten to get the inherit and call getImplements again
    // Recursively gets every super (inherit/base)
    static if (is(T S == super) && S.length)
    {
        static if (__traits(getAliasThis, T).length != 0)
            alias getImplements = AliasSeq!(S, typeof(__traits(getMember, T, __traits(getAliasThis, T))), getImplements!(typeof(__traits(getMember, T, __traits(getAliasThis, T)))));
        else
            alias getImplements = S;
    }
    else
    {
        static if (__traits(getAliasThis, T).length != 0)
            alias getImplements = AliasSeq!(typeof(__traits(getMember, T, __traits(getAliasThis, T))), getImplements!(typeof(__traits(getMember, T, __traits(getAliasThis, T)))));
        else
            alias getImplements = AliasSeq!();
    }  
}

/// Gets an AliasSeq of all fields in `A`
public template getFields(alias A)
{
    alias getFields = AliasSeq!();

    static foreach (member; __traits(allMembers, A))
    {
        static if (isField!(__traits(getMember, A, member)))
            getFields = AliasSeq!(getFields, member);
    }
}

/// Gets an AliasSeq of all functions in `A`
public template getFunctions(alias A)
{
    alias getFunctions = AliasSeq!();

    static foreach (member; __traits(allMembers, A))
    {
        static if (isFunction!(__traits(getMember, A, member)))
            getFunctions = AliasSeq!(getFunctions, member);
    }
}

/// Gets an AliasSeq of all types in `A`
public template getTypes(alias A)
{
    alias getTypes = AliasSeq!();

    static foreach (member; __traits(allMembers, A))
    {
        static if (isType!(__traits(getMember, A, member)))
            getTypes = AliasSeq!(getTypes, member);
    }
}

/// Gets an AliasSeq of all templates in `A`
public template getTemplates(alias A)
{
    alias getTemplates = AliasSeq!();

    static foreach (member; __traits(allMembers, A))
    {
        static if (isTemplate!(__traits(getMember, A, member)))
            getTemplates = AliasSeq!(getTemplates, member);
    }
}

/// Gets an `AliasSeq` of all modules publicly imported by `mod`
public template getImports(alias M)
{
    private pure string[] _getImports()
    {
        string[] imports;
        foreach (line; import(__traits(identifier, M)~".d").splitter('\n'))
        {
            long ii = line.indexOf("public import ");
            if (ii != -1)
            {
                long si = line.indexOf(";", ii + 13);
                if (si != -1)
                    imports ~= line[(ii + 13).. si].strip;
            }
        }
        return imports;
    }

    mixin("alias getImports = AliasSeq!("~ 
        _getImports.join(", ")~ 
    ");");
}

/// Gets a `void*[]` of all indirections contained in `T val`
pure void*[] indirections(T)(T val)
{
    void*[] ptrs;
    static foreach (field; getFields!T)
    {
        static if (isIndirection!T)
            ptrs ~= cast(void*)&__traits(getMember, val, field);
    }
    return ptrs;
}

pure string pragmatize(string str) 
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

/// Template mixin for auto-generating properties.\
/// Assumes standardized prefixes! (m_ for backing fields, k for masked enum values) \
/// Assumes standardized postfixes! (MASK or Mask for masks) \
// TODO: Overloads (allow devs to write specifically a get/set and have the counterpart auto generated)
//       ~Bitfield exemption?~
//       Conditional get/sets? (check flag -> return a default) (default attribute?)
//       Flag get/sets from pre-existing get/sets (see methodtable.d relatedTypeKind)
//       Auto import types (generics!!)
//       Allow for indiv. get/sets without needing both declared
//       Exports for flags!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag[1..$]~"_get\") extern (C) export final @property bool is"~flag[1..$]~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                                        // @property bool isEastern(bool state)...
                                        mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag[1..$]~"get\") extern (C) export final @property bool is"~flag[1..$]~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~")(state ? ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") | "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~" : ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~mask~") & ~"~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~")) == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                                    }
                                }

                            }
                        }
                        else
                        {  
                            static if (!__traits(hasMember, typeof(this), "is"~flag))
                            {
                                // @property bool isEastern()...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return ("~member[2..$]~" & "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") != 0; }");
                                // @property bool isEastern(bool state)...
                                mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = cast("~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~")(state ? ("~member[2..$]~" | "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") : ("~member[2..$]~" & ~"~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"))) != 0; }");
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
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"() { return "~member[2..$]~" == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                            // @property bool Eastern(bool state)...
                            mixin("pragma(mangle, \""~__traits(identifier, typeof(this)).pragmatize()~"_is"~flag~"_get\") extern (C) export final @property bool is"~flag~"(bool state) { return ("~member[2..$]~" = "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~") == "~fullyQualifiedName!(typeof(__traits(getMember, this, member)))~"."~flag~"; }");
                        }
                    }
                }
            }
        }
    }
}