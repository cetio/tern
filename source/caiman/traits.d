/// Traits templates intended to fill the gaps in `std.meta`
module caiman.traits;

import std.string;
import std.algorithm;
import std.array;
import std.meta;
import std.traits;
import caiman.meta;

public:
static:
/// True if `T` is a class, interface, pointer, or a wrapper for a pointer (like arrays.)
public alias isIndirection(T) = Alias!(is(T == class) || is(T == interface) || isPointer!T || wrapsIndirection!T);
/// True if `T` is an indirection, otherwise, false.
public alias isReferenceType(T) = isIndirection!T;
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
public alias hasParents(alias A) = Alias!(!isType!A || !isIntrinsicType!A);
/// True if `T` is a basic type, built-in type, or array, otherwise, false.
public alias isIntrinsicType(T) = Alias!(isBasicType!T || isBuiltinType!T || isArray!T);
/// True if `A` has any children, otherwise, false.
public alias hasChildren(alias A) = Alias!(!isType!A || isOrganic!A);
/// True if `A` is not mutable (const, immutable, enum, etc.), otherwise, false.
public alias isImmutable(alias A) = Alias!(!isMutable!A || (isField!A && __traits(compiles, { enum _ = mixin(A.stringof); })));
/// True if `T` is an enum, array, or pointer, otherwise, false.
public alias hasModifiers(T) = Alias!(isArray!T || isPointer!T || !isAggregateType!T);
/// True if 'T' does not have any modifiers and is not an intrinsic type, otherwise, false.
public alias isOrganic(T) = Alias!(!hasModifiers!T && !isIntrinsicType!T);
/// True if `T` has any member "__ctor", otherwise, false.
public alias hasCtor(T) = Alias!(hasMember!(T, "__ctor"));
/// True if `A` inherits `B`, otherwise, false. \
/// If you mean to get all inherits of `A`, use `Implements(T)`
public alias inherits(A, B) = Alias!(seqContains!(B, Implements!A));

/// True if `T` wraps indirection, like an array or wrapper for a pointer, otherwise, false.
public template wrapsIndirection(T)
{
    static if (hasChildren!T)
        enum wrapsIndirection = hasIndirections!T && __traits(allMembers, T).length <= 2;
    else
        enum wrapsIndirection = isArray!T;
}

/// Gets the type of member `MEMBER` in `A` \
/// This will return a function alias if `MEMBER` refers to a function, and do god knows what if `MEMBER` is a package or module.
public template TypeOf(alias A, string MEMBER)
{
    static if (isType!(__traits(getMember, A, MEMBER)) || isTemplate!(__traits(getMember, A, MEMBER)) || isFunction!(__traits(getMember, A, MEMBER)))
        alias TypeOf = __traits(getMember, A, MEMBER);
    else
        alias TypeOf = typeof(__traits(getMember, A, MEMBER));
}

/// Gets the element type of `T`, if applicable. \
/// Returns the type of enum values if `T` is an enum.
public template ElementType(T) 
{
    static if (is(T == U[], U) || is(T == U*, U) || is(T U == U[L], ptrdiff_t L))
        alias ElementType = ElementType!U;
    else
        alias ElementType = OriginalType!T;
}

/** 
 * Gets the signature of `F` as a string. \
 * This includes all attributes, templates (must be already initialized, names are lost,) and parameters.
 *
 * Params:
 *  F = Function to get the signature of.
 */
public template FunctionSignature(alias F)
    if (isFunction!F)
{
    enum FunctionSignature = 
    {
        string paramSig = "(";
        static if (__traits(compiles, { alias _ = TemplateArgsOf!F; }))
        {
            static foreach (i, A; TemplateArgsOf!F)
            {
                static if (__traits(compiles, { enum _ = B; }))
                    paramSig ~= fullyQualifiedName!(typeof(B))~" T"~i.stringof[0..$-2];
                else
                    paramSig ~= "alias T"~i.stringof[0..$-2];
            }
            paramSig ~= ")(";
        }
        
        foreach (i, P; Parameters!F)
            paramSig ~= fullyQualifiedName!P~" "~ParameterIdentifierTuple!F[i]~(i == Parameters!F.length - 1 ? null : ", ");
        paramSig ~= ')';

        return seqStringOf!(" ", __traits(getFunctionAttributes, F))~" "~fullyQualifiedName!(ReturnType!F)~" "~__traits(identifier, F)~paramSig;
    }();
}

/** 
 * Gets the signature of `F` as a string without any types present.
 *
 * Params:
 *  F = Function to get the signature of.
 */
// Uses a lot of redundant code but that's fine
public template FunctionCallableSignature(alias F)
    if (isFunction!F)
{
    enum FunctionCallableSignature = 
    {
        string paramSig = "(";
        static if (__traits(compiles, { alias _ = TemplateArgsOf!F; }))
        {
            static foreach (i, A; TemplateArgsOf!F)
            {
                static if (__traits(compiles, { enum _ = B; }))
                    paramSig ~= "T"~i.stringof[0..$-2];
                else
                    paramSig ~= "T"~i.stringof[0..$-2];
            }
            paramSig ~= ")(";
        }
        
        foreach (i, P; Parameters!F)
            paramSig ~= ParameterIdentifierTuple!F[i]~(i == Parameters!F.length - 1 ? null : ", ");
        paramSig ~= ')';

        return __traits(identifier, F)~paramSig;
    }();
}

/**
    Gets an `AliasSeq` all types that `T` implements.

    This is functionally very similar to `InterfacesTuple(T)` from `std.traits`, but is more advanced and \
    includes *all* implements, including class inherits and alias this.
*/
public template Implements(T)
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
            alias Implements = AliasSeq!(S, TypeOf!(T, __traits(getAliasThis, T)), Implements!(TypeOf!(T, __traits(getAliasThis, T))));
        else
            alias Implements = S;
    }
    else
    {
        static if (__traits(getAliasThis, T).length != 0)
            alias Implements = AliasSeq!(TypeOf!(T, __traits(getAliasThis, T)), Implements!(TypeOf!(T, __traits(getAliasThis, T))));
        else
            alias Implements = AliasSeq!();
    }  
}

/// Gets an AliasSeq of all fields in `A`
public template FieldNames(alias A)
{
    alias FieldNames = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isField!(__traits(getMember, A, member)))
            FieldNames = AliasSeq!(FieldNames, member);
    }
}

/// Gets an AliasSeq of all functions in `A`
public template FunctionNames(alias A)
{
    alias FunctionNames = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isFunction!(__traits(getMember, A, member)))
            FunctionNames = AliasSeq!(FunctionNames, member);
    }
}

/// Gets an AliasSeq of all types in `A`
public template TypeNames(alias A)
{
    alias TypeNames = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isType!(__traits(getMember, A, member)))
            TypeNames = AliasSeq!(TypeNames, member);
    }
}

/// Gets an AliasSeq of all templates in `A`
public template TemplateNames(alias A)
{
    alias TemplateNames = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isTemplate!(__traits(getMember, A, member)))
            TemplateNames = AliasSeq!(TemplateNames, member);
    }
}

/// Gets an `AliasSeq` of all modules publicly imported by `mod`
public template Imports(alias M)
{
    private pure string[] _Imports()
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

    mixin("alias Imports = AliasSeq!("~ 
        _Imports.join(", ")~ 
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