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

    const upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const lowerCase = "abcdefghijklmnopqrstuvwxyz";


    foreach(c; upperCase ~ lowerCase){
        assert(c.isAlpha());
        assert(c.isAlphaNum());
        assert(!c.isDigit());
    }
    foreach(c; lowerCase){
        assert(c.isLower());
        assert(!c.isUpper());
    }
    foreach(c; upperCase){
        assert(!c.isLower());
        assert(c.isUpper());
    }

    foreach(i,c; lowerCase){
        assert(c.toUpper == upperCase[i]);
        assert(c == upperCase[i].toLower);
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
    assert("hello_world_this_looks_like_shit" == toSnakeCase("helloWorldThisLooksLikeShit"));
    assert("helloWorldThisLooksLikeShit" == toCamelCase("HelloWorldThisLooksLikeShit"));
}