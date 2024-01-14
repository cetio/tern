module caiman.regex;

public import caiman.regex.builder;
public import caiman.regex.matcher;

package static string[string] lookups;
static this()
{
    lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
    lookups["\\d"] = expand("0-9", lookups);
    lookups["\\s"] = expand(" \t\r\n\f", lookups);
    lookups["\\h"] = expand(" \t", lookups);
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

    pure string[][] matchFirst(string TEXT)()
    {
        string[string] lookups;
        lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
        lookups["\\d"] = expand("0-9", lookups);
        lookups["\\s"] = expand(" \t\r\n\f", lookups);
        lookups["\\h"] = expand(" \t", lookups);
        lookups["\\t"] = expand("\t", lookups);
        lookups["\\r"] = expand("\r", lookups);
        lookups["\\n"] = expand("\n", lookups);
        lookups["\\f"] = expand("\f", lookups);
        lookups["\\v"] = expand("\v", lookups);
        lookups["\\b"] = expand("\b", lookups);
        lookups["\\a"] = expand("\a", lookups);
        lookups["\\0"] = expand("\0", lookups);

        return matchInternal(PATTERN.build(lookups), FLAGS, TEXT, 1);
    }

    pure string[][] match(string TEXT)()
    {
        string[string] lookups;
        lookups["\\w"] = expand("a-zA-Z0-9_", lookups);
        lookups["\\d"] = expand("0-9", lookups);
        lookups["\\s"] = expand(" \t\r\n\f", lookups);
        lookups["\\h"] = expand(" \t", lookups);
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

    string[][] matchFirst(string text)
    {
        return matchInternal(elements, flags, text, 1);
    }

    string[][] match(string text)
    {
        return matchInternal(elements, flags, text);
    }
} 