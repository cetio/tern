/// Expansive traits module meant to replace `std.traits`.
module tern.traits;

// TODO: Legacy imports, get rid of this eventually
public import std.traits : functionAttributes, hasFunctionAttributes, functionLinkage, FunctionTypeOf,
    ParameterDefaults, ParameterStorageClassTuple, SetFunctionAttributes, variadicFunctionStyle,
    BaseClassesTuple, BaseTypeTuple, EnumMembers, FieldNameTuple, hasStaticMember, hasNested, hasIndirections, isNested,
    RepresentationTypeTuple, TemplateArgsOf, TemplateOf, TransitiveBaseTypeTuple, InoutOf, ConstOf, SharedOf, SharedInoutOf,
    SharedConstInoutOf, SharedConstOf, ImmutableOf, QualifierOf, allSameType, ForeachType, KeyType, Largest, mostNegative,
    PointerTarget, Signed, Unconst, Unshared, Unqual, Unsigned, ValueType, Promoted, lvalueOf, rvalueOf, select, Select,
    hasUDA, getUDAs, getSymbolsByUDA;
static import std.traits;
static import tern.traits;
import std.meta;
import std.string;
import std.functional : toDelegate;
import std.conv;

/// Gets the partial identifier of `A` excluding all parents.
public enum identifier(alias A) =
{
    static if (isExpression!A)
        return A.stringof;
    static if (hasIdentifier!A)
        return __traits(identifier, A);
    else
        return A.stringof;
}();
/// Gets the full identifier of `A` including all parents.
public enum fullIdentifier(alias A) =
{
    // TODO: Fix, use identifier unless type or expression
    static if (hasParents!A)
        return fullIdentifier!(Parent!A)~"."~identifier!A;
    else
        return identifier!A;
}();

/// Gets the parent of `A`.
public alias Parent(alias A) = __traits(parent, A);
/// Gets the children of `A`.
public alias Children(alias A) = __traits(allMembers, A);
/// Gets the `alias this` of `T`.
public alias AliasThis(T) = __traits(getAliasThis, T);
/// Gets all attributes that are applied to `A`.
public alias Attributes(alias A) = __traits(getAttributes, A);
/// True if `A` has a child `M`.
public enum hasChild(alias A, string M) = std.traits.hasMember!(A, M);
/// True if `A` has a field `M`.
public enum hasField(alias A, string M) = std.traits.hasMember!(A, M) && isField!(getChild!(M, A));
/// True if `A` has a function `M`.
public enum hasFunction(alias A, string M) = std.traits.hasMember!(A, M) && isFunction!(getChild!(M, A));
/// True if `A` has a type `M`.
public enum hasType(alias A, string M) = std.traits.hasMember!(A, M) && isType!(getChild!(M, A));
/// True if `A` has a type `M`.
public enum hasTemplate(alias A, string M) = std.traits.hasMember!(A, M) && isTemplate!(getChild!(M, A));
/// Gets an alias to child `M` in `A`.
public alias getChild(alias A, string M) = __traits(getMember, A, M);
/// True if `A` has a parent `P`.
public enum hasParent(alias A, alias P) = staticIndexOf!(P, Implements!A) != -1;
/// True if type `B` is an instance of type `A`.
public enum isInstanceOf(alias A, alias B) = (isTemplate!A && std.traits.isInstanceOf!(A, B)) || hasParent!(A, B);
/// True if `A` contains any kind of aliasing.
public enum hasAliasing(alias A) = std.traits.hasAliasing!A;
/// True if `A` contains any kind of unshared (thread-unsafe) aliasing.
public enum hasUnsharedAliasing(alias A) = std.traits.hasUnsharedAliasing!A;
/// True if `T` has a user defined assignment operation.
public enum hasElaborateAssign(T) = std.traits.hasElaborateAssign!T;
/// True if `T` has a user defined copy constructor.
public enum hasElaborateCopyConstructor(T) = std.traits.hasElaborateCopyConstructor!T;
/// True if `T` has a user defined destructor.
public enum hasElaborateDestructor(T) = std.traits.hasElaborateDestructor!T;
/// True if `T` has a user defined move operation.
public enum hasElaborateMove(T) = std.traits.hasElaborateMove!T;
/// True if `F` is safe.
public enum isSafe(alias F) = std.traits.isSafe!F;
/// True if `F` is unsafe.
public enum isUnsafe(alias F) = std.traits.isUnsafe!F;
/// True if `A` is final.
public enum isFinal(alias A) = std.traits.isFinal!A;
/// True if `A` is final.
public enum isAbstract(alias A) = std.traits.isAbstractClass!A || std.traits.isAbstractFunction!A;
/// True if `F` has no return type (`void`.)
public enum isNoReturn(alias F) = is(ReturnType!F == void);
/// True if type `A` is assignable to type `B`.
public enum isAssignable(A, B) = std.traits.isAssignable!(A, B);
/// True if type `A` is covariant with type `B`.
public enum isCovariantWith(A, B) = std.traits.isCovariantWith!(A, B);
/// True if type `A` is implicitly convertible to type `B`.
public enum isImplicitlyConvertible(A, B) = std.traits.isImplicitlyConvertible!(A, B);
/// True if type `A` is qualifier convertible to type `B`.
public enum isQualifierConvertible(A, B) = std.traits.isQualifierConvertible!(A, B);
/// True if type `A` is reinterpretable to type `B`.
public enum isReinterpretable(A, B) =
{
    static if ((is(A == void*) && is(B == class)) || (is(A == class) && is(B == void*)))
        return true;

