/// Original Phobos drop-in replacement traits, superseded by the new Tern traits system.
module tern.legacy.traits;

public import std.traits : fullyQualifiedName, mangledName, moduleName, packageName,
    isFunction, arity, functionAttributes, hasFunctionAttributes, functionLinkage, FunctionTypeOf, isSafe, isUnsafe,
    isFinal, ParameterDefaults, SetFunctionAttributes, FunctionAttribute, variadicFunctionStyle, EnumMembers,
    hasAliasing, hasElaborateAssign, hasElaborateCopyConstructor, hasElaborateDestructor, hasElaborateMove, hasIndirections,
    hasMember, hasStaticMember, hasNested, hasUnsharedAliasing, isInnerClass, isNested, TemplateArgsOf, TemplateOf,
    CommonType, AllImplicitConversionTargets, ImplicitConversionTargets, CopyTypeQualifiers, CopyConstness, isAssignable,
    isCovariantWith, isImplicitlyConvertible, isQualifierConvertible, InoutOf, ConstOf, SharedOf, SharedInoutOf, SharedConstOf,
    SharedConstInoutOf, ImmutableOf, QualifierOf, allSameType, isType, isAggregateType, isArray, isAssociativeArray, isAutodecodableString,
    isBasicType, isBoolean, isBuiltinType, isCopyable, isDynamicArray, isEqualityComparable, isFloatingPoint, isIntegral, isNarrowString, 
    isConvertibleToString, isNumeric, isOrderingComparable, isPointer, isScalarType, isSigned, isSIMDVector, isSomeChar, isSomeString,
    isStaticArray, isUnsigned, isAbstractClass, isAbstractFunction, isDelegate, isExpressions, isFinalClass, isFinalFunction, isFunctionPointer,
    isInstanceOf, isSomeFunction, isTypeTuple, Unconst, Unshared, Unqual, Signed, Unsigned, ValueType, Promoted, Select, select,
    hasUDA, getUDAs, getSymbolsByUDA;
import std.traits;
import std.meta;
import std.string;

