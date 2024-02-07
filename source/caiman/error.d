/// Utilities for throwing informational errors/exceptions/throwables
module caiman.error;

import std.algorithm;
import std.array;

private const string padding = "                      "; // object.Throwable@(0): 
private enum AnsiColor 
{
    Reset = "\x1B[0m",
    
    // Regular colors
    Black = "\x1B[30m",
    Red = "\x1B[31m",
    Green = "\x1B[32m",
    Yellow = "\x1B[33m",
    Blue = "\x1B[34m",
    Magenta = "\x1B[35m",
    Cyan = "\x1B[36m",
    White = "\x1B[37m",
    
    // Bold colors
    BoldBlack = "\x1B[30;1m",
    BoldRed = "\x1B[31;1m",
    BoldGreen = "\x1B[32;1m",
    BoldYellow = "\x1B[33;1m",
    BoldBlue = "\x1B[34;1m",
    BoldMagenta = "\x1B[35;1m",
    BoldCyan = "\x1B[36;1m",
    BoldWhite = "\x1B[37;1m",
    
    // Underline colors
    UnderlineBlack = "\x1B[30;4m",
    UnderlineRed = "\x1B[31;4m",
    UnderlineGreen = "\x1B[32;4m",
    UnderlineYellow = "\x1B[33;4m",
    UnderlineBlue = "\x1B[34;4m",
    UnderlineMagenta = "\x1B[35;4m",
    UnderlineCyan = "\x1B[36;4m",
    UnderlineWhite = "\x1B[37;4m",
    
    // Background colors
    BackgroundBlack = "\x1B[40m",
    BackgroundRed = "\x1B[41m",
    BackgroundGreen = "\x1B[42m",
    BackgroundYellow = "\x1B[43m",
    BackgroundBlue = "\x1B[44m",
    BackgroundMagenta = "\x1B[45m",
    BackgroundCyan = "\x1B[46m",
    BackgroundWhite = "\x1B[47m",
    
    // Additional styles
    Underline = "\x1B[4m",
    Italic = "\x1B[3m",
    Reverse = "\x1B[7m"
}

public:
static:
pure:
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
string highlight(AnsiColor color, string matchTo, ptrdiff_t matchStart, ptrdiff_t matchEnd)
{
    return matchTo[0..matchStart]~color~matchTo[matchStart..matchEnd]~AnsiColor.Reset~matchTo[matchEnd..$];
}

/** 
 * Raises an exception using optional highlighting.
 *
 * Params:
 *  exception = The exception to be raised.
 *  matchTo = String to use for syntax/error highlighting.
 *  matchOf = String to use to search for and highlight in `matchTo`
 */
void raise(string exception, string matchTo = null, string matchOf = null)
{
    if (matchTo == null)
        throw new Throwable(exception);

    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchOf));
}

unittest
{
    try
    {
        raise("Test exception", "This is a test string", "test");
    }
    catch (Throwable e)
    {
        assert(e.msg == "Test exception\n                      This is a \x1B[31;4mtest\x1B[0m string");
    }
}

/** 
 * Raises an exception using optional highlighting.
 *
 * Params:
 *  exception = The exception to be raised.
 *  matchTo = String to use for syntax/error highlighting.
 *  matchStart = Start index of the string to use to search for and highlight in `matchTo`
 *  matchEnd = End index of the string to use to search for and highlight in `matchTo`
 */
void raise(string exception, string matchTo, ptrdiff_t matchStart, ptrdiff_t matchEnd)
{
    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchStart, matchEnd));
}

unittest
{
    try
    {
        raise("Test exception", "This is a test string", 10, 14);
    }
    catch (Throwable e)
    {
        assert(e.msg == "Test exception\n                      This is a \x1B[31;4mtest\x1B[0m string");
    }
}
