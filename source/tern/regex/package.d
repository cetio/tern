// Comptime and runtime Regex that matches fast and builds even faster
module tern.regex;

import tern.regex.builder;
import tern.regex.matcher;

package static string[string] lookups;
static this()
{
    lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
    lookups["\\d"] = expand("0-9", lookups);
    lookups["\\s"] = expand("  t\r\n\f", lookups);
    lookups["\\h"] = expand("  t", lookups);
    lookups["\\t"] = expand("\t", lookups);
    lookups["\\r"] = expand("\r", lookups);
    lookups["\\n"] = expand("\n", lookups);
    lookups["\\f"] = expand("\f", lookups);
    lookups["\\v"] = expand("\v", lookups);
    lookups["\\b"] = expand("\b", lookups);
    lookups["\\a"] = expand("\a", lookups);
    lookups["\\0"] = expand("\0", lookups);
}

public template regex(string PATTERN, ubyte FLAGS = GLOBAL)
{
public:
final:
    Regex ctor()
    {
        return new Regex(PATTERN, FLAGS);
    }

    pure string[] matchFirst(string TEXT)()
    {
        string[string] lookups;
        lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
        lookups["\\d"] = expand("0-9", lookups);
        lookups["\\s"] = expand("  t\r\n\f", lookups);
        lookups["\\h"] = expand("  t", lookups);
        lookups["\\t"] = expand("\t", lookups);
        lookups["\\r"] = expand("\r", lookups);
        lookups["\\n"] = expand("\n", lookups);
        lookups["\\f"] = expand("\f", lookups);
        lookups["\\v"] = expand("\v", lookups);
        lookups["\\b"] = expand("\b", lookups);
        lookups["\\a"] = expand("\a", lookups);
        lookups["\\0"] = expand("\0", lookups);

        auto ret = matchInternal(PATTERN.build(lookups), FLAGS, TEXT, 1);
        return ret.length != 0 ? ret[0] : null;
    }

    pure string[][] match(string TEXT)()
    {
        string[string] lookups;
        lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
        lookups["\\d"] = expand("0-9", lookups);
        lookups["\\s"] = expand("  t\r\n\f", lookups);
        lookups["\\h"] = expand("  t", lookups);
        lookups["\\t"] = expand("\t", lookups);
        lookups["\\r"] = expand("\r", lookups);
        lookups["\\n"] = expand("\n", lookups);
        lookups["\\f"] = expand("\f", lookups);
        lookups["\\v"] = expand("\v", lookups);
        lookups["\\b"] = expand("\b", lookups);
        lookups["\\a"] = expand("\a", lookups);
        lookups["\\0"] = expand("\0", lookups);

        return matchInternal(PATTERN.build(lookups), FLAGS, TEXT);
    }
}

public class Regex
{
private:
final:
    Element[] elements;
    ubyte flags;

public:
    
    this(string pattern, ubyte flags = GLOBAL)
    {
        this.elements = pattern.build(lookups);
        this.flags = flags;
    }

    string[] matchFirst(string text)
    {
        auto ret = matchInternal(elements, flags, text, 1);
        return ret.length != 0 ? ret[0] : null;
    }

    string[][] match(string text)
    {
        return matchInternal(elements, flags, text);
    }
} 