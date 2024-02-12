/// Traits templates intended to fill the gaps in `std.meta`
module caiman.traits;

import std.string;
import std.algorithm;
import std.array;
import std.meta;
import caiman.meta;
import caiman.conv;
public import std.traits;

public:
static:
/// True if `T` is a class, interface, pointer, or a wrapper for a pointer (like arrays.)
public alias isIndirection(T) = Alias!(is(T == class) || is(T == interface) || isPointer!T || wrapsIndirection!T);
/// True if `T` is an indirection.
public alias isReferenceType(T) = Alias!(is(T == class) || is(T == interface) || isPointer!T || isArray!T);
/// True if `T` is not an indirection.
public alias isValueType(T) = Alias!(!isIndirection!T);
/// True if `F` is exported.
public alias isExport(alias F) = Alias!(__traits(getVisibility, func) == "export");
/// True if `A` is a template.
public alias isTemplate(alias A) = Alias!(__traits(isTemplate, A));
/// True if `A` is a module.
public alias isModule(alias A) = Alias!(__traits(isModule, A));
/// True if `A` is a package.
public alias isPackage(alias A) = Alias!(__traits(isPackage, A));
/// True if `A` is a field, otherwise false. \
/// This is functionally equivalent to `!isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A`
public alias isField(alias A) = Alias!(!isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A);
/// True if `A` has any parents.
public alias hasParents(alias A) = Alias!(Derequirement!(A, false, isType, false, isIntrinsicType) && !isPackage!A);
/// True if `T` is a basic type, built-in type, or array.
public alias isIntrinsicType(T) = Alias!(isBasicType!T || isBuiltinType!T || isArray!T);
/// True if `A` has any children.
public alias hasChildren(alias A) = Alias!(isModule!A || isPackage!A || Prerequirement!(A, true, isType, false, isIntrinsicType, false, hasModifiers));
/// True if `A` is not mutable (const, immutable, enum, etc.).
public template isImmutable(alias A)
{
    static if (isType!A)
        enum isImmutable = !isMutable!A;
    else static if (isField!A)
        enum isImmutable = !isMutable!(typeof(A)) || isEnum!A;
    else
        enum isImmutable = true;
}
/// True if `T` is an enum, array, or pointer.
public alias hasModifiers(T) = Alias!(isArray!T || isPointer!T || !isAggregateType!T);
/// True if `T` has any instance constructor ("__ctor").
public alias hasConstructor(T) = Alias!(hasMember!(T, "__ctor"));
/// True if `A` implements `B`. \
/// If you want to get all implements of 'A', see `Implements(T)`
public alias isImplement(A, B) = Alias!(seqContains!(B, Implements!A));
/// Gets an alias to the package in which `A` is defined, undefined behavior for any alias that does not have a package (any intrinsic type.)
public alias getPackage(alias A) = Alias!(mixin(fullyQualifiedName!A.indexOf('.') == -1 ? fullyQualifiedName!A : fullyQualifiedName!A[0..fullyQualifiedName!A.indexOf('.')]));
/// True if `A` is not D implementation defined.
public alias isOrganic(alias A) = Alias!(!isDImplDefined!A);
/// True if `F` is a constructor;
public alias isConstructor(alias F) = Alias!(isFunction!F && (__traits(identifier, F).startsWith("__ctor") || __traits(identifier, F).startsWith("_staticCtor")));
/// True if `F` is a destructor.
public alias isDestructor(alias F) = Alias!(isFunction!F && (__traits(identifier, F).startsWith("__dtor") || __traits(identifier, F).startsWith("__xdtor") || __traits(identifier, F).startsWith("_staticDtor")));
/// True if `F` is `toHash` or `toString`
public alias isDManyThing(alias F) = Alias!(isFunction!F && (__traits(identifier, F).startsWith("toHash") || __traits(identifier, F).startsWith("toString")));
/// True if `F` is a static field.
public alias isStatic(alias F) = Alias!(isField!F && !isEnum!F && __traits(compiles, { auto _ = __traits(getMember, __traits(parent, F), __traits(identifier, F)); }));
/// True if `F` is an enum field.
public alias isEnum(alias F) = Alias!(__traits(compiles, { enum _ = __traits(getMember, __traits(parent, F), __traits(identifier, F)); }));