    static if (is(A == class) != is(B == class))
        return false;

    static if (A.sizeof > B.sizeof)
        return false;

    static if (hasChildren!A && hasChildren!B)
    {
        static foreach (i, field; Fields!A)
        {{
            alias FA = getChild!(A, field);
            alias FB = getChild!(B, Fields!B[i]);
            static if (!isReinterpretable!(typeof(FA), typeof(FB)) || (isManifest!FA != isManifest!FB))
                return false;
        }}
    }
    else static if (hasChildren!A || hasChildren!B)
    {
        static if (hasChildren!A)
        {
            static if (isManifest!(getChild!(A, Fields!A[0])))
                return false;

            alias FA = typeof(getChild!(A, Fields!A[0]));
        }
        else
            alias FA = A;

        static if (hasChildren!B)
        {
            static if (isManifest!(getChild!(B, Fields!B[0])))
                return false;
                
            alias FB = typeof(getChild!(B, Fields!B[0]));
        }
        else
            alias FB = B;

        return isReinterpretable!(FA, FB);
    }

    return true;
}();
/// True if `T` is an array.
public enum isArray(T) = std.traits.isArray!T;
/// True if `T` is a dynamic array.
public enum isDynamicArray(T) = std.traits.isDynamicArray!T;
/// True if `T` is a static array.
public enum isStaticArray(T) = std.traits.isStaticArray!T;
/// True if `T` is a vector, this is any fixed-length indexable.
public enum isVector(T) = !isDynamicArray!T && isIndexable!T && isNumeric!(ElementType!T);
/// True if `T` is an associative array.
public enum isAssociativeArray(T) = std.traits.isAssociativeArray!T;
/// True if `T` is an auto-decodeable string.
public enum isAutodecodeableString(T) = std.traits.isAutodecodableString!T;
/// True if `T` is a built-in type, as in any language defined type.
public enum isBuiltinType(T) = std.traits.isBuiltinType!T;
/// True if `T` is an integral.
public enum isIntegral(T) = std.traits.isIntegral!T;
/// True if `T` is an intrinsically numeric.
public enum isScalar(T) = std.traits.isScalarType!T;
/// True if `T` is a floating point.
public enum isFloatingPoint(T) = std.traits.isFloatingPoint!T;
/// True if `T` is a `string` or `wstring`.
public enum isNarrowString(T) = std.traits.isNarrowString!T;
/// True if `T` is numerically represented, as in integral or float.
public enum isNumeric(T) = std.traits.isNumeric!T;
/// True if `T` is a pointer.
public enum isPointer(T) = std.traits.isPointer!T;
/// True if `T` is any string.
public enum isString(T) = std.traits.isSomeString!T;
/// True if `T` is any char.
public enum isChar(T) = std.traits.isSomeChar!T;
/// True if `T` is signed.
public enum isSigned(T) = std.traits.isSigned!T;
/// True if `T` is unsigned.
public enum isUnsigned(T) = std.traits.isUnsigned!T;
/// True if `T` is unable to be copied.
public enum isCopyable(T) = std.traits.isCopyable!T;
/// True if `T` is able to be equality compared.
public enum isEqualityComparable(T) = std.traits.isTestable!T || std.traits.isEqualityComparable!T;
/// True if `T` is able to be ordering compared, as in `<`, `>`, etc.
public enum isOrderingComparable(T) = std.traits.isOrderingComparable!T;
/// True if `T` is an indirection.
public enum isReferenceType(T) = is(T == class) || is(T == interface) || isPointer!T || isDynamicArray!T || isAssociativeArray!T;
/// True if `T` is not an indirection.
public enum isValueType(T) = is(T == struct) || is(T == enum) || is(T == union) || isBuiltinType!T || hasModifiers!T;
/// True if `A` is a template.
public enum isTemplate(alias A) = __traits(isTemplate, A);
/// True if `A` is a template, uninstantiated or instatiated.
public enum isTemplated(alias A) = __traits(compiles, TemplateArgsOf!A) || isTemplate!A;
/// True if `A` is a module.
public enum isModule(alias A) = __traits(isModule, A);
/// True if `A` is a package.
public enum isPackage(alias A) = __traits(isPackage, A);
/// True if `A` is a field.
public enum isField(alias A) = !isType!A && !isFunction!A && !isTemplate!A && !isModule!A && !isPackage!A;
/// True if `A` is a local.
public enum isLocal(alias A) = !isManifest!A && !__traits(compiles, { enum _ = A; }) && __traits(compiles, { auto _ = A; });
/// True if `A` is an expression, like a string, numeric, or other manifest data.
public enum isExpression(alias A) = __traits(compiles, { enum _ = A; });
/// True if `A` is a function symbol.
public enum isFunction(alias A) = std.traits.isFunction!A;
/// True if `A` is a function pointer symbol.
public enum isFunctionPointer(alias A) = std.traits.isFunctionPointer!A;
/// True if `A` is a delegate symbol.
public enum isDelegate(alias A) = std.traits.isDelegate!A;
/// True if `A` is a type symbol.
public enum isType(alias A) = std.traits.isType!A;
/// True if `A` is a class type symbol.
public enum isClass(alias A) = is(A == class);
/// True if `A` is a interface type symbol.
public enum isInterface(alias A) = is(A == interface);
/// True if `A` is a struct type symbol.
public enum isStruct(alias A) = is(A == struct);
/// True if `A` is a enum type symbol.
public enum isEnum(alias A) = is(A == enum);
/// True if `A` is a union type symbol.
public enum isUnion(alias A) = is(A == union);
/// True if `A` is an aggregate type symbol.
public enum isAggregateType(alias A) = std.traits.isAggregateType!A;
/// True if `A` is an alias to a top-level symbol, like a package or intrinsic, which has no parent.
public enum isTopLevel(alias A) = !__traits(compiles, { alias _ = Parent!A; }) || !__traits(compiles, { enum _ = is(Parent!A == void); }) || is(Parent!A == void);
/// True if `A` has any parents.
public enum hasParents(alias A) = !isManifest!A && !isTopLevel!A;
/// True if `T` is an enum, array, or pointer.
public enum hasModifiers(T) = isArray!T || isPointer!T || isEnum!T;
/// True if `A` has any children.
public enum hasChildren(alias A) = isModule!A || isPackage!A || (!isType!A || (!isBuiltinType!A && !hasModifiers!A));
/// True if `T` has any instance constructor ("__ctor").
public enum hasConstructor(alias A) = std.traits.hasMember!(T, "__ctor");
/// True if `F` is a constructor;
public enum isConstructor(alias F) = isFunction!F && (__traits(identifier, F).startsWith("__ctor") || __traits(identifier, F).startsWith("_staticCtor"));
/// True if `F` is a destructor.
public enum isDestructor(alias F) = isFunction!F && (__traits(identifier, F).startsWith("__dtor") || __traits(identifier, F).startsWith("__xdtor") || __traits(identifier, F).startsWith("_staticDtor"));
/// True if `A` is a static field.
public enum isStatic(alias A) = !isManifest!A && ((isField!A && __traits(compiles, { auto _ = __traits(getMember, Parent!A, __traits(identifier, A)); })) || (isLocal!A && __traits(compiles, { static auto _() { return A; } })));
/// True if `A` is an enum field or local.
public enum isManifest(alias A) = __traits(compiles, { enum _ = __traits(getMember, Parent!A, __traits(identifier, A)); });
/// True if `A` is an implementation defined alias (ie: __ctor, std, rt, etc.)
public enum isDImplDefined(alias A) =
{
    static if ((isModule!A || (isType!A && !isBuiltinType!A)) && (identifier!(getPackage!A) == "std" || identifier!(getPackage!A) == "rt" || identifier!(getPackage!A) == "core"))
        return true;
    else static if (isPackage!A && (identifier!A == "std" || identifier!A == "rt" || identifier!A == "core"))
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
/// True if `T` is able to be indexed.
public enum isIndexable(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { template t(T) { T v; auto t() => v[0]; } auto x = t!T; });
/// True if `T` is able to be index assigned.
public enum isIndexAssignable(T) = __traits(compiles, { template t(T) { T v; auto t() => v[0] = v[1]; } alias x = t!T; }) && isMutable!(ElementType!T);
/// True if `T` is able to be sliced.
public enum isSliceable(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { template t(T) { T v; auto t() => v[0..1]; } alias x = t!T; });
/// True if `T` is able to be slice assigned.
public enum isSliceAssignable(T) = __traits(compiles, { template t(T) { T v; auto t() => v[0..1] = v[1..2]; } alias x = t!T; }) && isMutable!(ElementType!T);
/// True if `T` is able to be iterated upon forwards.
public enum isForward(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { template t(T) { T v; auto t() { foreach (u; v) { } } } alias x = t!T; });
/// True if `T` is able to be iterated upon forwards.
public enum isBackward(T) = isDynamicArray!T || isStaticArray!T || __traits(compiles, { template t(T) { T v; auto t() { foreach_reverse (u; v) { } } } alias x = t!T; });
/// True if `B` is an element type of `A` (assignable as element.)
public enum isElement(A, B) = isAssignable!(B, ElementType!A);
/// True if `B` is able to be used as a range the same as `A`.
public enum isSimRange(A, B) = isAssignable!(ElementType!B, ElementType!A);
/// True if `A` has an identifier.
public enum hasIdentifier(alias A) = __traits(compiles, { enum _ = __traits(identifier, A); });
/// True if `F` is a lambda.
public enum isLambda(alias F) = hasIdentifier!F && __traits(identifier, F).startsWith("__lambda");
/// True if `F` is a dynamic lambda (templated, ie: `x => x + 1`)
public enum isTemplatedCallable(alias F) = isTemplate!F && isCallable!(DefaultInstantiate!F);
/// True if `F` is a dynamic lambda (templated, ie: `x => x + 1`)
public enum isDynamicLambda(alias F) = isLambda!F && is(typeof(F) == void);
/// True if `F` is a function, lambda, or otherwise may be called using `(...)`
public enum isCallable(alias F) = std.traits.isCallable!F || isLambda!F || isTemplatedCallable!F;
/// True if `F` is a property of any kind.
public enum isProperty(alias F) = hasUDA!(F, property);
/// True if `F` is a pure callable.
public enum isPure(alias F) = isCallable!F && hasFunctionAttributes!(F, "pure");
/// True if type `A` implements type `B`.
public enum isImplement(A, B) = staticIndexOf!(B, Implements!A) != -1;
/// True if `A` has a frame-limited generic parameter.
enum hasExternalFrameLimit(alias A) =
{
    static if (isTemplated!A)
    static foreach (B; TemplateArgsOf!A)
    {
        static if (isFrameLimited!B)
            return true;
    }
    return false;
}();
/// True if `A` is frame-limited, such as a type with a generic lambda parameter.
public enum isFrameLimited(alias A) = isLambda!A || isDelegate!A || (isTemplated!A && hasExternalFrameLimit!A);
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

/// Gets all children of child `M` in `A`.
public alias Children(alias A, string M) = Children!(getChild!(A, M));
/// Gets all attributes of child `M` in `A`.
public alias Attributes(alias A, string M) = Attributes!(getChild!(A, M));
/// True if child `M1` in `A` has a child `M2`.
public alias hasChild(alias A, string M1, string M2) = hasChild!(getChild!(A, M1), M2);
/// True if child `M1` in `A` has a field `M2`.
public alias hasField(alias A, string M1, string M2) = hasField!(getChild!(A, M1), M2);
/// True if child `M1` in `A` has a function `M2`.
public alias hasFunction(alias A, string M1, string M2) = hasFunction!(getChild!(A, M1), M2);
/// True if child `M1` in `A` has a type `M2`.
public alias hasType(alias A, string M1, string M2) = hasType!(getChild!(A, M1), M2);
/// True if child `M1` in `A` has a template `M2`.
public alias hasTemplate(alias A, string M1, string M2) = hasTemplate!(getChild!(A, M1), M2);
/// Gets the child `M2` in `M1` in `A`.
public alias getChild(alias A, string M1, string M2) = getChild!(getChild!(A, M1), M2);
/// True if child `M1` in `A` has a parent `P`.
public alias hasParent(alias A, string M, alias P) = hasParent!(getChild!(A, M), P);
/// True if the type of `M` in `A` has aliasing.
public alias hasAliasing(alias A, string M) = hasAliasing!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` has unshared aliasing.
public alias hasUnsharedAliasing(alias A, string M) = hasUnsharedAliasing!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` has an elaborate assign.
public alias hasElaborateAssign(alias A, string M) = hasElaborateAssign!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` has an elaborate copy constructor.
public alias hasElaborateCopyConstructor(alias A, string M) = hasElaborateCopyConstructor!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` has an elaborate destructor.
public alias hasElaborateDestructor(alias A, string M) = hasElaborateDestructor!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` has an elaborate move.
public alias hasElaborateMove(alias A, string M) = hasElaborateMove!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is safe.
public alias isSafe(alias A, string M) = isSafe!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is unsafe.
public alias isUnsafe(alias A, string M) = isUnsafe!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is final.
public alias isFinal(alias A, string M) = isFinal!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is abstract.
public alias isAbstract(alias A, string M) = isAbstract!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a void returning callable.
public alias isNoReturn(alias A, string M) = isNoReturn!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is assignable to `B`.
public alias isAssignable(alias A, string M, alias B) = isAssignable!(typeof(getChild!(A, M), B));
/// True if the type of `M` in `A` is covariant with `B`.
public alias isCovariantWith(alias A, string M, alias B) = isCovariantWith!(typeof(getChild!(A, M), B));
/// True if the type of `M` in `A` is implicitly convertible to `B`.
public alias isImplicitlyConvertible(alias A, string M, alias B) = isImplicitlyConvertible!(typeof(getChild!(A, M), B));
/// True if the type of `M` in `A` is qualifier convertible to `B`.
public alias isQualifierConvertible(alias A, string M, alias B) = isQualifierConvertible!(typeof(getChild!(A, M), B));
/// True if the type of `M` in `A` is reinterpretable to `B`.
public alias isReinterpretable(alias A, string M, alias B) = isReinterpretable!(typeof(getChild!(A, M), B));
/// True if the type of `M` in `A` is an array.
public alias isArray(alias A, string M) = isArray!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a dynamic array.
public alias isDynamicArray(alias A, string M) = isDynamicArray!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a static array.
public alias isStaticArray(alias A, string M) = isStaticArray!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an associative array.
public alias isAssociativeArray(alias A, string M) = isAssociativeArray!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an auto-decodeable string.
public alias isAutodecodableString(alias A, string M) = isAutodecodableString!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a built-in type.
public alias isBuiltinType(alias A, string M) = isBuiltinType!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an integral.
public alias isIntegral(alias A, string M) = isIntegral!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a scalar.
public alias isScalar(alias A, string M) = isScalar!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a floating-point.
public alias isFloatingPoint(alias A, string M) = isFloatingPoint!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a narrow string.
public alias isNarrowString(alias A, string M) = isNarrowString!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is numeric.
public alias isNumeric(alias A, string M) = isNumeric!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a pointer.
public alias isPointer(alias A, string M) = isPointer!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is any string.
public alias isString(alias A, string M) = isString!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is any char.
public alias isChar(alias A, string M) = isChar!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is signed.
public alias isSigned(alias A, string M) = isSigned!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is unsigned.
public alias isUnsigned(alias A, string M) = isUnsigned!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is copyable.
public alias isCopyable(alias A, string M) = isCopyable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is equality comparable.
public alias isEqualityComparable(alias A, string M) = isEqualityComparable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is ordering comparable.
public alias isOrderingComparable(alias A, string M) = isOrderingComparable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a reference type.
public alias isReferenceType(alias A, string M) = isReferenceType!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a value type.
public alias isValueType(alias A, string M) = isValueType!(typeof(getChild!(A, M)));
/// True if `M` in `A` is a template.
public alias isTemplate(alias A, string M) = isTemplate!(getChild!(A, M));
/// True if `M` in `A` is a module.
public alias isModule(alias A, string M) = isModule!(getChild!(A, M));
/// True if `M` in `A` is a field.
public alias isField(alias A, string M) = isField!(getChild!(A, M));
/// True if `M` in `A` is a local.
public alias isLocal(alias A, string M) = isLocal!(getChild!(A, M));
/// True if `M` in `A` is a function.
public alias isFunction(alias A, string M) = isFunction!(getChild!(A, M));
/// True if the type of `M` in `A` is a function pointer.
public alias isFunctionPointer(alias A, string M) = isFunctionPointer!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a delegate.
public alias isDelegate(alias A, string M) = isDelegate!(typeof(getChild!(A, M)));
/// True if `M` in `A` is a type. 
public alias isType(alias A, string M) = isType!(getChild!(A, M));
/// True if the type of `M` in `A` is a class. 
public alias isClass(alias A, string M) = isClass!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an interface.
public alias isInterface(alias A, string M) = isInterface!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a struct.
public alias isStruct(alias A, string M) = isStruct!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an enum.
public alias isEnum(alias A, string M) = isEnum!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a union.
public alias isUnion(alias A, string M) = isUnion!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an aggregate type.
public alias isAggregateType(alias A, string M) = isAggregateType!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an instance of `B`.
public alias isInstanceOf(alias A, string M, alias B) = isInstanceOf!(typeof(getChild!(A, M)), B);
/// True if the type of `M` in `A` has modifiers.
public alias hasModifiers(alias A, string M) = hasModifiers!(typeof(getChild!(A, M)));
/// True if `M` in `A` has children.
public alias hasChildren(alias A, string M) = hasChildren!(getChild!(A, M));
/// True if the type of `M` in `A` has a constructor.
public alias hasConstructor(alias A, string M) = hasChildren!(typeof(getChild!(A, M)));
/// True if `M` in `A` is static.
public alias isStatic(alias A, string M) = isStatic!(getChild!(A, M));
/// True if `M` in `A` is manifest data.
public alias isManifest(alias A, string M) = isManifest!(getChild!(A, M));
/// True if `M` in `A` is implementation defined.
public alias isDImplDefined(alias A, string M) = isDImplDefined!(getChild!(A, M));
/// True if `M` in `A` is not implementation defined.
public alias isOrganic(alias A, string M) = isOrganic!(getChild!(A, M));
/// True if the type of `M` in `A` is indexable.
public alias isIndexable(alias A, string M) = isIndexable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is index assignable.
public alias isIndexAssignable(alias A, string M) = isIndexAssignable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is sliceable.
public alias isSliceable(alias A, string M) = isSliceable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is slice assignable.
public alias isSliceAssignable(alias A, string M) = isSliceAssignable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is forward iterable.
public alias isForward(alias A, string M) = isForward!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is backward iterable.
public alias isBackward(alias A, string M) = isBackward!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is an element of `B`.
public alias isElement(alias A, string M, alias B) = isElement!(typeof(getChild!(A, M)), B);
/// True if the type of `M` in `A` shares element type with `B`.
public alias isSimRange(alias A, string M, alias B) = isSimRange!(typeof(getChild!(A, M)), B);
/// True if the type of `M` in `A` is a lambda.
public alias isLambda(alias A, string M) = isLambda!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a templated callable.
public alias isTemplatedCallable(alias A, string M) = isTemplatedCallable!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is a dynamic lambda.
public alias isDynamicLambda(alias A, string M) = isDynamicLambda!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` is callable.
public alias isCallable(alias A, string M) = isCallable!(typeof(getChild!(A, M)));
/// True if `M` in `A` is a property.
public alias isProperty(alias A, string M) = isProperty!(getChild!(A, M));
/// True if the type of `M` in `A` is pure.
public alias isPure(alias A, string M) = isPure!(typeof(getChild!(A, M)));
/// True if the type of `M` in `A` implements `B`.
public alias isImplement(alias A, string M, alias B) = isImplement!(typeof(getChild!(A, M)), B);
/// True if `M` in `A` is mutable.
public alias isMutable(alias A, string M) = isMutable!(getChild!(A, M));

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

/// Instantiates `T` using all default arguments (`void[]` for types or variadic)
public template DefaultInstantiate(alias T)
    if (isTemplate!T)
{
    string args()
    {
        string ret;
        static foreach (arg; T.stringof[(T.stringof.indexOf("(") + 1)..T.stringof.indexOf(")")].split(", "))
        {
            static if (arg.split(" ").length == 1 || arg.split(" ")[0] == "alias")
                ret ~= "void[], ";
            else
                ret ~= arg.split(" ")[0]~".init, ";
        }
        return ret[0..(ret.length >= 2 ? $-2 : $)];
    }

    alias DefaultInstantiate = mixin("T!("~args~")");
}

/// Gets the number of arguments that `F` takes, undefined or variadic.
public enum Arity(alias F) =
{
    static if (identifier!F.startsWith("__lambda") && !is(typeof(F) == void))
    {
        typeof(toDelegate(F)) dg;
        return Parameters!dg.length;
    }
    static if (!identifier!F.startsWith("__lambda") || !is(typeof(F) == void))
        return Parameters!F.length;
    else
    {
        string p = F.stringof[(F.stringof.lastIndexOf("(") + 1)..(F.stringof.lastIndexOf(")"))];
        return p.split(", ").length;
    }
}();

/// Gets the module that `A` is declared in, or itself, if it has no module.
public template Module(alias A)
{
    static if (!hasParents!A || isPackage!(Parent!A))
        alias Module = A;
    else
        alias Module = Module!(Parent!A);
}

/// Gets the package that `A` is declared in, or itself, if it has no package.
public template Package(alias A)
{
    static if (!hasParents!A)
        alias Package = A;
    else static if (isPackage!(Parent!A))
        alias Package = Parent!A;
    else
        alias Package = Package!(Parent!A);
}

/// Gets the return type of a callable symbol.
public template ReturnType(alias F)
    if (isCallable!F)
{
    static if (isLambda!F && !__traits(compiles, { alias _ = std.traits.ReturnType!F; }))
    {
        typeof(toDelegate(F)) dg;
        alias ReturnType = typeof(dg);
    }  
    else
        alias ReturnType = std.traits.ReturnType!F;
}

/// Gets the parameters of a callable symbol.
public template Parameters(alias F)
    if (isCallable!F)
{
    static if (isTemplatedCallable!F)
        alias ParameterIdentifiers = std.traits.ParameterIdentifierTuple!(DefaultInstantiate!F);
    else static if (isLambda!F && !__traits(compiles, { alias _ = std.traits.Parameters!F; }))
    {
        typeof(toDelegate(F)) dg;
        alias Parameters = std.traits.Parameters!dg;
    }  
    else
        alias Parameters = std.traits.Parameters!F;
}

/// Gets the parameter identifiers of a callable symbol.
public template ParameterIdentifiers(alias F)
    if (isCallable!F)
{
    static if (isTemplatedCallable!F)
        alias ParameterIdentifiers = std.traits.ParameterIdentifierTuple!(DefaultInstantiate!F);
    else static if (isLambda!F && !__traits(compiles, { alias _ = std.traits.ParameterIdentifierTuple!F; }))
    {
        typeof(toDelegate(F)) dg;
        alias ParameterIdentifiers = std.traits.ParameterIdentifierTuple!dg;
    }  
    else
        alias ParameterIdentifiers = std.traits.ParameterIdentifierTuple!F;
}

/// Gets the element type of `T`, if applicable.  
/// Returns the type of enum values if `T` is an enum.
public template ElementType(T) 
{
    static if (is(T == U[], U) || is(T == U*, U) || is(T U == U[L], size_t L))
        alias ElementType = U;
    else static if (isIndexable!T)
    {
        pragma(msg, T);
        pragma(msg, isIndexable!T);
        T temp;
        alias ElementType = typeof(temp[0]);
    }
    else
        alias ElementType = std.traits.OriginalType!T;
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
    private template Flatten(H, T...)
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
        static if (getAliasThis!T.length != 0)
            alias Implements = AliasSeq!(TypeOf!(T, getAliasThis!T), Implements!(TypeOf!(T, getAliasThis!T)), NoDuplicates!(Flatten!S));
        else
            alias Implements = NoDuplicates!(Flatten!S);
    }
    else
    {
        static if (getAliasThis!T.length != 0)
            alias Implements = AliasSeq!(TypeOf!(T, getAliasThis!T), Implements!(TypeOf!(T, getAliasThis!T)));
        else
            alias Implements = AliasSeq!();
    }  
}

