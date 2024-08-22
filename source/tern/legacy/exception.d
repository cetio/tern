/// Simple parser oriented throwable raising with highlighting.
module tern.legacy.exception;

import tern.string;

private enum padding = "                      "; // object.Throwable@(0): 

public:
static:
pure:
/** 
 * Raises an exception using optional highlighting.
 *
 * Params:
 *  exception = The exception to be raised.
 *  matchTo = String to use for syntax/error highlighting.
 *  matchOf = String to use to search for and highlight in `matchTo`.
 */
void raise(string exception, string matchTo = null, string matchOf = null)
{
    if (matchTo == null)
        throw new Throwable(exception);
        
    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchOf));
}

/** 
 * Raises an exception using optional highlighting.
 *
 * Params:
 *  exception = The exception to be raised.
 *  matchTo = String to use for syntax/error highlighting.
 *  matchStart = Start index of the string to use to search for and highlight in `matchTo`.
 *  matchEnd = End index of the string to use to search for and highlight in `matchTo`.
 */
void raise(string exception, string matchTo, size_t matchStart, size_t matchEnd)
{
    throw new Throwable(exception~"\n"~padding~highlight(AnsiColor.UnderlineRed, matchTo, matchStart, matchEnd));
}