public template isDImplDefined(alias A)
{
    static if ((isModule!A || (isType!A && !isIntrinsicType!A)) && (getPackage!A.stringof == "package std" || getPackage!A.stringof == "package rt" || getPackage!A.stringof == "package core"))
        enum isDImplDefined = true;
    else static if (isPackage!A && (A.stringof == "package std" || A.stringof == "package rt" || A.stringof == "package core"))
        enum isDImplDefined = true;
    else static if (isType!A && isIntrinsicType!A)
        enum isDImplDefined = true;
    else static if (isFunction!A && 
    // Not exactly accurate but good enough
        (__traits(identifier, A).startsWith("_d_") || __traits(identifier, A).startsWith("rt_") || 
        __traits(identifier, A).startsWith("factory") || __traits(identifier, A).startsWith("__") ||
        __traits(identifier, A).startsWith("op")))
        enum isDImplDefined = true;
    else static if (isConstructor!A || isDestructor!A || isDManyThing!A)
        enum isDImplDefined = true;
    else
        enum isDImplDefined = false;
}

/// True if `T` wraps indirection, like an array or wrapper for a pointer.
public template wrapsIndirection(T)
{
    static if (hasChildren!T)
    // We don't want a type with an array field to count
        enum wrapsIndirection = hasIndirections!T && __traits(allMembers, T).length <= 2 && !isArray!(typeof(__traits(allMembers, T)[0])) && !isArray!(typeof(__traits(allMembers, T)[1]));
    else
        enum wrapsIndirection = isArray!T;
}

/// Gets an all default arguments for `T` as a mixin (`void[]` for types or variadic)
public template TemplateDefaults(alias T)
    if (isTemplate!T)
{
    enum TemplateDefaults =
    {
        string ret;
        static foreach (arg; T.stringof[(T.stringof.indexOf('(') + 1)..T.stringof.indexOf(')')].split(", "))
        {
            static if (arg.split(' ').length == 1)
                ret ~= "void[]";
            else
                ret ~= arg.split(' ')[0]~".init";
        }
        return ret;
    }();
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

/// Gets the length of `T`, if applicable.
public template Length(T) 
{
    static if (is(T U == U[L], ptrdiff_t L))
        enum Length = L;
}

/** 
 * Gets the signature of `F` as a string. \
 * Initializers will be lost.
 */
public template FieldSignature(alias F)
    if (isField!F)
{
    enum FieldSignature =
    {
        static if (isEnum!F)
            return "enum "~fullyQualifiedName!(typeof(F))~" "~__traits(identifier, F)~" = "~F.stringof;
        else static if (isStatic!F)
            return "static "~fullyQualifiedName!(typeof(F))~" "~__traits(identifier, F);
        else
            return fullyQualifiedName!(typeof(F))~" "~__traits(identifier, F);
    }();
}

/** 
 * Gets the signature of `F` as a string. \
 * This includes all attributes, templates (must be already initialized, names are lost,) and parameters.
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
        static if (isPointer!(TypeOf!(T, field)))
            ptrs ~= cast(void*)__traits(getMember, val, field);
        else static if (is(TypeOf!(T, field) == class))
            ptrs ~= *cast(void**)&__traits(getMember, val, field);
        else static if (isIndirection!(TypeOf!(T, field)))
            ptrs ~= __traits(getMember, val, field).indirections;
    }
    return ptrs;
}

/** 
 * Generates a mixin for implementing all possible functions of `T`
 * 
 * Remarks:
 *  Any function that returns true for `isDImplDefined` is discarded. \
 *  `nothrow`, `pure`, and `const` attributes are discarded. \
 *  `opCall`, `opAssign`, `opIndex`, `opSlice`, `opCast` and `opDollar` are discarded even if `mapOperators` is true.
 */
 // TODO: typeof(this) attributes (ie: shared)
public template functionMap(T, bool mapOperators = false)
    if (hasChildren!T)
{
    enum functionMap =
    {
        string str = "import "~moduleName!T~';';
        static foreach (func; FunctionNames!T)
        {
            static if (!isDImplDefined!(TypeOf!(T, func)))
            {
                static if (is(ReturnType!(TypeOf!(T, func)) == void))
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" { 
                        import caiman.conv;
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        orig."~FunctionCallableSignature!(TypeOf!(T, func))~";  }\n");
                else
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" { 
                        import caiman.conv;
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this))); 
                        return orig."~FunctionCallableSignature!(TypeOf!(T, func))~"; }\n");
            }
        }
        static if (mapOperators)
        // TODO: Fix for classes
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