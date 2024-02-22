/// Wrappers for automatically managing memory
module tern.typecons.automem;

import tern.typecons.security;
import tern.traits;
import tern.meta;
import std.experimental.allocator;
import std.typecons;
import std.conv;

private alias NULL = typeof(null);
/// Automatically releases a pointer of type `T` when exiting scope, assumes no ownership is passed.
public class Unique(T, alias FREE = typeof(null))
{
    T* ptr;
    alias ptr this;

public:
final:
    this(P : U*, U)(P ptr)
    {
        this.ptr = cast(T*)ptr;
    }

    auto opAssign(A)(A ahs)
    {
        static assert(0, "Cannot reassign a Unique!");
    }

    /// Releases/frees this manager. Implementation defined.
    void release()
    {
        void[] arr;
        (cast(size_t*)&arr)[0] = T.sizeof;
        (cast(void**)&arr)[1] = cast(void*)ptr;

        if (theAllocator.owns(arr) == Ternary.yes)
            theAllocator.deallocate(arr);
        else if (!is(FREE == NULL))
            FREE(ptr);
        else
        {
            if (ptr !is null)
                destroy(*ptr);

            destroy(ptr);
        }
    }

    ~this()
    {
        release();
    }
}

/// Helper function for creating a unique.
Unique!T unique(T : U*, U)(T ptr)
{
    return new Unique!T(ptr);
}

/// Automatically releases a pointer of type `T` when exiting scope, allows any kind of ownership, but does not ref count.
public class Scoped(T, alias FREE = typeof(null))
{
    T* ptr;
    alias ptr this;

public:
final:
    this(P : U*, U)(P ptr)
    {
        this.ptr = cast(T*)ptr;
    }

    /// Releases/frees this manager. Implementation defined.
    void release()
    {
        void[] arr;
        (cast(size_t*)&arr)[0] = T.sizeof;
        (cast(void**)&arr)[1] = cast(void*)ptr;

        if (theAllocator.owns(arr) == Ternary.yes)
            theAllocator.deallocate(arr);
        else if (!is(FREE == NULL))
            FREE(ptr);
        else
        {
            if (ptr !is null)
                destroy(*ptr);

            destroy(ptr);
        }
    }

    ~this()
    {
        release();
    }
}

/// Helper function for creating a scoped.
Scoped!T scoped(T : U*, U)(T ptr)
{
    return new Scoped!T(ptr);
}

/// Counts references to the origin `RefCounted` and only releases if all references have also destructed.
public class RefCounted(T, alias FREE = typeof(null))
{
    T* ptr;
    alias ptr this;

public:
final:
    shared Atomic!ptrdiff_t refs;
    shared(Atomic!(ptrdiff_t))* pref;

    this(P : U*, U)(P ptr)
    {
        this.ptr = cast(T*)ptr;
        this.refs = 1;
        this.pref = &refs;
    }

    this(P : RefCounted, U)(P ptr)
    {
        this.ptr = cast(T*)ptr.ptr;
        this.pref = ptr.pref;
        (*pref)++;
    }

    auto opUnary(string op)()
    {
        static assert (op != "*" || !is(T == class), "Cannot dereference a RefCounted(T) where T is a class!");
        return mixin(op~"ptr");
    }

    auto opAssign(A)(A ahs)
        if (is(A : U*, U) || is(A : RefCounted, U))
    {
        static if (is(A == RefCounted))
        {
            this.ptr = cast(T*)ahs.ptr;
            this.pref = ahs.pref;
            (*pref)++;
        }
        else
        {
            this.ptr = cast(T*)ahs;
            this.refs = 1;
            this.pref = &refs;
        }
        return this;
    }

    /// Releases/frees this manager. Implementation defined.
    void release()
    {
        (*pref)--;
        if (*pref <= 0)
        {
            void[] arr;
            (cast(size_t*)&arr)[0] = T.sizeof;
            (cast(void**)&arr)[1] = cast(void*)ptr;

            if (theAllocator.owns(arr) == Ternary.yes)
                theAllocator.deallocate(arr);
            else if (!is(FREE == NULL))
                FREE(ptr);
            else
            {
                if (ptr !is null)
                    destroy(*ptr);

                destroy(ptr);
            }
        }
    }

    ~this()
    {
        release();
    }
}

/// Helper function for creating a ref counted.
RefCounted!T refCounted(T : U*, U)(T ptr)
{
    return RefCounted!T(ptr);
}

private void*[] tracking;
/// Stores all pointers and sweeps through the array after a `Tracked` destructs.
public class Tracked(T, alias FREE = typeof(null))
    if (is(T == class))
{
    T* ptr;
    alias ptr this;

public:
final:
    this(P : U*, U)(P ptr)
    {
        this.ptr = cast(T*)ptr;
        tracking ~= cast(void*)ptr;
    }

    ~this()
    {
        foreach (ref ptr; tracking)
        {
            if (ptr != null && ptr.isNull)
            {
                void[] arr;
                (cast(size_t*)&arr)[0] = T.sizeof;
                (cast(void**)&arr)[1] = cast(void*)ptr;

                if (theAllocator.owns(arr) == Ternary.yes)
                    theAllocator.deallocate(arr);
                else if (!is(FREE == NULL))
                    FREE(ptr);
                else
                {
                    if (ptr !is null)
                        destroy(*ptr);

                    destroy(ptr);
                }
            }
            ptr = null;
        }
    }
}

/// Helper function for creating a tracked.
Tracked!T tracked(T : U*, U)(T ptr)
    if (is(T == class))
{
    return new Tracked!T(ptr);
}

/// Automatically disposing wrapper, will attempt to dispose by calling `close`, `dispose`, or `destroy` if all else fails.
public class Disposable(T)
{
    T value;
    alias value this;

public:
final:
    this(T val)
    {
        value = val;
    }

    /// Releases/frees this manager. Implementation defined.
    void release()
    {
        static if (seqContains!("close", FunctionNames!T))
        {
            static assert(Parameters!(TypeOf!(T, "close")).length == 0, "Close function expected to have no parameters!");
            mixin("value.close();");
        }
        else static if (seqContains!("dispose", FunctionNames!T))
        {
            static assert(Parameters!(TypeOf!(T, "dispose")).length == 0, "Dispose function expected to have no parameters!");
            mixin("value.dispose();");
        }
        else
            destroy(value);
    }
    
    ~this()
    {
        release();
    }
}

/// Helper function for creating a disposable.
Disposable!T disposable(T)(T val)
{
    return new Disposable!T(val);
}