module caiman.main;

import caiman;
import std;

alias to = caiman.conv.to;

void main()
{
    //simplifyEq("x ^^ (2 & 1)").writeln;
    int[2] arr = [1,0];
    int[] arr2 = [1,2];
    writeln(arr.to!(ulong[2]));
    writeln((cast(ubyte[8])arr).to!(ulong));
    string str = 1.8326812.to!string;
    writeln(str);
}