/// Simple math functions and expression simplifier
module caiman.math;

import std.algorithm;
import std.math;
import std.range;
import std.conv;
import std.ascii;

public:
static:
pure:
/**
 * Calculates the factorial of an integer.
 *
 * Params:
 *   n = Integer for which factorial is to be calculated.
 *
 * Returns:
 *   Factorial of the input integer.
 */
ulong factorial(int n)
{
    ulong result = 1;
    foreach (i; 2 .. n + 1)
        result *= i;
    return result;
}

/**
 * Calculates the greatest common divisor (GCD) of two integers.
 *
 * Params:
 *   a = First integer.
 *   b = Second integer.
 *
 * Returns:
 *   GCD of the two input integers.
 */
int gcd(int a, int b)
{
    while (b)
    {
        int temp = b;
        b = a % b;
        a = temp;
    }
    return abs(a);
}

/**
 * Calculates the least common multiple (LCM) of two integers.
 *
 * Params:
 *   a = First integer.
 *   b = Second integer.
 *
 * Returns:
 *   LCM of the two input integers.
 */
int lcm(int a, int b)
{
    return (a * b) / gcd(a, b);
}

/**
 * Aligns a number to another number upwards.
 *
 * Params:
 *   value = The value to be aligned.
 *   alignment = The alignment value.
 *
 * Returns:
 *   The aligned value.
 */
int falign(int value, int alignment)
{
    return value + (alignment - (value % alignment));
}

/**
 * Calculates the transpose of a matrix.
 *
 * Params:
 *   matrix = The matrix to be transposed.
 *
 * Returns:
 *   Transposed matrix.
 */
double[][] transpose(double[][] matrix)
{
    if (matrix.empty || matrix[0].empty)
        return [];

    auto rows = matrix.length;
    auto cols = matrix[0].length;

    double[][] result;
    result.length = cols;
    foreach (colIdx; 0 .. cols)
    {
        result[colIdx].length = rows;
        foreach (rowIdx; 0 .. rows)
        {
            result[colIdx][rowIdx] = matrix[rowIdx][colIdx];
        }
    }
    return result;
}

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
 *  auto result = simplifyEq("(5 + 3) * 2");
 *  assert(result == "16");
 *
 *  // Simplify a more complex expression
 *  auto expr = "3 * (4 + 2) / 3";
 *  auto simplifiedExpr = simplifyEq(expr);
 *  assert(simplifiedExpr == "6");
 *  ```
 */
string simplifyEq(string exp)
{
    static foreach (op; ["*", "^^", "/", "%", "+", "-", "<<", ">>", "<", "<=", ">", ">=", "==", "!=", "&", "|", "&&", "||"])
        exp = simplifyEq(exp, op);
    return exp;
}