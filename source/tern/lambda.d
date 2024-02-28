/// High-level range lambda support for algorithms/functional programming
module tern.lambda;

// TODO: Use Blittable?
import tern.traits;
import tern.typecons;
import std.string;
import std.conv;
import std.functional;
import std.meta;

public:
/**
 * Dynamically memoizes and tries to barter a range based lambda.
 *
 * Params:
 *  F = The lambda being fulfilled.
 *  index = The current index in the range, by ref.
 *  elem = The current element in the range, by ref.
 * 
 * Remarks:
 *  - This will barter any kind of lambda, but throws if there are more than 3 arguments.
 *  - Has no explicit parameter checking, just tries to match a call.
 *  - Will allow for fulfilling normal functions, but has no optimizations and is simply for ease of use.
 */
auto barter(alias F, A)(ref size_t index, auto ref A elem)
    if (isCallable!F)
{
    static if (numArgs!F == 3)
    {
        static if (isDynamicLambda!F)
        {
            alias R = DLambdaImpl!(F, size_t, A);
            static assert(!is(ReturnType!R == void), "Cannot have a folding lambda with a void return type!");
            static Blittable!(ReturnType!R) prev;
        }
        else
        {
            static assert(!is(ReturnType!F == void), "Cannot have a folding lambda with a void return type!");
            static Blittable!(ReturnType!F) prev;
        }
    }

    static if (isDynamicLambda!F)
    {
        /* alias K = DLambdaImpl!(F, size_t, A);
        static if (!is(ReturnType!K == void))
            alias G = memoize!K;
        else
            alias G = K; */

        static if (numArgs!F == 0)
            return F!()();
        else static if (numArgs!F == 1)
            return DLambdaImpl!(F, size_t, A)(index);
        else static if (numArgs!F == 2)
            return DLambdaImpl!(F, size_t, A)(index, elem);
        else static if (numArgs!F == 3)
        {
            auto ret = DLambdaImpl!(F, size_t, A)(index, elem, prev);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter dynamic lambda with argument count "~numArgs!F.to!string);
    }
    else
    {
        static if (Parameters!F.length == 0)
            return F();
        else static if (Parameters!F.length == 1)
            return F(index);
        else static if (Parameters!F.length == 2)
            return F(index, elem);
        else static if (Parameters!F.length == 3)
        {
            auto ret = F(index, elem, prev);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter lambda with argument count "~numArgs!F.to!string);
    }
}

/// ditto
auto barter(alias F, A)(auto ref A elem)
    if (isCallable!F)
{
    static if (numArgs!F == 2)
    {
        static if (isDynamicLambda!F)
        {
            alias R = DLambdaImpl!(F, A);
            static assert(!is(ReturnType!R == void), "Cannot have a folding lambda with a void return type!");
            static Blittable!(ReturnType!R) prev;
        }
        else
        {
            static assert(!is(ReturnType!F == void), "Cannot have a folding lambda with a void return type!");
            static Blittable!(ReturnType!F) prev;
        }
    }
        
    static if (isDynamicLambda!F)
    {
        static if (numArgs!F == 0)
            return F!()();
        else static if (numArgs!F == 1)
            return DLambdaImpl!(F, A)(elem);
        else static if (numArgs!F == 2)
        {
            auto ret = DLambdaImpl!(F, A)(elem, prev);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter dynamic lambda with argument count "~numArgs!F.to!string);
    }
    else
    {
        static if (Parameters!F.length == 0)
            return F();
        else static if (Parameters!F.length == 1)
            return F(elem);
        else static if (Parameters!F.length == 2)
        {
            auto ret = F(elem, prev.value);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter lambda with argument count "~numArgs!F.to!string);
    }
}


pure:
private:
/// Tries to create a string mixin for automatically instantiating dynamic lambda `F`
private template DLambdaImpl(alias F, ARGS...)
    if (isDynamicLambda!F)
{
    string args()
    {
        string setup()
        {
            string ret;
            string p = F.stringof[(F.stringof.lastIndexOf('(') + 1)..$];
            string[] ps = p.split(", ");
            foreach (i, _p; ps)
            {
                if (_p.replace("const ", "").replace("ref ", "").replace("shared ", "")
                    .replace("immutable ", "").replace("auto ", "").replace("scope ", "").split(' ').length > 2)
                    continue;

                ret ~= i < ARGS.length ? "ARGS["~i.to!string~"], " : "ARGS[$-1], ";
            }
            return ret[0..(ret.length >= 2 ? $-2 : $)];
        }

        alias D = mixin("F!("~setup~')');
        return setup.replace("ARGS[$-1]", fullyQualifiedName!(ReturnType!D));
    }

    alias DLambdaImpl = mixin("F!("~args~')');
}

/// Retrieves the total number of arguments that a dynamic lambda is expecting.
size_t numArgs(alias F)()
    if (isCallable!F)
{
    /* string t = F.stringof[(F.stringof.indexOf('(') + 1)..(F.stringof.indexOf(')'))];
    string p = F.stringof[(F.stringof.lastIndexOf('(') + 1)..(F.stringof.lastIndexOf(')'))];
    string[] ts = t.split(", ");
    string[] ps = p.split(", ");
    foreach (i, ref _p; ps)
        _p = ts[i]~" "~_p;
    p = ps.join(", ")[0..$-2];
    return '('~t~")("~p~')'; */
    static if (!isDynamicLambda!F)
        return Parameters!F.length;
    else
    {
        string p = F.stringof[(F.stringof.lastIndexOf('(') + 1)..(F.stringof.lastIndexOf(')'))];
        return p.split(", ").length;
    }
}