module tests.meta;
import tern.meta;
import tern.traits;

unittest
{
    alias Seq = AliasSeq!(int, float, string);
    static assert(seqContains!(string, Seq) == true);
}

unittest
{
    alias Seq = AliasSeq!(int, float, string);
    alias FilteredSeq = seqFilter!(isFloatingPoint, Seq);
    static assert(is(FilteredSeq == AliasSeq!(float)));
}

unittest
{
    alias Seq = AliasSeq!(int, float, string);
    alias S = seqFilter!("isFloatingPoint!X", Seq);
    static assert(is(S == AliasSeq!(float)));
}

unittest
{
    alias Seq = AliasSeq!(int, float, string);
    alias MappedSeq = seqMap!(isIntegral, Seq);
    static assert(MappedSeq.stringof == "AliasSeq!(true, false, false)");
}

unittest
{
    alias Seq = AliasSeq!(int, byte, long);
    alias S = seqMap!("Alias!(X.sizeof)", Seq);
    static assert(S.stringof == "AliasSeq!(4LU, 1LU, 8LU)");
}

unittest
{
    alias Seq = AliasSeq!(int, float, string);
    static assert(seqIndexOf!(string, Seq) == 2);
}

unittest
{
    alias A = int;
    alias B = int;
    static assert(isSame!(A, B));
}