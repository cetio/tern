module caiman.regex.builder;

import std.string;
import std.conv;
import std.ascii;
import std.algorithm;
import caiman.state;
// TODO: Use caiman.error

// Tokens
package enum : ubyte
{
    BAD,
    /// `(?...)`
    /// Matches group ahead
    LOOK_AHEAD,
    /// `(...<...)`
    /// Matches group behind
    LOOK_BEHIND,
    /// `[...]`
    /// Stores a set of characters (matches any)
    CHARACTERS,
    /// `^`
    /// Matches only if at the start of a line or the full text
    ANCHOR_START,
    /// `$`
    /// Matches only if at the end of a line or the full text
    ANCHOR_END,
    /// `(...)`
    /// Stores a set of elements
    GROUP,
    /// `.`
    /// Matches any character
    ANY,
    /// ~`\gn`~ or `$n` (group) or `%n` (absolute)
    /// Refers to a group or element
    REFERENCE,
    // Not used! Comments don't need to be parsed!
    // (?#...)
    //COMMENT
    /// `\K` `\Kn`
    /// Resets match or group match
    RESET,
    /// `n->` or `|->`
    /// Moves the current text position forward
    PUSHFW,
    /// `<-n` or `<-|`
    /// Moves the current text position backward
    PUSHBW
}

// Element modifiers
package enum : ubyte
{
    /// No special rules, matches until the next element can match
    NONE = 0,
    /// `|`
    /// If fails, the next element will attempt to match instead
    ALTERNATE = 1,
    /// `[^...]`
    /// Matches only if no characters in the set match
    EXCLUSIONARY = 2,
    /// `{...}`
    /// Has min/max
    QUANTIFIED = 4,
    // *
    //GREEDY = 8,
    // +
    //MANY = 16,
    // ?
    //OPTIONAL = 32,
    // Now defaults to POSITIVE/CAPTURE if set to NONE
    // (...=...)
    // Also (...) (capture group)
    //CAPTURE = 64,
    //POSITIVE = 64,
    /// `(?:...)`
    /// Acts as a group but does not capture match
    NONCAPTURE = 8,
    /// `(...!...)`
    /// Matches if not matched
    NEGATIVE = 16,
    /// `...?`
    /// Matches as few times as possible
    LAZY = 32,
    /// `...+`
    /// Matches as many times as possible
    GREEDY = 64
}

// Regex flags
package enum : ubyte
{
    /// Match more than once
    GLOBAL = 2,
    /// ^ & $ match start & end
    MULTILINE = 4,
    /// Case insensitive
    INSENSITIVE = 8,
    /// Ignore whitespace
    EXTENDED = 16,
    /// . matches  r\n\f
    SINGLELINE = 32
}

package struct Element
{
public:
final:
align(8):
    /// What kind of element is this?
    /// eg: `CHARACTERS`
    ubyte token;
    /// What are the special modifiers of this element?
    /// eg: `EXCLUSIONARY`
    ubyte modifiers;
    /// Characters mapped (like in a character set or literal)
    /// Elements mapped (like in a group or reference)
    union
    {
        string str;
        Element[] elements;
    }
    /// Minimum times to require fulfillment
    /// eg: `1`
    uint min;
    /// Maximum times to allow fulfillment
    /// eg: `1`
    uint max = 1;

    pure string tokenName()
    {
        switch (token)
        {
            case BAD: return "BAD";
            case LOOK_AHEAD: return "LOOK_AHEAD";
            case LOOK_BEHIND: return "LOOK_BEHIND";
            case CHARACTERS: return "CHARACTERS";
            case ANCHOR_START: return "ANCHOR_START";
            case ANCHOR_END: return "ANCHOR_END";
            case GROUP: return "GROUP";
            case ANY: return "ANY";
            case REFERENCE: return "REFERENCE";
            case RESET: return "RESET";
            case PUSHFW: return "PUSHFW";
            case PUSHBW: return "PUSHBW";
            default: assert(0);
        }
    }

    pure string modifiersName()
    {
        string ret;
        switch (modifiers)
        {
            case NONE: ret = "NONE"; break;
            case ALTERNATE: (ret != null) ? ret ~= " | ALTERNATE" : ret ~= "ALTERNATE"; break;
            case EXCLUSIONARY: (ret != null) ? ret ~= " | EXCLUSIONARY" : ret ~= "EXCLUSIONARY"; break;
            case QUANTIFIED: (ret != null) ? ret ~= " | QUANTIFIED" : ret ~= "QUANTIFIED"; break;
            case NONCAPTURE: (ret != null) ? ret ~= " | NONCAPTURE" : ret ~= "NONCAPTURE"; break;
            case NEGATIVE: (ret != null) ? ret ~= " | NEGATIVE" : ret ~= "NEGATIVE"; break;
            case LAZY: (ret != null) ? ret ~= " | LAZY" : ret ~= "LAZY"; break;
            case GREEDY: (ret != null) ? ret ~= " | GREEDY" : ret ~= "GREEDY"; break;
            default: assert(0);
        }
        return ret;
    }
}

