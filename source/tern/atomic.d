/// Reimplementation of `core.atomic` with better data support as well as Queue and CircularBuffer
module tern.atomic;

import core.atomic;
import core.sync.mutex;
import std.traits;
import tern.typecons;

public:
static:
shared Mutex mutex;

shared static this()
{
    mutex = new shared Mutex();
}

/// Inserts a load/store memory fence, ensuring that all loads and stores before this call happen before any loads and stores after.
pragma(inline)
void fence()
{
    atomicFence();
}

/// Atomically loads the value of `rhs`
pragma(inline)
auto atomicLoad(R)(ref shared R rhs)
{
    static if (isScalarType!R)
        return core.atomic.atomicLoad!(MemoryOrder.seq)(rhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return rhs;
    }
}

/// Atomically loads an array element in the value of `rhs`
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM];
}

/// Atomically loads a field element in the value of `rhs`
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM);
}

unittest
{
    shared int val = 10;
    assert(val.atomicLoad == 10);
}

/// Atomically stores `lhs` in `rhs`
pragma(inline)
void atomicStore(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        core.atomic.atomicStore!(MemoryOrder.seq)(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        rhs = lhs;
    }
}

/// Atomically stores the array element `lhs` in an array element of `rhs`
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM] = lhs;
}

/// Atomically stores the field element `lhs` in a field element of `rhs`
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM~" = lhs");
}

unittest
{
    shared int val = 10;
    val.atomicStore(7);
    assert(val.atomicLoad == 7);
}

/// Atomically exchanges `rhs` and `lhs`
pragma(inline)
void atomicExchange(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        core.atomic.atomicExchange!(MemoryOrder.seq)(&rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        R t = lhs;
        lhs = rhs; 
        rhs = t;
    }
}

unittest
{
    shared int val = 10;
    shared int val2 = 1;
    val.atomicExchange(val2);
    assert(val.atomicLoad == 1);
}

/// Performs an atomic operation `op` on `rhs` and `lhs`
pragma(inline)
auto atomicOp(string op, R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        return core.atomic.atomicOp!op(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return mixin("rhs "~op~" lhs");
    }
}

unittest
{
    shared int val = 10;
    assert(val.atomicOp!"+"(1) == 11);
}

/// Thread-safe queue implementation with range capabilities
public struct Queue(T)
{
private:
final:
    shared Atomic!(T[]) queue;

public:
    void enqueue(T val) shared
    {
        queue ~= val;
    }

    T dequeue() shared
    {
        scope (exit) queue = queue[1..$];
        return queue[0];
    }

    size_t length() shared
    {
        return queue.length;
    }

    bool empty() shared
    {
        return queue.length == 0;
    }

    T front() shared
    {
        return queue.value[0];
    }

    T back() shared
    {
        return queue.value[$-1];
    }

    void popFront()
    {
        queue = queue[1..$];
    }

    void popBack()
    {
        queue = queue[0..$-1];
    }
}

/// Thread-safe circular buffer implementation that acts like a stream
public class CircularBuffer(T)
{
private:
final:
    T[] array;
    Atomic!size_t head;

public:
    this(size_t length)
    {
        array = new T[length];
    }
    
    void write(T val)
    {
        if (head >= array.length)
            head = 0;

        array[head++] = val;
    }

    void put(T val)
    {
        if (head >= array.length)
            head = 0;

        array[head] = val;
    }

    T read()
    {
        if (head >= array.length)
            head = 0;
            
        return array[head++];
    }

    T peek()
    {
        if (head >= array.length)
            head = 0;

        return array[head];
    }
}