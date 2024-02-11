/// Utilities for working with strings and characters of any encoding
module caiman.string;

import std.array;
import std.algorithm;
import caiman.traits;

public:
static:
pure:
/* string mangle(string str) 
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
} */

T toUpper(T)(T str)
    if (isSomeString!T)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
    {
        if (c.isLower)
            ret[i] = cast(ElementType!T)(c - ('a' - 'A'));
        else
            ret[i] = c;
    }
    return cast(string)ret;
}

T toLower(T)(T str)
    if (isSomeString!T)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
    {
        if (c.isUpper)
            ret[i] = cast(ElementType!T)(c + ('a' - 'A'));
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

bool isAlpha(T)(T str)
    if (isSomeString!T)
{
    foreach (c; str)
    {
        if (!c.isAlpha)
            return false;
    }
    return true;
}

bool isAlphaNum(T)(T str, uint base = 10)
    if (isSomeString!T)
{
    foreach (c; str)
    {
        if (!c.isAlpha && !c.isDigit(base))
            return false;
    }
    return true;
}

bool isNumeric(T)(T str, uint base = 10)
    if (isSomeString!T)
{
    foreach (c; str)
    {
        if (!c.isDigit(base))
            return false;
    }
    return true;
}

bool isUpper(T)(T str)
    if (isSomeString!T)
{
    foreach (c; str)
    {
        if (!c.isUpper)
            return false;
    }
    return true;
}

bool isLower(T)(T str)
    if (isSomeString!T)
{
    foreach (c; str)
    {
        if (!c.isLower)
            return false;
    }
    return true;
}

ptrdiff_t indexOf(T)(T str, char c)
    if (isSomeString!T)
{
    foreach (i, _c; str)
    {
        if (_c == c)
            return i;
    }
    return -1;
}

ptrdiff_t lastIndexOf(T)(T str, char c)
    if (isSomeString!T)
{
    ptrdiff_t last = -1;
    foreach (i, _c; str)
    {
        if (_c == c)
            last = i;
    }
    return last;
}