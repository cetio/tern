/// A collection of very unsafe but very powerful stack allocators
module caiman.experimental.stackallocator;

import caiman.traits;

public:
static:
@nogc:
/**
 * Allocates `T` on the stack, this is highly volatile for reference types, but will just create `T` normally for value types.
 *
 * Params:
 *   T = The type to be allocated.
 *
 * Returns:
 *   A new instance of `T` allocated on the stack.
 *
 * Example:
 *   ```d
 *   B a = stackNew!B;
 *   writeln(a); // caiman.main.B
 *   ```
 */
T stackNew(T)()
{
    static if (!isReferenceType!T)
    {
        T ret;
        return ret;
    }

    static ubyte[__traits(classInstanceSize, T)] bytes;
    foreach (field; FieldNames!T)
    {
        auto init = __traits(getMember, T, field).init;
        ptrdiff_t offset = __traits(getMember, T, field).offsetof;
        bytes[offset..(offset + TypeOf!(T, field).sizeof)] = (cast(ubyte*)&init)[0..TypeOf!(T, field).sizeof];
    }
    // No idea what the next 8 bytes are, padding??
    *cast(void**)bytes.ptr = T.classinfo.vtbl.ptr;
    return cast(T)bytes.ptr;
}