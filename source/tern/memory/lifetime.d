module tern.memory.lifetime;

public:
static:
@nogc:
pure:
/**
 * Checks if `val` is actually a valid, non-null class, and has a valid vtable.
 *
 * Params:
 *  val = The value to check if null.
 *
 * Returns:
 *  True if `val` is null or has an invalid vtable.
 */
@trusted bool isNull(T)(T val)
    if (is(T == class) || isPointer!T)
{
    return val is null || *cast(void**)val is null;
}