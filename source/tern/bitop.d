module tern.bitop;

public import core.bitop;

public:
static:
pure:
Tuple!(A, B) mulCarry(A, B, C)(A hi, B lo, C muli)
    if (isIntegral!A && isIntegral!B && isIntegral!C)
{
    auto rlo = lo * muli;
    auto rhi = hi * muli + (rlo >> (B.sizeof * 8));
    return tuple(cast(A)(rhi), cast(B)(rlo));
}

Tuple!(A, B) divCarry(A, B, C)(A hi, B lo, C divi)
    if (isIntegral!A && isIntegral!B && isIntegral!C)
{
    auto dividend = (cast(ulong)hi << (B.sizeof * 8)) | lo;
    auto divisor = cast(ulong)divi;

    auto ret = dividend / divisor;
    auto remainder = dividend % divisor;

    return tuple(cast(A)(ret >> (B.sizeof * 8)), cast(B)remainder);
}

Tuple!(A, B) addCarry(A, B, C)(A hi, B lo, C src)
    if (isIntegral!A && isIntegral!B && isIntegral!C)
{
    auto rlo = lo + src;
    auto carry = rlo < lo ? 1 : 0;
    return tuple(cast(A)((hi + carry) & A.max), cast(B)(rlo & B.max));
}

Tuple!(A, B) subCarry(A, B, C)(A hi, B lo, C src)
    if (isIntegral!A && isIntegral!B && isIntegral!C)
{
    auto borrow = lo < src ? 1 : 0;
    return tuple(cast(A)((hi - borrow) & A.max), cast(B)((lo - src) & B.max));
}

Tuple!(A, B) moduloCarry(A, B, C)(A hi, B lo, C divi)
    if (isIntegral!A && isIntegral!B && isIntegral!C)
{
    auto dividend = (cast(ulong)hi << (B.sizeof * 8 - 1)) | lo;
    auto divisor = cast(ulong)divi;

    auto remainder = dividend % divisor;
    return tuple(cast(A)(remainder >> (B.sizeof * 8 - 1)), cast(B)remainder);
}

string toBitString(ubyte[] bytes)
{
    string ret;
    foreach_reverse (b; bytes)
    {
        foreach_reverse (i; 0..7)
            ret ~= (((b >> i) & 1) ? "1" : "0");
    }
    return ret;
}

// rol
// ror
// shl
// shr
// bits