module caiman.stream.impl;

public interface IStream
{
    bool mayRead(T)();
    bool mayRead(ptrdiff_t count);

    void seekRead(T)();
    void seekPeek(T)();
    void seek();

    T read(T)();
    T read(T)(ptrdiff_t count);
    T read(T : U[], U)();
    T readString(CHAR, bool PREFIXED = false)();

    T peek(T)();
    T peek(T)(ptrdiff_t count);
    T peek(T : U[], U)();
    T peekString(CHAR, bool PREFIXED = false)();

    void write(T)(T val);
    void write(T : U[], U, bool PREFIXED = true)(T items);
    void writeString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] string);

    void put(T)();
    void put(T : U[], U, bool PREFIXED = true)(T items);
    void putString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] string);
}