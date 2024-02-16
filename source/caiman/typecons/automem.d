/// Automated memory releasing/disposing wrappers
module caiman.typecons.automem;

import std.experimental.allocator;
import std.typecons;
import caiman.object;
import caiman.traits;
import caiman.meta;

/// Automatically releases a pointer of type `T` when exiting scope, assumes no ownership is passed.
public struct Unique(T, alias FREE = typeof(null))
{
    T* ptr;
    alias ptr this;

public:
final:
    private alias NULL = typeof(null);

    this(P : U*, U)(P ptr)
    {
        this.ptr = cast(T*)ptr;
    }

    auto opImplicitCastFrom(P : U*, U)(P ptr)
    {
        return Unique!(T, FREE)(ptr);
    }

    void release()
    {
        void[] arr;
        (cast(ptrdiff_t*)&arr)[0] = T.sizeof;
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

/// Automatically disposing wrapper, will attempt to dispose by calling `close`, `dispose`, or `destroy` if all else fails.
public struct Disposable(T)
{
    T value;
    alias value this;

public:
final:
    this(T val)
    {
        value = val;
    }

    auto opImplicitCastFrom(T val)
    {
        return Disposable!T(val);
    }

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