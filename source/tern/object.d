/// Advanced stores and loads, endianness, cloning, and more.
module tern.object;

import tern.memory;
import tern.traits;
import std.meta;

public enum Endianness
{
    Native,
    LittleEndian,
    BigEndian
}

public:
pure:
/**
 * Swaps the endianness of the provided value, if applicable.
 *
 * Params:
 *  val = The value to swap endianness.
 *  endianness = The desired endianness.
 *
 * Returns:
 *  The value with swapped endianness.
 */
@trusted T makeEndian(T)(T val, Endianness endianness)
{
    version (LittleEndian)
    {
        if (endianness == Endianness.BigEndian)
            byteswap(reference!val, sizeof!T);
    }
    else version (BigEndian)
    {
        if (endianness == Endianness.LittleEndian)
            byteswap(reference!val, sizeof!T);
    }
    return val;
}

/**
 * Dynamically tries to load the length of `val`, this is useful for arbitrary range types.
 *
 * Params:
 *  val = The value to load the length of.
 *
 * Remarks:
 *  Returns 1 if `T` has no length apparent.
 *
 * Returns:
 *  The loaded length.
 */
pragma(inline, true)
size_t loadLength(size_t DIM : 0, T)(T val)
{
    static if (__traits(compiles, { auto _ = val.opDollar!DIM; }))
        return val.opDollar!DIM;
    else static if (DIM == 0)
        return opDollar();
    else static if (isForward!T)
    {
        size_t length;
        foreach (u; val[DIM])
            length++;
        return length;
    }
    else
        return 1;
}

/// ditto
pragma(inline, true)
size_t loadLength(T)(T val)
{
    static if (__traits(compiles, { auto _ = val.opDollar(); }))
        return val.opDollar();
    else static if (__traits(compiles, { auto _ = val.length; }))
        return val.length;
    else static if (isForward!T)
    {
        size_t length;
        foreach (u; val)
            length++;
        return length;
    }
    else
        return 1;
}

/**
 * Shallow clones a value.
 *
 * Params:
 *  val = The value to be shallow cloned.
 *
 * Returns:
 *  A shallow clone of the provided value.
 *
 * Example:
 * ```d
 * A a;
 * A b = a.dup();
 * ```
 */
pragma(inline, true)
T dup(T)(T val)
    if (!isArray!T && !isAssignable!(T, Object))
{
    return val;
}

/**
 * Deep clones a value.
 *
 * Params:
 *  val = The value to be deep cloned.
 *
 * Returns:
 *  A deep clone of the provided value.
 *
 * Example:
 * ```d
 * B a; // where B is a class containing indirection
 * B b = a.ddup();
 * ```
 */
pragma(inline, true)
T ddup(T)(T val)
    if (!isArray!T && !isAssociativeArray!T)
{
    static if (!hasIndirections!T || isPointer!T)
        return val;
    else
    {
        T ret = factory!T;
        static foreach (field; Fields!T)
        {
            static if (isMutable!(TypeOf!(T, field)))
            {
                static if (!hasIndirections!(TypeOf!(T, field)))
                    __traits(getMember, ret, field) = __traits(getMember, val, field);
                else
                    __traits(getMember, ret, field) = __traits(getMember, val, field).ddup();
            }
        }
        return ret;
    }
}

/// ditto
pragma(inline, true)
T ddup(T)(T arr)
    if (isArray!T && !isAssociativeArray!T)
{
    T ret;
    foreach (u; arr)
        ret ~= u.ddup();
    return ret;
}

/// ditto
pragma(inline, true)
T ddup(T)(T arr)
    if (isAssociativeArray!T)
{
    T ret;
    foreach (key, value; arr)
        ret[key.ddup()] = value.ddup();
    return ret;
}

/**
 * Duplicates `val` using soft[de]serialization, avoiding deep cloning.
 *
 * This is safer than a normal shallow copy, as it ensures that the new value has a totally new instance.
 *
 * Params:
 *  val = The value to be duplicated.
 *
 * Returns:
 *  Clone of `val`.
 */
pragma(inline, true)
@trusted T qdup(T)(T val)
{
    static if (isArray!T)
    {
        size_t size = ElementType!T.sizeof * val.length;
        T ret = factory!T(size / ElementType!T.sizeof);
        memcpy(cast(void*)val.ptr, cast(void*)ret.ptr, size);
        return ret;
    }
    else
    {
        T ret = factory!T;
        memcpy(reference!val, reference!ret, sizeof!T);
        return ret;
    }
}

/// Creates a new instance of `T` dynamically based on its traits, with optional construction args.
pragma(inline, true)
T factory(T, ARGS...)(ARGS args)
{
    static if (isDynamicArray!T)
    {
        static if (ARGS.length == 0)
            return new T(0);
        else
            return new T(args);
    }
    else static if (isReferenceType!T)
        return new T(args);
    else 
    {
        static if (ARGS.length != 0)
            return T(args);
        else
            return T.init;
    }
}

