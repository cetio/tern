module main;

import caiman;
import std;

void printHex(ubyte[] arr) {
    foreach (ubyte value; arr) 
        writef("%02X ", value);
    writeln();
}

void main()
{
    //Regex re = regex!(r"^abc$").ctor();
    //re.match("ababc").writeln;
    /* Regex re = regex!(r"\[.{2}\]").ctor();
    re.match("a[12]").writeln;
    Regex re = regex!(r".+").ctor();
    re.match("a[123]").writeln; */
    assemble("
        mov [1], rax
    ").printHex;
    
}