/// Gets an alias to the package in which `A` is defined, undefined behavior for any alias that does not have a package (any intrinsic type.)
public alias getPackage(alias A) = mixin(fullyQualifiedName!A.indexOf(".") == -1 ? fullyQualifiedName!A : fullyQualifiedName!A[0..fullyQualifiedName!A.indexOf(".")]);
/// True if `T` is an indirection.
public enum isReferenceType(T) = is(T == class) || is(T == interface) || isPointer!T || isDynamicArray!T || isAssociativeArray!T;
/// True if `T` is not an indirection.
public enum isValueType(T) = is(T == struct) || is(T == enum) || is(T == union) || isBuiltinType!T || hasModifiers!T;
/// True if `A` is a template.
public enum isTemplate(alias A) = __traits(isTemplate, A);
/// True if `A` is a module.
public enum isModule(alias A) = __traits(isModule, A);
/// True if `A` is a package.
public enum isPackage(alias A) = __traits(isPackage, A);
/// True if `A` is a field.
public enum isField(alias A) = !isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A;
/// True if `A` is a local.
public enum isLocal(alias A) = !isManifest!A && !__traits(compiles, { enum _ = A; }) && __traits(compiles, { auto _ = A; });
/// True if `T` is a basic type, built-in type, or array.
public enum isBuiltinType(T) = isBasicType!T || isBuiltinType!T || isArray!T;
/// True if `A` has any parents.
public enum hasParents(alias A) = (!isType!A || !isBuiltinType!A) && !isPackage!A;
/// True if `T` is an enum, array, or pointer.
public enum hasModifiers(T) = isArray!T || isPointer!T || !isAggregateType!T;
/// True if `A` has any children.
public enum hasChildren(alias A) = isModule!A || isPackage!A || (!isType!A || (!isBuiltinType!A && !hasModifiers!A));
/// True if `T` has any instance constructor ("__ctor").
public enum hasConstructor(alias A) = hasMember!(T, "__ctor");
/// True if `F` is a constructor;
public enum isConstructor(alias F) = isFunction!F && (__traits(identifier, F).startsWith("__ctor") || __traits(identifier, F).startsWith("_staticCtor"));
/// True if `F` is a destructor.
public enum isDestructor(alias F) = isFunction!F && (__traits(identifier, F).startsWith("__dtor") || __traits(identifier, F).startsWith("__xdtor") || __traits(identifier, F).startsWith("_staticDtor"));
/// True if `A` is a static field.
public enum isStatic(alias A) = !isManifest!A && ((isField!A && __traits(compiles, { auto _ = __traits(getMember, __traits(parent, A), __traits(identifier, A)); })) || (isLocal!A && __traits(compiles, { static auto _() { return A; } })));
/// True if `A` is an enum field or local.
public enum isManifest(alias A) = __traits(compiles, { enum _ = __traits(getMember, __traits(parent, A), __traits(identifier, A)); });
/// True if `A` is an implementation defined alias (ie: __ctor, std, rt, etc.)
public enum isDImplDefined(alias A) =
{
    static if ((isModule!A || (isType!A && !isBuiltinType!A)) && (getPackage!A.stringof == "package std" || getPackage!A.stringof == "package rt" || getPackage!A.stringof == "package core"))
        return true;
    else static if (isPackage!A && (A.stringof == "package std" || A.stringof == "package rt" || A.stringof == "package core"))
        return true;
    else static if (isType!A && isBuiltinType!A)
        return true;
    else static if (isFunction!A && 
    // Not exactly accurate but good enough
        (__traits(identifier, A).startsWith("_d_") || __traits(identifier, A).startsWith("rt_") || 
        __traits(identifier, A).startsWith("__") || __traits(identifier, A).startsWith("op")))
        return true;
    else static if (isConstructor!A || isDestructor!A || (isFunction!F && (__traits(identifier, F).startsWith("toHash") || __traits(identifier, F).startsWith("toString"))))
        return true;
    else
        return false;
}();
/// True if `A` is not D implementation defined.
public enum isOrganic(alias A) = !isDImplDefined!A;
/// True if `A` is able to be indexed.
public enum isIndexable(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { T t; auto _ = t[0]; });
/// True if `A` is able to be iterated upon forwards.
public enum isForward(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { T t; foreach (u; t) { } });
/// True if `A` is able to be iterated upon forwards.
public enum isBackward(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { T t; foreach_reverse (u; t) { } });
/// True if `B` is an element type of `A` (assignable as element.)
public enum isElement(A, B) = isAssignable!(B, ElementType!A);
/// True if `B` is able to be used as a range the same as `A`.
public enum isSimRange(A, B) = isAssignable!(ElementType!B, ElementType!A);
/// True if `F` is a lambda.
public enum isLambda(alias F) = __traits(identifier, F).startsWith("__lambda");
/// True if `F` is a dynamic lambda (templated, ie: `x => x + 1`)
public enum isTemplatedCallable(alias F) = std.traits.isCallable!(DefaultInstance!F);
/// True if `F` is a dynamic lambda (templated, ie: `x => x + 1`)
public enum isDynamicLambda(alias F) = isLambda!F && is(typeof(F) == void);
/// True if `F` is a function, lambda, or otherwise may be called using `(...)`
public enum isCallable(alias F) = std.traits.isCallable!F || isLambda!F || isTemplatedCallable!F;
/// True if `F` is a property of any kind.
public enum isProperty(alias F) = hasUDA!(F, property);
/// True if `F` is a pure callable.
public enum isPure(alias F) = isCallable!F && hasFunctionAttributes!(F, "pure");
/// True if `B` implements `A`.
public enum isImplement(A, B) = staticIndexOf!(A, Implements!B) != -1;
/// True if `A` is not mutable (const, immutable, enum, etc.).
public enum isMutable(alias A) =
{
    static if (isType!A)
        return std.traits.isMutable!A;
    else static if (isField!A)
        return std.traits.isMutable!(typeof(A)) || !isManifest!A;
    else
        return false;
}();

/// Gets the alignment of `T` dynamically, returning the actual instance alignment.
public enum alignof(T) =
{
    static if (is(T == class))
        return __traits(classInstanceAlignment, T);
    else
        return T.alignof;
}();

