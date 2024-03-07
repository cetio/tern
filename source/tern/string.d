/// Highlighting, case conversions, parsing, and more.
module tern.string;

public import tern.algorithm;
public import std.string : strip, stripLeft, stripRight;
import std.traits;

/// Ansi color implementation.
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
/**
 * Converts all characters in `str` to be uppercase.
 *
 * Params:
 *  str = The string to convert to uppercase.
 *
 * Return:
 *  `str` in uppercase.
 */
string toUpper(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
        ret[i] = c.toUpper;
    return cast(string)ret;
}

/**
 * Converts all characters in `str` to be lowercase.
 *
 * Params:
 *  str = The string to convert to lowercase.
 *
 * Return:
 *  `str` in lowercase.
 */
string toLower(string str)
{
    char[] ret = new char[str.length];
    foreach (i, c; str)
        ret[i] = c.toLower;
    return cast(string)ret;
}

/**
 * Converts a character to uppercase.
 *
 * Params:
 *  c = The character to convert to uppercase.
 *
 * Return:
 *  `c` in uppercase.
 */
T toUpper(T)(T c) if (isSomeChar!T)
{
    if (c.isLower)
        return cast(T)(c - ('a' - 'A'));
    else
        return c;
}

/**
 * Converts a character to lowercase
 *
 * Params:
 *  c = The character to convert to lowercase.
 *
 * Return:
 *  `c` in lowercase.
 */
T toLower(T)(T c) if (isSomeChar!T)
{
    if (c.isUpper)
        return cast(T)(c + ('a' - 'A'));
    else
        return c;
}

/**
 * Converts `str` to camel case.
 *
 * Params:
 *  str = The string to convert to camel case.
 *
 * Returns:
 *  The input string `str` converted to camel case.
 */
string toCamelCase(string str)
{
    char[] ret = new char[str.length];
    ret[0] = str[0].toLower;
    foreach (i, c; str[1..$])
        ret[i+1] = c;

    return cast(string)ret;
}

/**
 * Converts `str` to Pascal case.
 *
 * Params:
 *  str = The string to convert to Pascal case.
 *
 * Returns:
 *  The input string `str` converted to Pascal case.
 */
string toPascalCase(string str)
{
    char[] ret = new char[str.length];
    ret[0] = str[0].toUpper;
    foreach (i, c; str[1..$])
        ret[i+1] = c;

    return cast(string)ret;
}

/**
 * Converts `str` to snake case.
 *
 * Params:
 *  str = The string to convert to snake case.
 *
 * Returns:
 *  The input string `str` converted to snake case.
 */
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
            ret ~= c;
    }
    return cast(string)ret;
}

/**
 * Converts `str` to kebab case.
 *
 * Params:
 *  str = The string to convert to kebab case.
 *
 * Returns:
 *  The input string `str` converted to kebab case.
 */
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
            ret ~= c;
    }
    return cast(string)ret;
}

/**
 * Mangles `str` to remove special characters.
 *
 * Params:
 *  str = The string to mangle.
 *
 * Returns:
 *  A mangled version of the input string `str` with special characters replaced and non-alphanumeric characters removed.
 */
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

/**
 * Pads `str` to the left with `padding` character until it reaches `length`.
 *
 * Params:
 *  str = The string to pad.
 *  length = The desired length of the resulting string.
 *  padding = The character to use for padding. Defaults to space.
 *
 * Returns:
 *  The input string `str` padded to the left with `padding` character until it reaches `length`.
 */
string padLeft(string str, size_t length, char padding = ' ')
{
    while (str.length < length)
        str = padding~str;
    return str;
}

/**
 * Pads `str` to the right with `padding` character until it reaches `length`.
 *
 * Params:
 *  str = The string to pad.
 *  length = The desired length of the resulting string.
 *  padding = The character to use for padding. Defaults to space.
 *
 * Returns:
 *  The input string `str` padded to the right with `padding` character until it reaches `length`.
 */
string padRight(string str, size_t length, char padding = ' ')
{
    while (str.length < length)
        str = str~padding;
    return str;
}

/** 
 * Highlights `matchOf` in `matchTo` with `color`.
 *
 * Params:
 *  color = The color to highlight using.
 *  matchTo = The string being highlighted.
 *  matchOf = The string to highlight.
 *
 * Returns: `matchTo` with the color and reset inserted as to highlight `matchOf`.
 */
