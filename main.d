module main;

//import tern;
import std.stdio;
import avocet;

import tern.algorithm.iteration;
import tern.algorithm.lazy_filter;

void main()
{
    float[] a = [1, 2, 3];
    writeln(a.map!(x => x > 1)[0]);
}