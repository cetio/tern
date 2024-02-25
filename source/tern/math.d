/// Simple math functions and expression simplifier
module tern.math;

// TODO: Refactor simpl
import std.conv;
import std.traits;
import tern.string;
import std.string : split;

public:
static:
pure:
/**
 * Simplifies a simple (does not contain functions) arithmetic expression.
 *
 * Params:
 *  exp = The arithmetic expression to be simplified.
 *  op = Specific operation to be simplified out of `exp`
 *
 * Returns:
 *  The simplified arithmetic expression.
 */
string simpl(string exp, string op)
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
    
    size_t findMatchingParenthesis(size_t start)
    {
        int depth = 0;
        for (size_t i = start; i < words.length; i++)
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

    for (size_t i = 0; i < words.length; i++)
    {
        if (words[i] == null)
            continue;
            
        if (words[i][0] == '(')
        {
            size_t end = findMatchingParenthesis(i);
            exp = exp.replace(words[i..end].join(' '), simpl(words[i..end].join(' ')[1..$-1]));
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

/**
 * Simplifies a simple (does not contain functions) arithmetic expression.
 *
 * Params:
 *  exp = The arithmetic expression to be simplified.
 *
 * Returns:
 *  The simplified arithmetic expression.
 *
 * Example:
 *  ```d
 *  // Simplify an arithmetic expression
 *  auto result = simpl("(5 + 3) * 2");
 *  assert(result == "16");
 *
 *  // Simplify a more complex expression
 *  auto expr = "3 * (4 + 2) / 3";
 *  auto simplifiedExpr = simpl(expr);
 *  assert(simplifiedExpr == "6");
 *  ```
 */
string simpl(string exp)
{
    static foreach (op; ["*", "^^", "/", "%", "+", "-", "<<", ">>", "<", "<=", ">", ">=", "==", "!=", "&", "|", "&&", "||"])
        exp = simpl(exp, op);
    return exp;
}