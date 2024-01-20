module caiman.logging;

import std.string;
import std.algorithm;
import std.stdio;
import std.datetime;

private const string padding = "                      "; // object.Throwable@(0): 

public enum AnsiColor 
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


pure string highlight(AnsiColor color, string matchTo, string matchOf)
{
    if (!matchTo.canFind(matchOf)) 
        throw new Throwable("Matching substring not found in the input string");
        
    return matchTo.replace(matchOf, color~matchOf~AnsiColor.Reset);
}

pure string highlight(AnsiColor color, string matchTo, ptrdiff_t matchStart, ptrdiff_t matchEnd)
{
    if (!matchStart >= 0 && matchEnd >= matchStart && matchEnd <= matchTo.length)
        throw new Throwable("Invalid matchStart or matchEnd values");
    
    return matchTo[0..matchStart]~color~matchTo[matchStart..matchEnd]~AnsiColor.Reset~matchTo[matchEnd..$];
}

pure void raise(string exception, string matchTo = null, string matchOf = null)
{
    if (matchTo == null)
        throw new Throwable(exception);

    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchOf));
}

pure void raise(string exception, string matchTo, ptrdiff_t matchStart, ptrdiff_t matchEnd)
{
    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchStart, matchEnd));
}

void logError(string message)
{
    writeln(format("[%Y-%m-%d %H:%M:%S]", Clock.currTime())~" "~AnsiColor.Red~"[!] "~AnsiColor.Reset~message);
}

void logBad(string message)
{
    writeln(format("[%Y-%m-%d %H:%M:%S]", Clock.currTime())~" "~AnsiColor.Yellow~"[<] "~AnsiColor.Reset~message);
}

void logOk(string message)
{
    writeln(format("[%Y-%m-%d %H:%M:%S]", Clock.currTime())~" "~AnsiColor.Green~"[>] "~AnsiColor.Reset~message);
}

void logInfo(string message)
{
    writeln(format("[%Y-%m-%d %H:%M:%S]", Clock.currTime())~" "~AnsiColor.Blue~"[i] "~AnsiColor.Reset~message);
}