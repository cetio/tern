/* module caiman.stream.file_stream;

import std.stdio;
import caiman.typecons;
import caiman.stream.impl;
import caiman.object;
import caiman.conv;
import caiman.traits;
import caiman.mira;
import caiman.memory;

public enum Mode
{
    Read,
    Write,
    ReadWrite,
    Append,
    ReadAppend,
}

public class FileStream : IStream
{
protected:
final:
    File file;

public:
    Endianness endianness;

    this(string path, Mode mode = Mode.ReadWrite, Endianness endianness = Endianness.Native)
    {
        if (mode == Mode.Read)
            this.file = File(path, "r");
        else if (mode == Mode.Write)
            this.file = File(path, "w");
        else if (mode == Mode.ReadWrite)
            this.file = File(path, "r+");
        else if (mode == Mode.Append)
            this.file = File(path, "a");
        else if (mode == Mode.ReadAppend)
            this.file = File(path, "a+");
        this.endianness = endianness;
    }

    this(File file, Endianness endianness = Endianness.Native)
    {
        this.file = file;
        this.endianness = endianness;
    }

    @property ptrdiff_t position()
    {
        return file.tell();
    }

    @property ptrdiff_t position(ptrdiff_t val)
    {
        file.seek(val, SEEK_SET);
        return file.tell();
    }

    ptrdiff_t size()
    {
        return file.size();
    }

    bool mayRead(T)()
    {
        return position + T.sizeof < size;
    }

    bool mayRead(ptrdiff_t size)
    {
        return position + size < this.size;
    }

    void step(T)()
    {
        file.seek(T.sizeof, SEEK_CUR);
    }

    void seek(Seek SEEK)(ptrdiff_t offset)
    {
        if (SEEK == Seek.Current)
            file.seek(offset, SEEK_CUR);
        else if (SEEK == Seek.Start)
            file.seek(offset, SEEK_SET);
        else
            file.seek(offset, SEEK_END);
    }

    ubyte[] readAllBytes()
    {
        ubyte[] buff = new ubyte[size];
        file.rawRead(buff);
        return buff;
    }

    ubyte[] readAllText(CHAR = char)()
    {
        return cast(immutable(CHAR)[])readAllBytes;
    }

    T read(T)()
    {
        ubyte[T.sizeof] buff;
        file.rawRead(buff);
        return buff.deserialize!T;
    }

    T[] read(T)(ptrdiff_t count)
    {
        T[] items;
        foreach (i; 0..count)
            items ~= read!T;
        return items;
    }

    T read(T)()
        if (isDynamicArray!T)
    {
        return read!T(read7EncodedInt());
    }

    T peek(T)()
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        ubyte[T.sizeof] buff;
        file.rawRead(buff);
        return buff.deserialize!T;
    }

    T[] peek(T)(ptrdiff_t count)
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        T[] items;
        foreach (i; 0..count)
            items ~= read!T;
        return items;
    }

    T read(T)()
        if (isDynamicArray!T)
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        return read!T(read7EncodedInt());
    }

    void write(T)(T val)
        if (!isArray!T)
    {
        file.rawWrite(val.serialize());
    }

    void write(T, bool PREFIXED = true)(T val)
        if (isArray!T)
    {
        static if (PREFIXED)
            write7EncodedInt(cast(uint)val.length);

        file.rawWrite(val.serialize()[8..$]);
    }

    void put(T)(T val)
        if (!isArray!T)
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        file.rawWrite(val.serialize());
    }

    void put(T, bool PREFIXED = true)(T val)
        if (isArray!T)
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        static if (PREFIXED)
            write7EncodedInt(cast(uint)val.length);

        file.rawWrite(val.serialize()[8..$]);
    }

    immutable(CHAR)[] readString(CHAR, bool PREFIXED = false)()
    {
        static if (PREFIXED)
            return cast(immutable(CHAR)[])read!(immutable(CHAR)[]);
        else
        {
            immutable(CHAR)[] ret;
            while (peek!CHAR != '\0' && position < size)
                ret ~= read!CHAR;
            return ret;
        }
    }

    immutable(CHAR)[] peekString(CHAR, bool PREFIXED = false)()
    {
        ptrdiff_t position = file.tell();
        scope(exit) file.seek(position);
        static if (PREFIXED)
            return cast(immutable(CHAR)[])read!(immutable(CHAR)[]);
        else
        {
            immutable(CHAR)[] ret;
            while (peek!CHAR != '\0' && position < size)
                ret ~= read!CHAR;
            return ret;
        }
    }

    void writeString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] val)
    {
        write!(immutable(CHAR)[], PREFIXED)(val);
    }

    void putString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] val)
    {
        put!(immutable(CHAR)[], PREFIXED)(val);
    }

    uint read7EncodedInt()
    {
        uint result = 0;
        uint shift = 0;

        foreach (i; 0..5)
        {
            ubyte b = read!ubyte;
            result |= cast(uint)(b & 0x7F) << shift;
            if ((b & 0x80) == 0)
                return result;
            shift += 7;
        }
        
        return result;
    }

    void write7EncodedInt(uint val)
    {
        foreach (i; 0..5)
        {
            byte b = cast(byte)(val & 0x7F);
            val >>= 7;
            if (val != 0)
                b |= 0x80;
            write(b);
            if (val == 0)
                return;
        }
    }

    void encrypt(ptrdiff_t size)
    {
        if (!mayRead(size))
            encrypt(size - 1);

        ubyte[] buff = peek!ubyte(size);
        Mira.encrypt(buff, "9G7o6mcmxMFfAv0jOedyx1JWnGqRNk0g");
        write!(ubyte[], false)(buff);
    }

    void decrypt(ptrdiff_t size)
    {
        if (!mayRead(size))
            decrypt(size - 1);

        ubyte[] buff = peek!ubyte(size);
        Mira.decrypt(buff, "9G7o6mcmxMFfAv0jOedyx1JWnGqRNk0g");
        write!(ubyte[], false)(buff);
    }
} */