package:
static:
pragma(inline, true)
pure @nogc bool modifierQuantifiable(Element element)
{
    return !element.modifiers.hasFlag(QUANTIFIED);
}

pragma(inline, true)
pure @nogc bool tokenQuantifiable(Element element)
{
    return element.token != ANCHOR_START && 
        element.token != ANCHOR_END && 
        element.token != PUSHFW && 
        element.token != PUSHBW && 
        element.token != RESET;
}

pragma(inline, true)
pure @nogc string getArgument(string pattern, int start, char opener, char closer)
{
    int openers = 1;
    foreach (i; (start + 1)..pattern.length)
    {
        if (pattern[i] == opener)
            openers++;
        else if (pattern[i] == closer)
            openers--;
        
        if (openers == 0)
            return pattern[(start + 1)..i];
    }
    return pattern[(start + 1)..pattern.length];
}

pragma(inline, true)
pure string expand(string str, ref string[string] lookups)
{
    if (str in lookups)
        return lookups[str];

    string ret;
    int i = 0;
    while (i < str.length)
    {
        if (str[i] == '\\' && i + 1 < str.length && str[i..(i + 2)] in lookups)
        {
            ret ~= lookups[str[i..(i += 2)]];
        }
        else if (i + 2 < str.length && str[i + 1] == '-')
        {
            char start = str[i];
            char end = str[i + 2];
            foreach (c; start..(end + 1))
                ret ~= c;
            i += 3;
        }
        else
        {
            ret ~= str[i++];
        }
    }
    lookups[str] = ret;
    return ret;
}

pure string highlightError(string str, uint index)
{
    string highlightColor = "\x1B[31;4m";
    string resetColor = "\x1B[0m";

    return "                      "~str[0..index]~highlightColor~str[index..index + 1]~resetColor~str[index + 1..$];
}

