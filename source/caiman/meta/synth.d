/// Comptime and runtime function synthesizer and equation utilities
module caiman.meta.synth;

import std.array;
import std.ascii;
import std.algorithm;
import std.conv;

public:
static:
pure:
string simplifyEq(string exp, string op)
{
    immutable uint[string] priority = [
        "*": 0,
        "^^": 1,
        "/": 2,
        "%": 3,
        "+": 4,
        "-": 5,
        "<<": 6,
        ">>": 7,
        "<": 8,
        "<=": 9,
        ">": 10,
        ">=": 11,
        "==": 12,
        "!=": 13,
        "&": 14,
        "|": 15,
        "&&": 16,
        "||": 17
    ];

    string[] words = exp.split(' ');
    if (words.length < 3)
        return exp;
    
    ptrdiff_t findMatchingParenthesis(ptrdiff_t start)
    {
        int depth = 0;
        for (ptrdiff_t i = start; i < words.length; i++)
        {
            if (words[i][0] == '(')
                depth++;
            else if (words[i][$-1] == ')')
            {
                depth--;
                if (depth == 0)
                    return i + 1;
            }
        }
        return words.length;
    }

    for (ptrdiff_t i = 0; i < words.length; i++)
    {
        if (words[i] == null)
            continue;
            
        if (words[i][0] == '(')
        {
            ptrdiff_t end = findMatchingParenthesis(i);
            exp = exp.replace(words[i..end].join(' '), simplifyEq(words[i..end].join(' ')[1..$-1]));
            i = end - 1;
        }
    }

    words = exp.split(' ');
    if (words.length < 3)
        return exp;

    foreach (i, word; words)
    {
        if (i >= words.length - 1)
            return words.join(' ');
        
        if (i > 1 && words[i - 2] in priority && priority[words[i - 2]] < priority[op])
            continue;

        if (word == op)
        {
            if (words[i - 1].startsWith('~') && words[i - 1].filter!(x => x.isDigit).array.length == words[i - 1].length - 1)
                words[i - 1] = (~words[i - 1][1..$].to!ulong).to!string;

            if (words[i + 1].startsWith('~') && words[i + 1].filter!(x => x.isDigit).array.length == words[i + 1].length - 1)
                words[i + 1] = (~words[i + 1][1..$].to!ulong).to!string;

            bool lhsNumeric = words[i - 1].filter!(x => x.isDigit).array.length == words[i - 1].length;
            bool rhsNumeric = words[i + 1].filter!(x => x.isDigit).array.length == words[i + 1].length;

            if (!lhsNumeric || !rhsNumeric)
                continue;

            switch (op)
            {
                case "*":
                    words[i - 1] = (words[i - 1].to!ulong * words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "^^":
                    words[i - 1] = (words[i - 1].to!ulong ^^ words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "/":
                    words[i - 1] = (words[i - 1].to!ulong / words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "%":
                    words[i - 1] = (words[i - 1].to!ulong % words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "+":
                    words[i - 1] = (words[i - 1].to!ulong + words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "-":
                    words[i - 1] = (words[i - 1].to!ulong - words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "<<":
                    words[i - 1] = (words[i - 1].to!ulong << words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case ">>":
                    words[i - 1] = (words[i - 1].to!ulong >> words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "<":
                    words[i - 1] = (words[i - 1].to!ulong < words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "<=":
                    words[i - 1] = (words[i - 1].to!ulong <= words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case ">":
                    words[i - 1] = (words[i - 1].to!ulong > words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case ">=":
                    words[i - 1] = (words[i - 1].to!ulong >= words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "==":
                    words[i - 1] = (words[i - 1].to!ulong == words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "!=":
                    words[i - 1] = (words[i - 1].to!ulong != words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "^":
                    words[i - 1] = (words[i - 1].to!ulong ^ words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "&":
                    words[i - 1] = (words[i - 1].to!ulong & words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "|":
                    words[i - 1] = (words[i - 1].to!ulong | words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "&&":
                    words[i - 1] = (words[i - 1].to!ulong && words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                case "||":
                    words[i - 1] = (words[i - 1].to!ulong || words[i + 1].to!ulong).to!string;
                    words = words[0..i]~words[(i + 2)..$];
                    break;
                default:
                    assert(0);
            }
        }
    }
    return words.join(' ');
}

string simplifyEq(string exp)
{
    static foreach (op; ["*", "^^", "/", "%", "+", "-", "<<", ">>", "<", "<=", ">", ">=", "==", "!=", "&", "|", "&&", "||"])
        exp = simplifyEq(exp, op);
    return exp;
}