/// Gets the type of member `MEMBER` in `A`  
/// This will return a function alias if `MEMBER` refers to a function, and do god knows what if `MEMBER` is a package or module.
public template TypeOf(alias A, string MEMBER)
{
    static if (isType!(__traits(getMember, A, MEMBER)) || isTemplate!(__traits(getMember, A, MEMBER)) || isFunction!(__traits(getMember, A, MEMBER)))
        alias TypeOf = __traits(getMember, A, MEMBER);
    else
        alias TypeOf = typeof(__traits(getMember, A, MEMBER));
}

/// Gets an `AliasSeq` of the names of all fields in `A`.
public template Fields(alias A)
{
    alias Fields = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; Children!A)
    {
        static if (isField!(getChild!(A, member)))
            Fields = AliasSeq!(Fields, member);
    }
}

/// Gets an `AliasSeq` of the names all functions in `A`.
public template Functions(alias A)
{
    alias Functions = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; Children!A)
    {
        static if (isFunction!(getChild!(A, member)))
            Functions = AliasSeq!(Functions, member);
    }
}

/// Gets an `AliasSeq` of the names of all types in `A`.
public template Types(alias A)
{
    alias Types = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; Children!A)
    {
        static if (isType!(getChild!(A, member)))
            Types = AliasSeq!(Types, member);
    }
}