// TODO: Refer to future group/element
//        b  B (?:..) (..) lookahead lookbehind
pragma(inline, true)
pure Element[] build(string pattern, string[string] lookups)
{
    Element[] elements;
    for (int i; i < pattern.length; i++)
    {
        Element element;
        char c = pattern[i];
        switch (c)
        {
            case '+':
                if (!elements[$-1].tokenQuantifiable)
                    throw new Throwable(elements[$-1].tokenName()~" cannot be succeeded by quantifier token '+' (non-quantifiable!)\n"~highlightError(pattern, i));

                if (elements[$-1].modifierQuantifiable)
                {
                    elements[$-1].min = 1;
                    elements[$-1].max = uint.max;
                    elements[$-1].modifiers |= QUANTIFIED;
                }
                else
                {
                    elements[$-1].modifiers |= GREEDY;
                }
                break;

            case '*':
                if (!elements[$-1].tokenQuantifiable)
                    throw new Throwable(elements[$-1].tokenName()~" cannot be succeeded by quantifier token '*' (non-quantifiable!)\n"~highlightError(pattern, i));

                if (!elements[$-1].modifierQuantifiable)
                    throw new Throwable(elements[$-1].modifiersName()~" cannot be succeeded by quantifier token '*' (non-quantifiable!)\n"~highlightError(pattern, i));

                elements[$-1].min = 0;
                elements[$-1].max = uint.max;
                elements[$-1].modifiers |= QUANTIFIED;
                break;

            case '?':
                if (!elements[$-1].tokenQuantifiable)
                    throw new Throwable(elements[$-1].tokenName()~" cannot be succeeded by quantifier token '?' (non-quantifiable!)\n"~highlightError(pattern, i));

                if (elements[$-1].modifierQuantifiable)
                {
                    elements[$-1].min = 0;
                    elements[$-1].max = 1;
                    elements[$-1].modifiers |= QUANTIFIED;
                }
                else 
                {
                    elements[$-1].modifiers |= LAZY;
                }
                break;

            case '{':
                if (!elements[$-1].tokenQuantifiable)
                    throw new Throwable(elements[$-1].tokenName()~" cannot be succeeded by quantifier token '{' (non-quantifiable!)\n"~highlightError(pattern, i));

                if (!elements[$-1].modifierQuantifiable)
                    throw new Throwable(elements[$-1].modifiersName()~" cannot be succeeded by quantifier token '{' (non-quantifiable!)\n"~highlightError(pattern, i));

                string arg = pattern.getArgument(i, '{', '}');
                string[] args = arg.split("..");

                if (args.length == 1)
                {
                    elements[$-1].min = args[0].to!uint;
                    elements[$-1].max = args[0].to!uint;
                }
                else if (args.length == 2)
                {
                    elements[$-1].min = args[0].to!uint;
                    elements[$-1].max = args[1].to!uint;
                }
                else
                {
                    throw new Throwable("Quantifier range ('{') expected 1-2 arguments (found "~args.length.to!string~"!)\n"~highlightError(pattern, i));
                }

                i += arg.length + 1;
                elements[$-1].modifiers |= QUANTIFIED;
                break;

            case '|':
                if (i + 2 < pattern.length && pattern[i..(i + 3)] == "|->")
                {
                    element.token = PUSHFW;
                    element.min = 1;
                    i += 2;
                    break;
                }
                elements[$-1].modifiers |= ALTERNATE;
                break;

            case '.':
                element.token = ANY;
                element.min = 1;
                element.max = 1;
                break;

            case '[':
                if (i + 1 < pattern.length && pattern[i + 1] == '^')
                {
                    element.modifiers |= EXCLUSIONARY;
                    i++;
                }

                element.token = CHARACTERS;
                element.str = pattern.getArgument(i, '[', ']').expand(lookups);
                element.min = 1;
                element.max = 1;

                i += pattern.getArgument(i, '[', ']').length + 1;
                break;

            case '^':
                element.token = ANCHOR_START;
                break;

            case '%':
                if (i + 1 < pattern.length && pattern[i + 1].isDigit)
                {
                    uint id = 0;
                    while (i + 1 < pattern.length && pattern[i + 1].isDigit)
                        id = id * 10 + (pattern[++i] - '0');

                    if (id < elements.length)
                    {
                        element.token = REFERENCE;
                        element.elements = [ elements[id] ];
                    }
                    else
                    {
                        throw new Throwable("REFERENCE ('%n') refers to element "~id.to!string~", which is outside of valid range!\n"~highlightError(pattern, i));
                    }
                    break;
                }
                break;

            case '$':
                if (i + 1 < pattern.length && pattern[i + 1].isDigit)
                {
                    uint id = 0;
                    while (i + 1 < pattern.length && pattern[i + 1].isDigit)
                        id = id * 10 + (pattern[++i] - '0');

                    for (uint ii = 0, visits = 0; ii < elements.length; ++ii)
                    {
                        if (elements[ii].token == GROUP && visits++ == id)
                        {
                            element.token = REFERENCE;
                            element.elements = [ elements[ii] ];
                            break;
                        }
                    }
                    if (element.token != REFERENCE)
                        throw new Throwable("REFERENCE ('$n') refers to group "~id.to!string~", which is outside of valid range!\n"~highlightError(pattern, i));
                }
                element.token = ANCHOR_END;
                break;

            case '<':
                if (i + 2 < pattern.length && pattern[i + 1] == '-' && pattern[i + 2] == '|')
                {
                    element.token = PUSHBW;
                    element.min = 1;
                    i += 2;
                    break;
                }
                else if (i + 2 < pattern.length && pattern[i + 1] == '-' && pattern[i + 2].isDigit)
                {
                    i++;
                    uint len = 0;
                    while (i + 1 < pattern.length && pattern[i + 1].isDigit)
                        len = len * 10 + (pattern[++i] - '0');

                    element.token = PUSHBW;
                    element.min = len;
                    break;
                }
                else
                {
                    throw new Throwable("Expected syntax <-n or <-| for PUSHBW! "~highlightError(pattern, i));
                }
                break;

            case '(':
                string arg = pattern.getArgument(i, '(', ')');
                element.token = GROUP;
                element.elements = arg.build(lookups);
                i += arg.length + 1;
                break;

            default:
                if (c.isDigit)
                {
                    uint ci = i;
                    uint len = c - '0';
                    while (i + 1 < pattern.length && pattern[i + 1].isDigit)
                        len = len * 10 + (pattern[++i] - '0');
                    
                    if (i + 2 < pattern.length && pattern[(i + 1)..(i + 3)] == "->")
                    {
                        element.token = PUSHFW;
                        element.min = len;
                        i += 2;
                        break;
                    }
                    i = ci;
                }

                element.token = CHARACTERS;
                // Will not be adding support for  gn
                // Expected to use $n
                if (c == '\\' && i + 1 < pattern.length)
                {
                    // Reset (local)
                    if (pattern[i..(i + 2)] == r"\K")
                    {
                        i++;
                        element.token = RESET;
                        if (i + 1 < pattern.length && pattern[i + 1].isDigit)
                        {
                            uint id = 0;
                            while (i + 1 < pattern.length && pattern[i + 1].isDigit)
                                id = id * 10 + (pattern[++i] - '0');

                            for (uint ii = 0, visits = 0; ii < elements.length; ++ii)
                            {
                                if (elements[ii].token == GROUP && visits++ == id)
                                {
                                    element.elements = [ elements[ii] ];
                                    break;
                                }
                            }
                            if (element.elements.length == 0)
                                throw new Throwable(r"RESET ('\K') refers to group "~id.to!string~", which is outside of valid range!\n"~highlightError(pattern, i));
                        }
                        break;
                    }
                    // Escaped escape
                    else if (pattern[i..(i + 2)] == r"\\")
                    {
                        element.str = c.to!string;
                        element.min = 1;
                        element.max = 1;
                        i++;
                        break;
                    }
                    else if (pattern[i..(i + 2)] == r"\x" && i + 3 < pattern.length)
                    {
                        string hex = pattern[i + 2 .. i + 4];
                        element.str = (cast(char)hex.to!ubyte(16)).to!string;
                        element.min = 1;
                        element.max = 1;
                        i += 3;
                        break;
                    }
                    // Any escape
                    else
                    {
                        string arg = pattern[i..(++i + 1)];
                        switch (arg)
                        {
                            case r"\W", r"\D", r"\S", r"\H", r"\V":
                                element.str = arg.toLower.expand(lookups);
                                element.min = 1;
                                element.max = 1;
                                element.modifiers |= EXCLUSIONARY;
                                break;

                            default:
                                element.str = arg.expand(lookups);
                                element.min = 1;
                                element.max = 1;
                        }
                    }
                }
                else
                {
                    element.str = c.to!string;
                    element.min = 1;
                    element.max = 1;
                }
                break;
        }
        if (element.token != BAD)
            elements ~= element;
    }
    return elements;
}