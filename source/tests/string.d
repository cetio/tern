module tests.string;
import tern.string;

unittest
{
    foreach(c; "1234567890"){
        assert(c.isDigit);
    }
    foreach(c; "1234567890abcdef"){
        assert(c.isDigit(16));
    }
    assert(!'g'.isDigit(16));
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
