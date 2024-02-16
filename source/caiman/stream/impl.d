/// Stream interface and enums for stream implementations
module caiman.stream.impl;

public enum Seek
{
    Start,
    Current,
    End
}

public enum ReadKind
{
    Prefix,
    Field,
    Fixed
}

/// Stream interface used in all implementations
public interface IStream
{
public:
final:
    bool mayRead(T)();
    bool mayRead(ptrdiff_t size);

    void step(T)();
    void seek(Seek SEEK)(ptrdiff_t offset);

    T read(T)();
    T read(T)(ptrdiff_t count);
    T read(T : U[], U)();
    immutable(CHAR)[] readString(CHAR, bool PREFIXED = false)();

    T peek(T)();
    T peek(T)(ptrdiff_t count);
    T peek(T : U[], U)();
    immutable(CHAR)[] peekString(CHAR, bool PREFIXED = false)();

    void write(T)(T val);
    void write(T, bool PREFIXED = true)(T items);
    void writeString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] string);

    void put(T)();
    void put(T, bool PREFIXED = true)(T items);
    void putString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] string);
}