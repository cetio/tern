module main;

import tern;
import std.stdio;
import avocet;

import tern.algorithm.iteration;
import tern.algorithm.lazy_filter;

void main()
{
    import tern.digest.chacha20;
    Opaque!(int, "xNYCfQA64hwq5GjMWHvaemB2tVgTrZsS") a = 0;
    writeln(a.value); // 1
    Opaque!(int, "xNYCfQA64hwq5GjMWHvaemB2tVgTrzsS") b = 0;
    writeln(b.value); // 1
    Opaque!(int, "xnYCfQA64hwq5GjMWHvaemB2tVgTrZss") c = 0;
    writeln(c.value); // 1
}