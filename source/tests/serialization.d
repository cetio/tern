module tests.serialization;

import tern.serialization;
import std.stdio;


unittest
{
    static foreach(value; [1, 2, 4, ubyte.max, ushort.max, uint.max, ulong.max, ubyte.max+1, ushort.max+1, uint.max+1, ulong.max+1, ubyte.max-1, ushort.max-1, uint.max-1, ulong.max-1, 69, 420])
    {{
        static foreach(typeS; ["ubyte", "byte", "ushort", "short", "int", "uint", "long", "ulong", "float", "real", "double"])
        {{
            alias T = mixin(typeS);
            T initial = cast(T) value;
            assert(initial == initial.serialize().deserialize!T);

            T[] arrayTest = [initial, initial, initial, initial, initial, initial, initial];
            
            assert(arrayTest == arrayTest.serialize().deserialize!(T[]));

        }}
    }}
    static foreach(value; [1, 2, 4, ubyte.max, ushort.max, 3.14159265359, 6.28318530718, 1.234567])
    {{
        static foreach(typeS; ["ubyte", "byte", "ushort", "short", "int", "uint", "long", "ulong", "float", "real", "double"])
        {{
            alias T = mixin(typeS);
            T initial = cast(T) value;
            assert(initial == initial.serialize().deserialize!T);

            T[] arrayTest = [initial, initial, initial, initial, initial, initial, initial];

            assert(arrayTest == arrayTest.serialize().deserialize!(T[]));
        }}
    }}

}