/// Gets the size of `T` dynamically, returning the actual instance size.
public enum sizeof(T) =
{
    static if (is(T == class))
        return __traits(classInstanceSize, T);
    else
        return T.sizeof;
}();

/// Gets the type of member `MEMBER` in `A`  
/// This will return a function alias if `MEMBER` refers to a function, and do god knows what if `MEMBER` is a package or module.
public template TypeOf(alias A, string MEMBER)
{
    static if (isType!(__traits(getMember, A, MEMBER)) || isTemplate!(__traits(getMember, A, MEMBER)) || isFunction!(__traits(getMember, A, MEMBER)))
        alias TypeOf = __traits(getMember, A, MEMBER);
    else
        alias TypeOf = typeof(__traits(getMember, A, MEMBER));
}

/// Gets the return type of a callable symbol.
public template ReturnType(alias F)
    if (isCallable!F)
{
    static if (isLambda!F && !__traits(compiles, { alias _ = std.traits.ReturnType!F; }))
    {
        typeof(toDelegate(F)) dg;
        alias ReturnType = TypeOf!dg;
    }  
    else
        alias ReturnType = std.traits.ReturnType!F;
}

/// Gets the parameters of a callable symbol.
public template Parameters(alias F)
    if (isCallable!F)
{
    static if (isLambda!F && !__traits(compiles, { alias _ = std.traits.Parameters!F; }))
    {
        typeof(toDelegate(F)) dg;
        alias Parameters = std.traits.Parameters!dg;
    }  
    else
        alias Parameters = std.traits.Parameters!F;
}

/// Gets the element type of `T`, if applicable.  
/// Returns the type of enum values if `T` is an enum.
public template ElementType(T) 
{
    static if (is(T == U[], U) || is(T == U*, U) || is(T U == U[L], size_t L))
        alias ElementType = ElementType!U;
    else static if (isIndexable!T)
    {
        T temp;
        alias ElementType = ElementType!(typeof(temp[0]));
    }
    else
        alias ElementType = OriginalType!T;
}

/// Gets the length of `T`, if applicable.
public template Length(T) 
{
    static if (is(T U == U[L], size_t L))
        enum Length = L;
}

/// Gets an `AliasSeq` all types that `T` implements.
public template Implements(T)
{
    template Flatten(H, T...)
    {
        static if (T.length)
        {
            alias Flatten = AliasSeq!(Flatten!H, Flatten!T);
        }
        else
        {
            static if (!is(H == Object) && (is(H == class) || is(H == interface)))
                alias Flatten = AliasSeq!(H, Implements!H);
            else
                alias Flatten = Implements!H;
        }
    }

    static if (is(T S == super) && S.length)
    {
        static if (__traits(getAliasThis, T).length != 0)
            alias Implements = AliasSeq!(TypeOf!(T, __traits(getAliasThis, T)), Implements!(TypeOf!(T, __traits(getAliasThis, T))), NoDuplicates!(Flatten!S));
        else
            alias Implements = NoDuplicates!(Flatten!S);
    }
    else
    {
        static if (__traits(getAliasThis, T).length != 0)
            alias Implements = AliasSeq!(TypeOf!(T, __traits(getAliasThis, T)), Implements!(TypeOf!(T, __traits(getAliasThis, T))));
        else
            alias Implements = AliasSeq!();
    }  
}

/// Gets an `AliasSeq` of the names of all fields in `A`.
public template Fields(alias A)
{
    alias Fields = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isField!(__traits(getMember, A, member)))
            Fields = AliasSeq!(Fields, member);
    }
}

/// Gets an `AliasSeq` of the names all functions in `A`.
public template Functions(alias A)
{
    alias Functions = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isFunction!(__traits(getMember, A, member)))
            Functions = AliasSeq!(Functions, member);
    }
}

/// Gets an `AliasSeq` of the names of all types in `A`.
public template Types(alias A)
{
    alias Types = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isType!(__traits(getMember, A, member)))
            Types = AliasSeq!(Types, member);
    }
}

/// Gets an `AliasSeq` of the names of all templates in `A`.
public template Templates(alias A)
{
    alias Templates = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; __traits(allMembers, A))
    {
        static if (isTemplate!(__traits(getMember, A, member)))
            Templates = AliasSeq!(Templates, member);
    }
}