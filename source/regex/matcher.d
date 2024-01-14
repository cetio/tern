module caiman.regex.matcher;

import std.string;
import std.conv;
import std.algorithm;
import std.stdio;
import caiman.state;
import caiman.regex.builder;

package class State
{
package:
final:
    Element[] elements;
    uint next;
    ubyte flags;
    uint index;
}

package:
static:
pragma(inline, true)
pure bool isFulfilled(Element element, State state, string text)
{
    const bool qlazy = element.modifiers.hasFlag(LAZY);
    const bool qdef = state.next != -1 && !element.modifiers.hasFlag(GREEDY) && !qlazy;
    foreach (k; 0..element.max)
    {
        if (qlazy && k >= element.min)
            return true;
        else if (qdef && k >= element.min && state.elements[state.next].isFulfilled(state, text))
            return true;

        if (state.index + 1 >= text.length)
            return k >= element.min;
        
        if (k != 0)
            state.index++;

        switch (element.token)
        {
            case CHARACTERS:
                bool match;
                foreach (c; element.str)
                {
                    if (text[state.index] == c)
                        match = true;
                }

                if (element.modifiers.hasFlag(EXCLUSIONARY) ? match : !match)
                    return k >= element.min;
                break;

            default:
                return false;
        }
    }
    return true;
}

pragma(inline, true)
pure string[][] matchInternal(Element[] elements, ubyte flags, string text, uint stopAt = -1)
{
    string[][] matches;
    int k = 0;
    int g = 1;
    
    State state = new State();
    state.elements = elements;
    state.flags = flags;

    while (state.index < text.length)
    {
        if (matches.length == 0 || matches[$-1] != null)
        {
            matches ~= null;
            matches[$-1] ~= null;
        }
        
        for (int j; j < elements.length; j++)
        {
            Element element = elements[j];
            debug element.str.writeln;
            debug state.index.writeln;
            uint ci = state.index;
            state.next = j + 1 >= elements.length ? -1 : j + 1;

            if (stopAt == matches.length || (element.token != ANCHOR_END && state.index >= text.length))
            {
                debug writeln("ship left ", state.index);
                if (matches[$-1] == null)
                    return matches[0..$-1];
                else
                    return matches;
            }

            if (element.isFulfilled(state, text))
            {
                debug "fulfilled".writeln;
                if (state.index != ci)
                    state.index--;
                
                if (element.min != 0 || element.modifiers.hasFlag(QUANTIFIED))
                    matches[k][0] ~= text[ci..++state.index];
            }
            else if (element.token == RESET)
            {
                debug "reset".writeln;
                matches[k] = null;
            }
            else if (element.modifiers.hasFlag(ALTERNATE))
            {
                debug "skipped".writeln;
                continue;
            }
            else
            {
                debug "unfulfilled".writeln;
                if (!elements[0].isFulfilled(state, text))
                    state.index++;
                
                matches[k] = null;
                j = -1;
            }
        }

        if (matches[$-1] != null)
            k++;
    }
    if (matches[$-1] == null)
        return matches[0..$-1];
    else
        return matches;
}