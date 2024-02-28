/// Highlighting, case conversions, parsing, and more
module tern.string;

public import tern.algorithm;
import tern.traits;

public enum AnsiColor 
{
    Reset = "\x1B[0m",
    
    Black = "\x1B[30m",
    Red = "\x1B[31m",
    Green = "\x1B[32m",
    Yellow = "\x1B[33m",
    Blue = "\x1B[34m",
    Magenta = "\x1B[35m",
    Cyan = "\x1B[36m",
    White = "\x1B[37m",
    
    BoldBlack = "\x1B[30;1m",
    BoldRed = "\x1B[31;1m",
    BoldGreen = "\x1B[32;1m",
    BoldYellow = "\x1B[33;1m",
    BoldBlue = "\x1B[34;1m",
    BoldMagenta = "\x1B[35;1m",
    BoldCyan = "\x1B[36;1m",
    BoldWhite = "\x1B[37;1m",
    
    UnderlineBlack = "\x1B[30;4m",
    UnderlineRed = "\x1B[31;4m",
    UnderlineGreen = "\x1B[32;4m",
    UnderlineYellow = "\x1B[33;4m",
    UnderlineBlue = "\x1B[34;4m",
    UnderlineMagenta = "\x1B[35;4m",
    UnderlineCyan = "\x1B[36;4m",
    UnderlineWhite = "\x1B[37;4m",
    
    BackgroundBlack = "\x1B[40m",
    BackgroundRed = "\x1B[41m",
    BackgroundGreen = "\x1B[42m",
    BackgroundYellow = "\x1B[43m",
    BackgroundBlue = "\x1B[44m",
    BackgroundMagenta = "\x1B[45m",
    BackgroundCyan = "\x1B[46m",
    BackgroundWhite = "\x1B[47m",
    
    Underline = "\x1B[4m",
    Italic = "\x1B[3m",
    Reverse = "\x1B[7m"
}

public:
static:
pure:
string toUpper(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
        ret[i] = c.toUpper;
    return cast(string)ret;
}

string toLower(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
        ret[i] = c.toLower;
    return cast(string)ret;
}

char toUpper(char c)
{
    if (c.isLower)
        return cast(char)(c - ('a' - 'A'));
    else
        return c;
}

char toLower(char c)
{
    if (c.isUpper)
        return cast(char)(c + ('a' - 'A'));
    else
        return c;
}

string toCamelCase(string str)
{
    char[] ret = new char[str.length];
    ret[0] = str[0].toLower;
    foreach (i, c; str[1..$])
    {
        ret[i+1] = c;
    }
    return cast(string)ret;
}

string toPascalCase(string str)
{
    char[] ret = new char[str.length];
    ret[0] = str[0].toUpper;
    foreach (i, c; str[1..$])
    {
        ret[i+1] = c;
    }
    return cast(string)ret;
}

string toSnakeCase(string str)
{
    char[] ret;
    foreach (c; str)
    {
        if (c.isUpper)
        {
            if (ret.length > 0 && ret[$-1] != '_')
                ret ~= '_';
            ret ~= c.toLower;
        }
        else
        {
            ret ~= c;
        }
    }
    return cast(string)ret;
}

string toKebabCase(string str)
{
    char[] ret;
    foreach (c; str)
    {
        if (c.isUpper)
        {
            if (ret.length > 0 && ret[$-1] != '-')
                ret ~= '-';
            ret ~= c.toLower;
        }
        else
        {
            ret ~= c;
        }
    }
    return cast(string)ret;
}

string mangle(string str) 
{
    size_t idx = str.lastIndexOf('.');
    if (idx != -1)
        str = str[(idx + 1)..$];

    str = str.replace("*", "PTR")
        .replace("[", "OPBRK")
        .replace("]", "CLBRK")
        .replace("(", "OPPAR")
        .replace(")", "CLPAR")
        .replace(",", "COMMA")
        .replace("!", "EXCLM");

    return cast(string)str.filter!(c => isAlphaNum(c) || c == '_').range;
}

string padLeft(string str, size_t length, char padding = ' ')
{
    while (str.length < length)
        str = padding~str;
    return str;
}

string padRight(string str, size_t length, char padding = ' ')
{
    while (str.length < length)
        str = str~padding;
    return str;
}

/** 
 * Highlights `matchOf` in `matchTo` with `color`
 *
 * Params:
 *  color = The color to highlight using.
 *  matchTo = The string being highlighted.
 *  matchOf = The string to highlight.
 *
 * Returns: `matchTo` with the color and reset inserted as to highlight `matchOf`
 */
string highlight(AnsiColor color, string matchTo, string matchOf)
{
    return matchTo.replace(matchOf, color~matchOf~AnsiColor.Reset);
}

/** 
 * Highlights the string between `matchStart` and `matchEnd` in `matchTo` with `color`
 *
 * Params:
 *  color = The color to highlight using.
 *  matchTo = The string being highlighted.
 *  matchStart = The start index of the string to highlight.
 *  matchEnd = The end index of the string to highlight.
 *
 * Returns: `matchTo` with the color and reset inserted as to highlight the specified string.
 */
string highlight(AnsiColor color, string matchTo, size_t matchStart, size_t matchEnd)
{
    return matchTo[0..matchStart]~color~matchTo[matchStart..matchEnd]~AnsiColor.Reset~matchTo[matchEnd..$];
}

@nogc:
bool isAlpha(T)(T c) if (isSomeChar!T) => (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
bool isDigit(T)(T c, uint base = 10) if (isSomeChar!T) => (c >= '0' && c <= '9'- (base > 10 ? 0 : 10-base) ) || (base > 10 && c <= 'a' + base-11);
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