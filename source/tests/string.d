module tests.string;
import tern.string;

import std.stdio;
unittest
{
    foreach(c; "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"){
        assert(c.isAlpha());
        assert(c.isAlphaNum());
        assert(!c.isDigit());
    }
    foreach(c; "abcdefghijklmnopqrstuvwxyz"){
        assert(c.isLower());
        assert(!c.isUpper());
    }
    foreach(c; "ABCDEFGHIJKLMNOPQRSTUVWXYZ"){
        assert(!c.isLower());
        assert(c.isUpper());
    }
}
