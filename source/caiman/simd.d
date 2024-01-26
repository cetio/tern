module caiman.simd;

import std.traits;
import caiman.memory.ops;
import core.simd;

public alias byte16 = Vector128!byte;
public alias ubyte16 = Vector128!ubyte;
public alias short8 = Vector128!short;
public alias ushort8 = Vector128!ushort;
public alias int4 = Vector128!int;
public alias uint4 = Vector128!uint;
public alias long2 = Vector128!long;
public alias ulong2 = Vector128!ulong;
public alias float4 = Vector128!float;
public alias double2 = Vector128!double;

public struct Vector128(T)
    if ((isIntegral!T || isFloatingPoint!T) && T.sizeof <= 8)
{
public:
final:
    static if (T.sizeof % 8 == 0)
        T[2] data;
    else static if (T.sizeof % 4 == 0)
        T[4] data;
    else static if (T.sizeof % 2 == 0)
        T[8] data;
    else
        T[16] data;
    alias data this;

    void clear()
    {
        void* arr = data.ptr;
        asm
        {
            mov R10, arr;
            movdqa XMM0, [R10];
            xorpd XMM0, XMM0;
            movdqa [R10], XMM0;
        }
    }

    Vector128!T opBinary(string op, V)(V val)
    {
        Vector128!T vec = this.ddup;
        void* arr = vec.data.ptr;
        static if (op == "+")
        {
            static if (is(V == byte) || is(V == ubyte))
            {
                asm 
                {
                    mov R10, arr;
                    movdqa XMM0, [R10];
                    pinsrb XMM1, val, 0;
                    pinsrb XMM1, val, 1;
                    pinsrb XMM1, val, 2;
                    pinsrb XMM1, val, 3;
                    pinsrb XMM1, val, 4;
                    pinsrb XMM1, val, 5;
                    pinsrb XMM1, val, 6;
                    pinsrb XMM1, val, 7;
                    pinsrb XMM1, val, 8;
                    pinsrb XMM1, val, 9;
                    pinsrb XMM1, val, 10;
                    pinsrb XMM1, val, 11;
                    pinsrb XMM1, val, 12;
                    pinsrb XMM1, val, 13;
                    pinsrb XMM1, val, 14;
                    pinsrb XMM1, val, 15;
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
            else static if (is(V == short) || is(V == ushort))
            {
                asm 
                {
                    mov R10, arr;
                    movdqa XMM0, [R10];
                    pinsrw XMM1, val, 0;
                    pinsrw XMM1, val, 1;
                    pinsrw XMM1, val, 3;
                    pinsrw XMM1, val, 4;
                    pinsrw XMM1, val, 5;
                    pinsrw XMM1, val, 6;
                    pinsrw XMM1, val, 7;
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
            else static if (is(V == int) || is(V == uint))
            {
                asm 
                {
                    mov R10, arr;
                    movdqa XMM0, [R10];
                    pinsrd XMM1, val, 0;
                    pinsrd XMM1, val, 1;
                    pinsrd XMM1, val, 2;
                    pinsrd XMM1, val, 3;
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
            else static if (is(V == long) || is(V == ulong))
            {
                asm 
                {
                    mov R10, arr;
                    movdqa XMM0, [R10];
                    pinsrq XMM1, val, 0;
                    pinsrq XMM1, val, 1;
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
            else static if (is(V == core.simd.long2) || is(V == core.simd.ulong2))
            {
                void* dat = &val;
                asm 
                {
                    mov R10, arr;
                    mov R11, dat;
                    movdqa XMM0, [R10];
                    movdqa XMM1, [R11];
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
            else static if (is(V == long2) || is(V == ulong2))
            {
                void* dat = val.data.ptr;
                asm 
                {
                    mov R10, arr;
                    mov R11, dat;
                    movdqa XMM0, [R10];
                    movdqa XMM1, [R11];
                    addps XMM0, XMM1;
                    movdqa [R10], XMM0;
                }
            }
        }
        else static if (op == "<<")
        {
            // PSLLQ
        }
        return vec;
    }
}

public alias byte32 = Vector256!byte;
public alias ubyte32 = Vector256!ubyte;
public alias short16 = Vector256!short;
public alias ushort16 = Vector256!ushort;
public alias int8 = Vector256!int;
public alias uint8 = Vector256!uint;
public alias long4 = Vector256!long;
public alias ulong4 = Vector256!ulong;
public alias float8 = Vector256!float;
public alias double4 = Vector256!double;

public struct Vector256(T)
    if ((isIntegral!T || isFloatingPoint!T) && T.sizeof <= 8)
{
    static if (T.sizeof % 8 == 0)
        T[4] data;
    else static if (T.sizeof % 4 == 0)
        T[8] data;
    else static if (T.sizeof % 2 == 0)
        T[16] data;
    else
        T[32] data;
    alias data this;
}