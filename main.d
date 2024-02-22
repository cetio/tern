module main;

import tern;
import std.stdio;
import avocet;

import tern.algorithm.iteration;
import tern.algorithm.lazy_filter;

void main()
{
    import tern.digest.chacha20;
    Opaque!(int, "xnYCfQA64hwq5GjMWHvaemB2tVgTrZsS", Anura256) a = 1;
    writeln(a.value); // 1
    Opaque!(int, "xnYCfQA64hwq5GjMWHvaemB2tVgTrZss") b = 1;
    writeln(b); // 1
    Opaque!(int, "xnYCfQA64hwq5GjMWHvaemB2tVgTrzss") c = 0;
    writeln(c); // 1
}