string highlight(AnsiColor color, string matchTo, string matchOf)
{
    return matchTo.replace(matchOf, color~matchOf~AnsiColor.Reset);
}

/** 
 * Highlights the string between `matchStart` and `matchEnd` in `matchTo` with `color`.
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

/**
 * Splits `str` into an array of string lines.
 * 
 * Params:
 *  str = The string.
 *
 * Returns:
 *  Array of string lines from `str`.
 */
string[] splitLines(string str)
{
    str = str.replace("\r\n", "\n");
    str = str.replace("\r", "\n");
    str = str.replace("\f", "\n");
    return str.split('\n');
}

@nogc:
/**
 * Checks if a character is alphabetic.
 *
 * Params:
 *  c = The character to check.
 *
 * Returns:
 *  `true` if the character is alphabetic.
 */
bool isAlpha(T)(T c) if (isSomeChar!T) => (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
  
/**
 * Checks if a character is a digit.
 *
 * Params:
 *  c = The character to check.
 *  base = The numeric base to consider when checking for digitness.
 *
 * Returns:
 *  `true` if the character is a digit.
 */
bool isDigit(T)(T c, uint base = 10) if (isSomeChar!T) => (c >= '0' && c <= '9'- (base > 10 ? 0 : 10-base) ) || (base > 10 && c <= 'a' + base-11);


/**
 * Checks if a character is alphanumeric.
 *
 * Params:
 *  c = The character to check.
 *  base = The numeric base to consider when checking for alphanumericity.
 *
 * Returns:
 *  `true` if the character is alphanumeric.
 */
bool isAlphaNum(T)(T c, uint base = 10) if (isSomeChar!T) => c.isAlpha || c.isDigit(base);

/**
 * Checks if a character is uppercase.
 *
 * Params:
 *  c = The character to check.
 *
 * Returns:
 *  `true` if the character is uppercase.
 */
bool isUpper(T)(T c) if (isSomeChar!T) => (c >= 'A' && c <= 'Z');

/**
 * Checks if a character is lowercase.
 *
 * Params:
 *  c = The character to check.
 *
 * Returns:
 *  `true` if the character is lowercase.
 */
bool isLower(T)(T c) if (isSomeChar!T) => (c >= 'a' && c <= 'z');

/**
 * Checks if a string contains only alphabetic characters.
 *
 * Params:
 *  str = The string to check.
 *
 * Returns:
 *  `true` if the string contains only alphabetic characters.
 */
bool isAlpha(string str)
{
    foreach (c; str)
    {
        if (!c.isAlpha)
            return false;
    }
    return true;
}

/**
 * Checks if a string contains only alphanumeric characters.
 *
 * Params:
 *  str = The string to check.
 *  base = The numeric base to consider when checking for alphanumericity.
 *
 * Returns:
 *  `true` if the string contains only alphanumeric characters.
 */
bool isAlphaNum(string str, uint base = 10)
{
    foreach (c; str)
    {
        if (!c.isAlpha && !c.isDigit(base))
            return false;
    }
    return true;
}

/**
 * Checks if a string contains only numeric characters.
 *
 * Params:
 *  str = The string to check.
 *  base = The numeric base to consider when checking for numericity.
 *
 * Returns:
 *  `true` if the string contains only numeric characters.
 */
bool isNumeric(string str, uint base = 10)
{
    foreach (c; str)
    {
        if (!c.isDigit(base))
            return false;
    }
    return true;
}

/**
 * Checks if a string contains only uppercase characters.
 *
 * Params:
 *  str = The string to check.
 *
 * Returns:
 *  `true` if the string contains only uppercase characters.
 */
bool isUpper(string str)
{
    foreach (c; str)
    {
        if (!c.isUpper)
            return false;
    }
    return true;
}

/**
 * Checks if a string contains only lowercase characters.
 *
 * Params:
 *  str = The string to check.
 *
 * Returns:
 *  `true` if the string contains only lowercase characters.
 */
bool isLower(string str)
{
    foreach (c; str)
    {
        if (!c.isLower)
            return false;
    }
    return true;
}