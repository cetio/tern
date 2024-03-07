/// General-purpose yet powerful functional programming oriented functions.
module tern.functional;

// TODO: Plane currently uses normal indexing, it should use Range(T)
// TODO: tap
public import std.functional: curry, compose, pipe, memoize, not, partial, reverseArgs, unaryFun, binaryFun, bind;
import tern.traits;
import tern.object : loadLength;
import std.conv;
import std.meta;
import std.typecons;
import std.parallelism;
import std.range : iota;
import std.array;
import std.string;

/// Tries to automagically instantiate `F` by argument.
package template Instantiate(alias F, ARGS...)
    if (isDynamicLambda!F)
{
    string args()
    {
        string setup()
        {
            string ret;
            string p = F.stringof[(F.stringof.lastIndexOf("(") + 1)..$];
            string[] ps = p.split(", ");
            foreach (i, _p; ps)
            {
                if (_p.replace("const ", "").replace("ref ", "").replace("shared ", "")
                    .replace("immutable ", "").replace("auto ", "").replace("scope ", "").split(" ").length > 1)
                    continue;

                ret ~= i < ARGS.length ? "ARGS["~i.to!string~"], " : "ARGS[$-1], ";
            }
            return ret[0..(ret.length >= 2 ? $-2 : $)];
        }

        alias D = mixin("F!("~setup~")");
        return setup.replace("ARGS[$-1]", fullIdentifier!(Unconst!(ReturnType!D)));
    }

    alias Instantiate = mixin("F!("~args~")");
}

public:
/**
 * Denatures `F` on `args` to create a void function with no arguments.
 *
 * This is particularly useful when (unsafely) invoking a function from another thread.
 *
 * Params:
 *  F = The function to denature.
 *  args = The arguments to denature `F` to.
 *
 * Returns:
 *  A `void function()` which invokes `F` on `args`.
 *
 * Remarks:
 *  Supports renaturing arguments by reference, which may be especially unsafe.
 */