/// Gets an `AliasSeq` of the names of all templates in `A`.
public template Templates(alias A)
{
    alias Templates = AliasSeq!();

    static if (hasChildren!A)
    static foreach (member; Children!A)
    {
        static if (isTemplate!(getChild!(A, member)))
            Templates = AliasSeq!(Templates, member);
    }
}

/// Gets the signature of `A` as a string, has defined special behavior for callables and fields.
/// This includes all attributes, templates (must be already initialized, names are lost,) and parameters.
public template Signature(alias A, bool DECLARING = true)
{
    static if (isCallable!A)
    enum Signature = 
    {
        static if (DECLARING)
        {
            string paramSig = "(";
            static if (__traits(compiles, { alias _ = TemplateArgsOf!A; }))
            {
                static foreach (i, A; TemplateArgsOf!A)
                {
                    static if (__traits(compiles, { enum _ = B; }))
                        paramSig ~= fullIdentifier!(typeof(B))~" T"~i.stringof[0..$-2];
                    else
                        paramSig ~= "alias T"~i.stringof[0..$-2];
                }
                paramSig ~= ")(";
            }

            foreach (i, P; Parameters!A)
            {
                foreach (Q; __traits(getParameterStorageClasses, A, i))
                    paramSig ~= Q~" ";
                paramSig ~= fullIdentifier!P~" "~ParameterIdentifierTuple!A[i]~(i == Parameters!A.length - 1 ? null : ", ");
            }
            paramSig ~= ")";

            string attrs;
            static foreach (ATTR; __traits(getFunctionAttributes, A))
                attrs ~= ATTR~" ";
            attrs = attrs[0..(attrs.length == 0 ? $ : $-1)];
        }
        else
        {
            string paramSig = "(";
            static if (__traits(compiles, { alias _ = TemplateArgsOf!A; }))
            {
                static foreach (i, A; TemplateArgsOf!A)
                {
                    static if (__traits(compiles, { enum _ = B; }))
                        paramSig ~= "T"~i.stringof[0..$-2];
                    else
                        paramSig ~= "T"~i.stringof[0..$-2];
                }
                paramSig ~= ")(";
            }

            foreach (i, P; Parameters!A)
                paramSig ~= ParameterIdentifierTuple!A[i]~(i == Parameters!A.length - 1 ? null : ", ");
            paramSig ~= ")";
        }

        static if (DECLARING)
            return attrs~" "~fullIdentifier!(ReturnType!A)~" "~identifier!A~paramSig;
        else
            return identifier!A~paramSig;
    }();

    static if (isField!A)
    enum Signature =
    {
        static if (isManifest!F)
            return "enum "~fullIdentifier!(typeof(F))~" "~identifier!F~" = "~F.stringof;
        else static if (isStatic!F)
            return "static "~fullIdentifier!(typeof(F))~" "~identifier!F;
        else
            return fullIdentifier!(typeof(F))~" "~identifier!F;
    }();

    static if (!isCallable!A && !isField!A)
        enum Signature = fullIdentifier!A;
}

