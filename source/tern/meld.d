/// Type melding and arbitrary inheritance implementation
module tern.meld;

import std.array;
import std.ascii;
import std.algorithm;
import tern.traits;
import tern.serialization;
import tern.string;

/** 
 * Sets `T` as an inherited type, this can be anything, so long as it isn't an intrinsic type.  
 *
 * This is an attribute and should be used like `@inherit!T`
 *
 * Example:
 * ```d
 * struct A {int b; int x() => b; }
 *
 * interface B { string y(); }
 *
 * @inherit!A @inherit!B struct C 
 * {
 *     mixin meld;
 *
 *     string y() => "yohoho!";
 * }
 * ```
 */
public template inherit(T)
    if (hasChildren!T)
{
    alias inherit = T;
}

/** 
 * Sets up all inherits for the type that mixes this in. 
 * 
 * Must set inherited types by using `inherit(T)` beforehand.
 *
 * Example:
 *  ```d
 *  struct A {int b; int x() => b; }
 *
 *  interface B { string y(); }
 *
 *  @inherit!A @inherit!B struct C 
 *  {
 *      mixin meld;
 *
 *      string y() => "yohoho!";
 *  }
 * ```
 */
public template meld()
{
    static foreach (i, A; seqFilter!(isType, __traits(getAttributes, typeof(this))))
    {
        static assert(!hasModifiers!A, "Type with modifier cannot inherit from another type, must be a normal aggregate.");
        
        static foreach (field; FieldNames!A)
        {
            static if (hasParents!(TypeOf!(A, field)))
                mixin("import "~moduleName!(TypeOf!(A, field)));

            static if (!hasMember!(typeof(this), field) && (seqFilter!("isType!X && hasMember!(X, \""~field~"\")", __traits(getAttributes, typeof(this))).length == 0 ||
                is(seqFilter!("isType!X && hasMember!(X, \""~field~"\")", __traits(getAttributes, typeof(this)))[0] == A)))
                mixin(FieldSignature!(__traits(getMember, A, field))~';');
            else
            {
                static assert(is(TypeOf!(typeof(this), field) == TypeOf!(A, field)), "Type mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
                static assert(!isMutable!(__traits(getMember, typeof(this), field)) && isMutable!(__traits(getMember, A, field)), "Mutability mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
                static assert(isStatic!(__traits(getMember, typeof(this), field)) == isStatic!(__traits(getMember, A, field)), "Static mismatch of "~typeof(this).stringof~"."~field~" and inherited "~A.stringof~"."~field);
            }
        }

        static foreach (func; FunctionNames!A)
        {
            static if (hasParents!(ReturnType!(TypeOf!(A, func))))
                mixin("import "~moduleName!(ReturnType!(TypeOf!(A, func)))~';'); 
        }

        mixin("X as(X : "~fullyQualifiedName!A~")() const => this.conv!X;");
        mixin(functionMap!(A, i == 0));
    }
}

/* unittest
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
        mixin meld;

        string y() => "yohoho!";
    }

    C c;
    c.b = 2;
    assert(c.x() == 2);
    assert(c.y() == "yohoho!");
} */

/** 
 * Generates a mixin for implementing all possible functions of `T`
 * 
 * Remarks:
 *  - Any function that returns true for `isDImplDefined` is discarded.  
 *  - `nothrow`, `pure`, and `const` attributes are discarded.  
 *  - `opCall`, `opAssign`, `opIndex`, `opSlice`, `opCast` and `opDollar` are discarded even if `mapOperators` is true.
 */
 // TODO: typeof(this) attributes (ie: shared)
public template functionMap(T, bool mapOperators = false)
    if (hasChildren!T)
{
    enum functionMap =
    {
        string str = "import "~moduleName!T~";
            import tern.blit;";
        static foreach (func; FunctionNames!T)
        {
            static if (!isDImplDefined!(TypeOf!(T, func)))
            {
                static if (is(ReturnType!(TypeOf!(T, func)) == void))
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" {
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        orig."~FunctionCallableSignature!(TypeOf!(T, func))~";  }\n");
                else
                    str ~= (FunctionSignature!(TypeOf!(T, func)).replace("nothrow", "").replace("pure", "").replace("const", "")~" {
                        auto orig = as!("~fullyQualifiedName!T~"); 
                        scope (exit) this.blit(orig.conv!(typeof(this))); 
                        return orig."~FunctionCallableSignature!(TypeOf!(T, func))~"; }\n");
            }
        }
        static if (mapOperators)
            str ~= "public auto opOpAssign(string op, ORASS)(ORASS rhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opOpAssign!op(rhs);
                }

                public auto opBinary(string op, ORASS)(const ORASS rhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opBinary!op(rhs);
                }

                public auto opBinaryRight(string op, OLASS)(const OLASS lhs)
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opBinaryRight!op(lhs);
                }
                
                static if (is(typeof(this) == class))
                {
                    public override int opCmp(Object other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }
                }
                else
                {
                    public int opCmp(ORCMP)(const ORCMP other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }

                    public int opCmp(Object other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opCmp(other);
                    }
                }

                static if (is(typeof(this) == class))
                {
                    public override bool opEquals(Object other) 
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }
                }
                else
                {
                    public bool opEquals(OREQ)(const OREQ other)
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }

                    public bool opEquals(Object other) 
                    {
                        auto orig = as!("~fullyQualifiedName!T~");
                        scope (exit) this.blit(orig.conv!(typeof(this)));
                        return orig.opEquals(other);
                    }
                }

                public auto opIndexAssign(OTIASS)(OTIASS value, size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexAssign(value, index);
                }

                public auto opIndexOpAssign(string op, OTIASS)(OTIASS value, size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexOpAssign!op(value, index);
                }

                public auto opIndexUnary(string op)(size_t index) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opIndexUnary(index);
                }

                public auto opSliceAssign(OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign(value, start, end);
                }

                public auto opSlice(size_t DIM : 0)(size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSlice!DIM(start, end);
                }

                public auto opSliceAssign(size_t DIM : 0, OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign!DIM(value, start, end);
                }

                public auto opSliceOpAssign(string op, OTSASS)(OTSASS value, size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceAssign!op(value, start, end);
                }

                public auto opSliceUnary(string op)(size_t start, size_t end) 
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opSliceUnary!op(start, end);
                }

                public auto opUnary(string op)()
                {
                    auto orig = as!("~fullyQualifiedName!T~");
                    scope (exit) this.blit(orig.conv!(typeof(this)));
                    return orig.opUnary!op();
                }";
        return str;
    }();
}