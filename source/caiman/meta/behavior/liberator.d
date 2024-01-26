/**
 * WHAT THE FUCK IS INHERITANCE
                                                               __..-'
                                                         _.--''
                                               _...__..-'
                                             .'
                                           .'
                                         .'
                                       .'
            .------._                 ;
      .-"""`-.<')    `-._           .'
     (.--. _   `._       `'---.__.-'
      `   `;'-.-'         '-    ._
        .--'``  '._      - '   .
         `""'-.    `---'    ,
 ''--..__      `\
         ``''---'`\      .'
              jgs  `'. '
                     `'.
 */
module caiman.meta.behavior.liberator;

import caiman.meta.traits;
import caiman.meta.algorithm;
import std.traits;

/** 
 * Sets `T` as an inherited type, this can be anything, so long as it isn't an intrinsic type. \
 * This is an attribute and should be used like `@inherit!T`
 *
 *  Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *    mixin liberty;
 *
 *    string y() => "yohoho!";
 *  }
 *  ```
 */
public template inherit(T)
    if (!isIntrinsicType!T)
{
    alias inherit = T;
}

/* private template coalesced(T)
    if (!isIntrinsicType!T)
{
    T dummy;
}

public template coalesce(T)
    if (!isIntrinsicType!T)
{
    alias coalesce = coalesced!T;
} */

/** 
 * Sets up all inherits for the type that mixes this in. \
 * Must set inherited types by using `inherit(T)` beforehand.
 *
 *  Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *    mixin liberty;
 *
 *    string y() => "yohoho!";
 *  }
 *  ```
 */
// TODO: Use opDispatch to allow for multiple class/struct inherits
//       Find a faster way to do this, do not regenerate every call
//       Apply changes on parent to self
public template liberty(bool ignoreConflicts = false)
{
    static foreach (i, A; seqFilter!("isType!X && !isIntrinsicType!X", __traits(getAttributes, typeof(this))))
    {
        static foreach (field; FieldNames!A)
        {
            static if (hasParents!(typeof(__traits(getMember, A, field))))
                mixin("import "~moduleName!(typeof(__traits(getMember, A, field)))~";");

            static if (!seqContains!(field, FieldNames!(typeof(this))))
                mixin(fullyQualifiedName!(typeof(__traits(getMember, A, field)))~" "~field~";");
            else static if (!ignoreConflicts)
                static assert(is(typeof(__traits(getMember, typeof(this), field)) == typeof(__traits(getMember, A, field))), 
                    "Expected type of '"~typeof(__traits(getMember, A, field)).stringof~"' for inherited field '"~field~"' but got '"~typeof(__traits(getMember, typeof(this), field)).stringof~"'");
        }

        static foreach (func; FunctionNames!A)
        {
            static if (hasParents!(ReturnType!(__traits(getMember, A, func))))
                mixin("import "~moduleName!(ReturnType!(__traits(getMember, A, func)))~";");
        }

        static if (is(A == interface))
        {
            static foreach (func; FunctionNames!A)
            {
                static assert(seqContains!(func, FunctionNames!(typeof(this))) &&
                    is(ReturnType!(__traits(getMember, typeof(this), func)) == ReturnType!(__traits(getMember, A, func))) &&
                    is(Parameters!(__traits(getMember, typeof(this), func)) == Parameters!(__traits(getMember, A, func))) &&
                    functionAttributes!(__traits(getMember, typeof(this), func)) == functionAttributes!(__traits(getMember, A, func)) &&
                    functionLinkage!(__traits(getMember, typeof(this), func)) == functionLinkage!(__traits(getMember, A, func)), 
                    typeof(this).stringof~" does not implement function '"~func~"' from "~A.stringof);
            }
        }
        else
        {   
            mixin("private "~A.stringof~" asParent"~A.stringof.pragmatize()~"() {
            static if (is(T == class) || is(T == interface))
                "~A.stringof~" val = new "~A.stringof~"();
            else 
                "~A.stringof~" val;
            static if (hasChildren!("~A.stringof~"))
            import caiman.meta.traits;
            static foreach (field; FieldNames!("~A.stringof~"))
                __traits(getMember, val, field) = mixin(field);
            return val; }");

            static if (i == 0)
                mixin("alias asParent"~A.stringof.pragmatize()~" this;");
            else
            {
                /* mixin("import caiman.meta.algorithm;
                import caiman.meta.traits;
                auto opDispatch(string name, ARGS...)(ARGS args) 
                    if (seqContains!(name, FunctionNames!("~A.stringof~"))) {
                        mixin(\"return asParent"~A.stringof.pragmatize()~".\"~name~\"(\"~args.stringof~\");\");
                }"); */
            }
        }
    }

    /* static foreach (C; seqFilter!("X.stringof.length > 9 && X.stringof[0..9] == \"coalesced\"", __traits(getAttributes, typeof(this))))
    {
        static foreach (field; FieldNames!(typeof(__traits(getMember, C, "dummy"))))
        {
            static if (hasParents!(typeof(__traits(getMember, (typeof(__traits(getMember, C, "dummy"))), field))))
                mixin("import "~moduleName!(typeof(__traits(getMember, (typeof(__traits(getMember, C, "dummy"))), field)))~";");

            static if (!seqContains!(field, FieldNames!(typeof(this))))
                mixin(fullyQualifiedName!(typeof(__traits(getMember, (typeof(__traits(getMember, C, "dummy"))), field)))~" "~field~";");
            else static if (!ignoreConflicts)
                static assert(is(typeof(__traits(getMember, typeof(this), field)) == typeof(__traits(getMember, (typeof(__traits(getMember, C, "dummy"))), field))), 
                    "Expected type of '"~typeof(__traits(getMember, (typeof(__traits(getMember, C, "dummy"))), field)).stringof~"' for coalesced field '"~field~"' but got '"~typeof(__traits(getMember, typeof(this), field)).stringof~"'");
        }
    } */
}

unittest
{
    struct A
    {
        int b;

        int x() => b;
    }

    interface B
    {
        string y();
    }

    @inherit!A @inherit!B struct C
    {
        mixin liberty;

        string y() => "yohoho!";
    }

    C c;
    c.b = 2;
    assert(c.x() == 2);
    assert(c.y() == "yohoho!");
}