/// Gets an alias to the return type of `M` in `A`.
public alias ReturnType(alias A, string M) = ReturnType!(getChild!(A, M));
/// Gets an alias to the parameters of `M` in `A`.
public alias Parameters(alias A, string M) = Parameters!(getChild!(A, M));
/// Gets an alias to the element type of `M` in `A`.
public alias ElementType(alias A, string M) = ElementType!(typeof(getChild!(A, M)));
/// Gets an alias to the length of `M` in `A`.
public alias Length(alias A, string M) = Length!(typeof(getChild!(A, M)));
/// Gets an `AliasSeq` with all types implemented by `M` in `A`.
public alias Implements(alias A, string M) = Implements!(getChild!(A, M));
/// Gets an `AliasSeq` with all fields in `M` in `A`.
public alias Fields(alias A, string M) = Fields!(getChild!(A, M));
/// Gets an `AliasSeq` with all functions in `M` in `A`.
public alias Functions(alias A, string M) = Functions!(getChild!(A, M));
/// Gets an `AliasSeq` with all types in `M` in `A`.
public alias Types(alias A, string M) = Types!(getChild!(A, M));
/// Gets an `AliasSeq` with all templates in `M` in `A`.
public alias Templates(alias A, string M) = Templates!(getChild!(A, M));
/// Gets the signature of `M` in `A`.
public alias Signature(alias A, string M) = Signature!(getChild!(A, M));