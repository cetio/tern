module tests.string;
import tern.string;
import std.stdio;
unittest
{
    foreach(c; "1234567890"){
        assert(c.isDigit);
    }
    foreach(c; "1234567890abcdef"){
        assert(c.isDigit(16));
    }
    assert(!'g'.isDigit(16));

    foreach(c; "01234567"){
        assert(c.isDigit(8));
    }
    assert(!'8'.isDigit(8));
    
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
unittest{
    assert("Test".padLeft(10).length == 10);
    assert("Test".padLeft(10) == "      Test");

    assert("Test".padRight(10).length == 10);
    assert("Test".padRight(10) == "Test      ");
}
unittest
{
    assert("hello-world-this-looks-like-shit" == toKebabCase("helloWorldThisLooksLikeShit"));
    assert("HelloWorldThisLooksLikeShit" == toPascalCase("helloWorldThisLooksLikeShit"));
}