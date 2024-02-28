module tests.vector;
import tern.vector;
import std.stdio;
unittest
{
    static foreach(LENGTH ; [4, 8])
    {{
        int[LENGTH] x;
        auto to = Vector!(int[LENGTH])(x);
        
        to+=1;
        to.writeln();
        to-=1;
        to.writeln();
    }}
}