@nogc:
/**
 * Dynamically stores all data from `src` to `dst`.
 * 
 * Params:
 *  src = Value to copy data from.
 *  dst = Value to copy data to.
 */
pragma(inline, true)
@trusted void store(A, B)(const scope A src, ref B dst)
{
    static if (isReinterpretable!(A, B))
        memcpy(reference!src, reference!dst, sizeof!B);
    else
    {
        static foreach (field; Fields!B)
        {
            static if (hasChild!(A, field) && isMutable!(getChild!(A, field)) && isMutable!(getChild!(B, field)))
                __traits(getMember, dst, field).store(__traits(getMember, src, field));
        }
    }
}

/// Defines `L` as a store field, for use in store merging.
public enum mergeAs(alias F) = "mergeAs"~identifier!F;

/**
 * Performs a merged store on `dst` from a sequence of fields.
 *
 * This is done by portioning all fields to as little writes as necessary, and then doing hardware-accelerated
 * writes to set all field data. This can be substantially faster than normal set operations.
 *
 * Params:
 *  VARS = The variables that will be written to `dst` as field data.
 *  dst = The destination data to write fields to.
 *
 * Remarks:
 *  - All variables in `VARS` must be sequentially ordered in stack memory.
 *  - All variables in `VARS` must be named as the fields in `dst` they correspond to, or have a `mergeAs!(T.x)` attribute set.
 *  - This may be unusable in situations where the compiler does memory operations due to the aforementioned.
 */
public template storeMerged(VARS...)
    if ((allSatisfy!(isLocal, VARS) || allSatisfy!(isField, VARS)) && VARS.length >= 1)
{
private:
    pure size_t alignTo(size_t size, size_t alignment)()
    {
        return size + (alignment - ((size % alignment) | alignment));
    }

    template names()
    {
        enum udaName(alias VAR) =
        {
            static foreach (ATTR; __traits(getAttributes, VAR))
            {
                static if (__traits(compiles, { auto _ = ATTR; }) && isString!(typeof(ATTR)) && ATTR.length > 6)
                    return ATTR[6..$];
            }
            return null;
        }();

        alias names = AliasSeq!();

        static foreach (VAR; VARS)
        {
            static if (udaName!VAR != null)
                names = AliasSeq!(names, udaName!VAR);
            else
                names = AliasSeq!(names, __traits(identifier, VAR));
        }
    }

    template prepare(A)
    {
        alias fields = AliasSeq!();
        alias sizes = AliasSeq!();

        static foreach (i, name; s!())
        {
            static if (i == 0)
            {
                fields = AliasSeq!(fields, name);
                sizes = AliasSeq!(sizes, alignTo!(typeof(getChild!(A, name)).sizeof, typeof(getChild!(A, name)).alignof)());
            } 
            else static if ((getChild!(A, name).offsetof - getChild!(A, s!()[i - 1]).offsetof) != alignTo!(getChild!(A, s!()[i - 1]).sizeof, getChild!(A, name).alignof))
            {
                fields = AliasSeq!(fields, name);
                sizes = AliasSeq!(sizes, alignTo!(typeof(getChild!(A, name)).sizeof, typeof(getChild!(A, name)).alignof)());
            }
            else
            {
                sizes = AliasSeq!(sizes[0..$-1], alignTo!(sizes[$-1], getChild!(A, name).alignof)() + getChild!(A, name).sizeof);
            }
        }
    }

public:
    /**
     * Performs a merged store on `dst` from a sequence of fields.
     *
     * This is done by portioning all fields to as little writes as necessary, and then doing hardware-accelerated
     * writes to set all field data. This can be substantially faster than normal set operations.
     *
     * Params:
     *  VARS = The variables that will be written to `dst` as field data.
     *  dst = The destination data to write fields to.
     *
     * Remarks:
     *  - All variables in `VARS` must be sequentially ordered in stack memory.
     *  - All variables in `VARS` must be named as the fields in `dst` they correspond to, or have a `mergeAs!(T.x)` attribute set.
     *  - This may be unusable in situations where the compiler does memory operations due to the aforementioned.
     */
    @trusted void storeMerged(A)(ref A dst)
    {
        static assert(Fields!A.length >= VARS.length, "'"~A.stringof~"' must have the same number or greater fields as locals being storeted!");

        debug
        {
            size_t offset;
            foreach (i, VAR; VARS)
            {
                offset += VAR.alignof - ((offset % VAR.alignof) | VAR.alignof);
                assert(cast(void*)&(VARS[0]) + offset == cast(void*)&(VARS[i]), 
                    "Variables must be sequentially declared to use specialized field storeting, if they are, the compiler is optimizing this out!");
                offset += VAR.sizeof;
            }
        }

        alias fields = prepare!A.fields;
        alias sizes = prepare!A.sizes;

        static foreach (i, VAR; VARS)
        {{
            static assert(hasChild!(A, s!()[i]) && isField!(A, s!()[i]) && is(Unqual!(typeof(getChild!(A, s!()[i]))) == Unqual!(typeof(VAR))),
                "Variable '"~identifier!VAR~"' does not represent a valid field in '"~A.stringof~"'!");
        }}

        static foreach (i, field; fields)
            memcpy!(sizes[i])(cast(void*)&VARS[staticIndexOf!(field, s!())], cast(void*)&__traits(getMember, dst, field));
    }
}