auto denature(alias F, ARGS...)(auto ref ARGS args) @nogc
    if (__traits(compiles, { F(args); }))
{
    string makeFun()
    {
        string ret = "() { F(";
        static foreach (i, ARG; ARGS)
            ret ~= "*cast(ARGS["~i.to!string~"]*)a"~i.to!string~", ";
        return ret[0..(ARGS.length == 0 ? $ : $-2)]~"); }";
        // TODO: blit back
    }

    static foreach (i, ARG; ARGS)
    {
        mixin("static shared(ARGS["~i.to!string~"])* a"~i.to!string~";
        a"~i.to!string~" = cast(shared(ARGS["~i.to!string~"])*)&args["~i.to!string~"];");
    }
    void function() f = mixin(makeFun);
    return f;
}

/**
 * Renatures `F` to `SIG` on `args` to create a new arbitrary signature.
 *
 * Params:
 *  F = The function to renature.
 *  SIG = The new signature of `F` after renaturing.
 *  args = The arguments to renature `F` to.
 *
 * Returns:
 *  A `SIG` function which invokes `F` on `args`.
 */
public template renature(alias F, SIG...)
    if (SIG.length >= 1)
{
    auto renature(ARGS...)(auto ref ARGS args) @nogc
        if (__traits(compiles, { F(args); }))
    {
        string makeParams()
        {
            string ret = "(";
            static foreach (i, ARG; SIG[1..$])
                ret ~= fullIdentifier!ARG~", ";
            return ret[0..(SIG.length == 1 ? $ : $-2)]~")";
        }

        string makeFun()
        {
            string ret = makeParams~" { F(";
            static foreach (i, ARG; ARGS)
                ret ~= "cast(ARGS["~i.to!string~"]a"~i.to!string~", ";
            return ret[0..(ARGS.length == 0 ? $ : $-2)]~"); return SIG[0].init; }";
            // TODO: blit back
        }

        static foreach (i, ARG; ARGS)
        {
            mixin("static shared ARGS["~i.to!string~"] a"~i.to!string~";
            a"~i.to!string~" = cast(shared(ARGS["~i.to!string~"]))args["~i.to!string~"];");
        }
        mixin("SIG[0] function"~makeParams~" f = mixin(makeFun);");
        return f;
    }
}

/* auto shrinkWrap(alias F, ARGS...)(auto ref ARGS args)
    if (__traits(compiles, { F(args); }))
{
    alias RETURN = typeof(F(args));
    string makeFun()
    {
        static if (is(RETURN == void))
            string ret = "() { F(";
        else
            string ret = "() { return F(";
        static foreach (i, ARG; ARGS)
            ret ~= "*a"~i.to!string~", ";
        return ret[0..$-2]~"); }";
    }

    static foreach (i, ARG; ARGS)
    {
        mixin("static ARGS["~i.to!string~"]* a"~i.to!string~";
        a"~i.to!string~" = &args["~i.to!string~"];");
    }
    RETURN function() f = mixin(makeFun);
    return f;
} */

/**
 * Asynchronously calls every function in `FUNCS` using the given arguments, and returns all of the values in a tuple.
 *
 * Params:
 *  F = The function to be called.
 *  args = The arguments to call `F` on.
 *
 * Returns:
 *  A tuple of all returned values from every function in `FUNCS`.
 *
 * Remarks:
 *  Race conditions are very likely, make sure that the functions are thread safe.
 */
public template juxt(FUNCS...)
{
    /**
     * Asynchronously calls every function in `FUNCS` using the given arguments, and returns all of the values in a tuple.
     *
     * Params:
     *  F = The function to be called.
     *  args = The arguments to call `F` on.
     *
     * Returns:
     *  A tuple of all returned values from every function in `FUNCS`.
     *
     * Remarks:
     *  Race conditions are very likely, make sure that the functions are thread safe.
     */
    auto juxt(ARGS...)(auto ref ARGS args)
    {
        string makeTup()
        {
            string ret;
            static foreach (F; FUNCS)
            {{
                alias RETURN = typeof(F(args));
                ret ~= is(RETURN == void) ? "bool, " : fullIdentifier!RETURN~", ";
            }}
            return "Tuple!("~ret[0..$-2]~")";
        }

        string makeCase()
        {
            string ret;
            static foreach (j, F; FUNCS)
            {
                static if (is(typeof(F(args)) == void))
                {
                    ret ~= "case "~j.to!string~":
                    FUNCS["~j.to!string~"](args);
                    ret["~j.to!string~"] = true;
                    break;";
                }
                else
                {
                    ret ~= "case "~j.to!string~":
                    ret["~j.to!string~"] = FUNCS["~j.to!string~"](args);
                    break;";
                }
            }
            return ret;
        }
        
        mixin(makeTup) ret;
        foreach (i; parallel(iota(0, FUNCS.length)))
        {
            switch (i)
            {
                mixin(makeCase);
                default: assert(0);
            }
        }
        return ret;
    }
}

/**
 * Dynamically tries to barter a range based lambda.
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
auto barter(alias F, A, B)(auto ref A index, auto ref B elem)
    if (isCallable!F)
{
    static if (Arity!F == 3)
    {
        static if (isDynamicLambda!F)
        {
            alias R = Instantiate!(F, A, B);
            static assert(!is(Parameters!R[$-1] == void), "Cannot have a folding lambda with a void return type!");
            static Parameters!R[$-1] prev;
        }
        else
        {
            static assert(!is(Parameters!R[$-1] == void), "Cannot have a folding lambda with a void return type!");
            static Parameters!R[$-1] prev;
        }
    }

    static if (isDynamicLambda!F)
    {
        /* alias K = Instantiate!(F, A, B);
        static if (!is(ReturnType!K == void))
            alias G = memoize!K;
        else
            alias G = K; */

        static if (Arity!F == 0)
            return F!()();
        else static if (Arity!F == 1)
            return Instantiate!(F, A, B)(index);
        else static if (Arity!F == 2)
            return Instantiate!(F, A, B)(index, elem);
        else static if (Arity!F == 3)
        {
            auto ret = Instantiate!(F, A, B)(index, elem, prev);
            static if (!is(typeof(ret) == bool))
                scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter dynamic lambda with argument count "~Arity!F.to!string);
    }
    else
    {
        static if (Arity!F == 0)
            return F();
        else static if (Arity!F == 1)
            return F(index);
        else static if (Arity!F == 2)
            return F(index, elem);
        else static if (Arity!F == 3)
        {
            auto ret = F(index, elem, prev);
            static if (!is(typeof(ret) == bool))
                scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter lambda with argument count "~Arity!F.to!string);
    }
}

/// ditto
auto barter(alias F, A)(auto ref A elem)
    if (isCallable!F)
{
    static if (Arity!F == 2)
    {
        static if (isDynamicLambda!F)
        {
            alias R = Instantiate!(F, A);
            static assert(!is(ReturnType!R == void), "Cannot have a folding lambda with a void return type!");
            static Parameters!R[$-1] prev;
        }
        else
        {
            static assert(!is(ReturnType!F == void), "Cannot have a folding lambda with a void return type!");
            static Parameters!R[$-1] prev;
        }
    }
        
    static if (isDynamicLambda!F)
    {
        static if (Arity!F == 0)
            return F!()();
        else static if (Arity!F == 1)
            return Instantiate!(F, A)(elem);
        else static if (Arity!F == 2)
        {
            auto ret = Instantiate!(F, A)(elem, prev);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter dynamic lambda with argument count "~Arity!F.to!string);
    }
    else
    {
        static if (Arity!F == 0)
            return F();
        else static if (Arity!F == 1)
            return F(elem);
        else static if (Arity!F == 2)
        {
            auto ret = F(elem, prev.value);
            scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter lambda with argument count "~Arity!F.to!string);
    }
}

/// ditto
auto barter(alias F, A, B, _ = void)(A index, B elem)
    if (isCallable!F)
{
    static if (Arity!F == 3)
    {
        static if (isDynamicLambda!F)
        {
            alias R = Instantiate!(F, A, B);
            static assert(!is(ReturnType!R == void), "Cannot have a folding lambda with a void return type!");
            static Unqual!(Parameters!R[$-1]) prev;
        }
        else
        {
            static assert(!is(ReturnType!F == void), "Cannot have a folding lambda with a void return type!");
            static Unqual!(Parameters!R[$-1]) prev;
        }
    }
        
    static if (isDynamicLambda!F)
    {
        static if (Arity!F == 0)
            return F!()();
        else static if (Arity!F == 1)
            return Instantiate!(F, A, B)(index);
        else static if (Arity!F == 2)
            return Instantiate!(F, A, B)(index, elem);
        else static if (Arity!F == 3)
        {
            auto ret = Instantiate!(F, A, B)(index, elem, prev);
            static if (!is(typeof(ret) == bool))
                scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter dynamic lambda with argument count "~Arity!F.to!string);
    }
    else
    {
        static if (Arity!F == 0)
            return F();
        else static if (Arity!F == 1)
            return F(index);
        else static if (Arity!F == 2)
            return F(index, elem);
        else static if (Arity!F == 3)
        {
            auto ret = F(index, elem, prev);
            static if (!is(typeof(ret) == bool))
                scope (exit) prev = ret;
            return ret;
        }
        else
            static assert(0, "Unable to barter lambda with argument count "~Arity!F.to!string);
    }
}

/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto plane(alias C, A, B)(auto ref A range, scope B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {
        if (range[i] != elem)
        {
            if (++i >= range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto plane(alias C, A, B)(auto ref A range, scope B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {   
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (++i + subrange.loadLength > range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            ret = barter!C(i, slice);
            if (++i + subrange.loadLength > range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, slice);
            if (++i + subrange.loadLength > range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range`, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto plane(alias C, alias F, T)(auto ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!T, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i;
    while (true)
    {
        if (!barter!F(i, range[i]))
        {
            if (++i >= range.loadLength)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            ret = barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (++i >= range.loadLength)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  elem = The element to match for.
 */
auto planeReverse(alias C, A, B)(auto ref A range, scope B elem)
    if (isCallable!C && isIndexable!A && isElement!(A, B))
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength - 1;
    while (true)
    {  
        if (range[i] != elem)
        {
            if (--i < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (--i < 0)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (--i < 0)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  range = The range being iterated over.
 *  subrange = The subrange to match for.
 */
auto planeReverse(alias C, A, B)(auto ref A range, scope B subrange)
    if (isCallable!C && isIndexable!A && isIndexable!B && !isElement!(A, B))
{
    if (subrange.loadLength > range.loadLength)
        return;

    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!A, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength - subrange.loadLength;
    while (true)
    {
        auto slice = range[i..(i + subrange.loadLength)];
        if (slice != subrange)
        {
            if (--i - subrange.loadLength < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }
            
        static if (RETURN)
        {
            auto ret = barter!C(i, slice);
            if (--i - subrange.loadLength < 0)
                return ret;
        }
        else
        {
            barter!C(i, slice);
            if (--i - subrange.loadLength < 0)
                return;
        }
    }
}

/**
 * Iterates over every element in `range` in reverse, looking for matches.
 * 
 * Calls `C` using bartering (see `tern.lambda`) when a match is made.
 *
 * Params:
 *  C = Callback function.
 *  F = The predicate to match for.
 *  range = The range being iterated over.
 */
auto planeReverse(alias C, alias F, T)(auto ref T range)
    if (isCallable!C && isIndexable!T && isCallable!F)
{
    alias TYPE = ReturnType!(barter!(C, size_t, ElementType!T, void));
    enum RETURN = !is(TYPE == void);
    static if (RETURN)
        TYPE ret;
    size_t i = range.loadLength;
    while (true)
    {
        if (!barter!F(i, range[i]))
        {
            if (--i < 0)
            {
                static if (RETURN)
                    return ret;
                else
                    return;
            }
            continue;
        }

        static if (RETURN)
        {
            auto ret = barter!C(i, range[i]);
            if (--i < 0)
                return ret;
        }
        else
        {
            barter!C(i, range[i]);
            if (--i < 0)
                return;
        }
    }
}