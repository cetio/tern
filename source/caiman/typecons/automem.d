/// Automated memory releasing pointers
module caiman.typecons.automem;

import std.experimental.allocator;
import std.typecons;
import caiman.object;

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