/**
 * Performs a merged load from `dst` to a sequence of variables.
 *
 * This is done by portioning all fields to as little reads as necessary, and then doing hardware-accelerated
 * writes from all of the field data. This can be substantially faster than normal read operations.
 *
 * Params:
 *  VARS = The variables that will be written to `dst` as field data.
 *  dst = The destination data to read fields from.
 *
 * Remarks:
 *  - All variables in `VARS` must be sequentially ordered in stack memory.
 *  - All variables in `VARS` must be named as the fields in `dst` they correspond to, or have a `mergeAs!(T.x)` attribute set.
 *  - This may be unusable in situations where the compiler does memory operations due to the aforementioned.
 */
public template loadMerged(VARS...)
    if ((allSatisfy!(isLocal, VARS) || allSatisfy!(isField, VARS)) && VARS.length >= 1)
{
private:
    pure size_t alignTo(size_t size, size_t alignment)()
    {
        return size + (alignment - ((size % alignment) | alignment));
    }

    template names()
    {
        enum udaName(alias VAR) =
        {
            static foreach (ATTR; __traits(getAttributes, VAR))
            {
                static if (__traits(compiles, { auto _ = ATTR; }) && isString!(typeof(ATTR)) && ATTR.length > 6)
                    return ATTR[6..$];
            }
            return null;
        }();

        alias names = AliasSeq!();

        static foreach (VAR; VARS)
        {
            static if (udaName!VAR != null)
                names = AliasSeq!(names, udaName!VAR);
            else
                names = AliasSeq!(names, __traits(identifier, VAR));
        }
    }

    template prepare(A)
    {
        alias fields = AliasSeq!();
        alias sizes = AliasSeq!();

        static foreach (i, name; s!())
        {
            static if (i == 0)
            {
                fields = AliasSeq!(fields, name);
                sizes = AliasSeq!(sizes, alignTo!(typeof(getChild!(A, name)).sizeof, typeof(getChild!(A, name)).alignof)());
            } 
            else static if ((getChild!(A, name).offsetof - getChild!(A, s!()[i - 1]).offsetof) != alignTo!(getChild!(A, s!()[i - 1]).sizeof, getChild!(A, name).alignof))
            {
                fields = AliasSeq!(fields, name);
                sizes = AliasSeq!(sizes, alignTo!(typeof(getChild!(A, name)).sizeof, typeof(getChild!(A, name)).alignof)());
            }
            else
            {
                sizes = AliasSeq!(sizes[0..$-1], alignTo!(sizes[$-1], getChild!(A, name).alignof)() + getChild!(A, name).sizeof);
            }
        }
    }

public:
    /**
     * Performs a merged load from `dst` to a sequence of variables.
     *
     * This is done by portioning all fields to as little reads as necessary, and then doing hardware-accelerated
     * writes from all of the field data. This can be substantially faster than normal read operations.
     *
     * Params:
     *  VARS = The variables that will be written to `dst` as field data.
     *  dst = The destination data to read fields from.
     *
     * Remarks:
     *  - All variables in `VARS` must be sequentially ordered in stack memory.
     *  - All variables in `VARS` must be named as the fields in `dst` they correspond to, or have a `mergeAs!(T.x)` attribute set.
     *  - This may be unusable in situations where the compiler does memory operations due to the aforementioned.
     */
    @trusted void loadMerged(A)(ref A dst)
    {
        static assert(Fields!A.length >= VARS.length, "'"~A.stringof~"' must have the same number or greater fields as locals being storeted!");

        debug
        {
            size_t offset;
            foreach (i, VAR; VARS)
            {
                offset += VAR.alignof - ((offset % VAR.alignof) | VAR.alignof);
                assert(cast(void*)&(VARS[0]) + offset == cast(void*)&(VARS[i]), 
                    "Variables must be sequentially declared to use specialized field storeting, if they are, the compiler is optimizing this out!");
                offset += VAR.sizeof;
            }
        }

        alias fields = prepare!A.fields;
        alias sizes = prepare!A.sizes;

        static foreach (i, VAR; VARS)
        {{
            static assert(hasChild!(A, s!()[i]) && isField!(A, s!()[i]) && is(Unqual!(typeof(getChild!(A, s!()[i]))) == Unqual!(typeof(VAR))),
                "Variable '"~identifier!VAR~"' does not represent a valid field in '"~A.stringof~"'!");
        }}

        static foreach (i, field; fields)
            memcpy!(sizes[i])(cast(void*)&__traits(getMember, dst, field), cast(void*)&VARS[staticIndexOf!(field, s!())]);
    }
}