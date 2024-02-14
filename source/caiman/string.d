/// String mangling, `std.ascii` functionality, and general string utilities to replace `std.string`
module caiman.string;

import std.array;
import std.algorithm;
import caiman.traits;

public:
static:
pure:
string mangle(string str) 
{
    size_t idx = str.lastIndexOf('.');
    if (idx != -1)
        str = str[(idx + 1)..$];
    str = str.replace("*", "PTR")
        .replace("[", "OPBRK")
        .replace("]", "CLBRK")
        .replace(",", "COMMA")
        .replace("!", "EXCLM");
    return cast(string)str.filter!(c => isAlphaNum(c) || c == '_').array;
}

string toUpper(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
    {
        if (c.isLower)
            ret[i] = cast(char)(c - ('a' - 'A'));
        else
            ret[i] = c;
    }
    return cast(string)ret;
}

string toLower(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
    {
        if (c.isUpper)
            ret[i] = cast(char)(c + ('a' - 'A'));
        else
            ret[i] = c;
    }
    return cast(string)ret;
}

@nogc:
bool isAlpha(T)(T c) if (isSomeChar!T) => (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
bool isDigit(T)(T c, uint base = 10) if (isSomeChar!T) => (c >= '0' && c <= ('9' - base)) || (base > 10 && (c >= 'a' && c <= ('f' - base)) || (c >= 'A' && c <= ('F' - base)));
bool isAlphaNum(T)(T c, uint base = 10) if (isSomeChar!T) => c.isAlpha || c.isDigit(base);
bool isUpper(T)(T c) if (isSomeChar!T) => (c >= 'A' && c <= 'Z');
bool isLower(T)(T c) if (isSomeChar!T) => (c >= 'a' && c <= 'z');

bool isAlpha(string str)
{
    foreach (c; str)
    {
        if (!c.isAlpha)
            return false;
    }
    return true;
}

bool isAlphaNum(string str, uint base = 10)
{
    foreach (c; str)
    {
        if (!c.isAlpha && !c.isDigit(base))
            return false;
    }
    return true;
}

bool isNumeric(string str, uint base = 10)
{
    foreach (c; str)
    {
        if (!c.isDigit(base))
            return false;
    }
    return true;
}

bool isUpper(string str)
{
    foreach (c; str)
    {
        if (!c.isUpper)
            return false;
    }
    return true;
}

bool isLower(string str)
{
    foreach (c; str)
    {
        if (!c.isLower)
            return false;
    }
    return true;
}

ptrdiff_t indexOf(string str, char c)
{
    foreach (i, _c; str)
    {
        if (_c == c)
            return i;
    }
    return -1;
}

ptrdiff_t lastIndexOf(string str, char c)
{
    foreach_reverse (i, _c; str)
    {
        if (_c == c)
            return i;
    }
    return -1;
}

ptrdiff_t indexOf(string str, string substr) 
{
    if (substr.length > str.length)
        return -1;

    foreach (i; 0..(str.length - substr.length))
    {
        bool found = true;
        foreach (j, c; substr)
        {
            if (str[i + j] != c) 
            {
                found = false;
                break;
            }
        }
        if (found)
            return i;
    }
    return -1;
}

ptrdiff_t lastIndexOf(string str, string substr) 
{
    if (substr.length > str.length)
        return -1;

    foreach_reverse (i; 0 .. (str.length - substr.length + 1)) 
    {
        bool found = true;
        foreach (j, c; substr) 
        {
            if (str[i + j] != c) 
            {
                found = false;
                break;
            }
        }
        if (found)
            return i;
    }
    return -1;
}