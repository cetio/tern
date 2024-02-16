/// Thread-safe atomic stream implementation using `IStream`
module caiman.stream.atomic_stream;

public import caiman.stream.impl;
import caiman.typecons;
import caiman.serialization;
import caiman.conv;
import caiman.traits;
import caiman.memory;

/// Thread-safe implementation of `BinaryStream`
public class AtomicStream : IStream
{
public:
final:
shared:
    Atomic!(ubyte[]) data;
    Atomic!ptrdiff_t position;
    Atomic!Endianness endianness;

    shared this(T)(T data, Endianness endianness = Endianness.Native)
    {
        if (isArray!T)
            this.data = cast(ubyte[])data;
        else
            this.data = data.serialize();
        this.endianness = endianness;
    }

    /**
     * Checks if there are enough elements left in the data array to read `T`.
     *
     * Params:
     *  T = The type to check if can be read.
     * 
     * Returns:
     *  True if there are at least `T.sizeof` bytes left to read from the current position. 
     */
    bool mayRead(T)()
    {
        return position + T.sizeof > data.length;
    }

    /**
     * Checks if there are enough elements left in the data array to read.
     * 
     * Params:
     *  size = The number of elements to try to read. Defaults to 1.
     *
     * Returns:
     *  True if there are at least size elements left to read from the current position. 
     */
    bool mayRead(ptrdiff_t size)
    {
        return position + size > data.length;
    }

    /**
     * Moves the position in the stream by the size of type T.
     *
     * Params:
     *   T = The size of type to move the position by.
     */
    void step(T)()
    {
        position += T.sizeof;
    }

    /** 
     * Moves the position in the stream forward by one until `val` is peeked.
     *
     * Params:
     *  val = The value to be peeked.
     */
    void stepUntil(T)(T val)
    {
        static if (isSomeString!T)
        {
            while (peekString!(ElementType!T) != val)
                position++;
        }
        else
        {
            while (peek!T != val)
                position++;
        }
    }

    /**
     * Seeks to a new position in the stream based on the provided offset and seek direction.
     *
     * Params:
     *  SEEK = The direction of the seek operation (Start, Current, or End).
     *  offset = The offset from the seek direction to be set.
     */
    void seek(Seek SEEK)(ptrdiff_t offset)
    {
        static if (SEEK = Seek.Current)
            position += offset;
        else static if (SEEK = Seek.Start)
            position = offset;
        else
            position = data.length - offset;
    }

    /**
     * Reads the next value from the stream of type T.
     *
     * Params:
     *   T = The type of data to be read.
     *
     * Returns:
     *  The value read from the stream.
     */
    T read(T)()
        if (!isDynamicArray!T)
    {
        if (position + T.sizeof > data.length)
            throw new Throwable("Tried to read past the end of stream!");

        return (*cast(T*)data[position..(position += T.sizeof)].ptr).makeEndian(endianness);
    }

    /**
     * Peeks at the next value from the stream of type T without advancing the stream position.
     *
     * Params:
     *  T = The type of data to peek.
     *
     * Returns:
     *  The value peeked from the stream.
     */
    T peek(T)()
        if (!isDynamicArray!T)
    {
        if (position + T.sizeof > data.length)
            throw new Throwable("Tried to read past the end of stream!");

        return (*cast(T*)data[position..(position + T.sizeof)].ptr).makeEndian(endianness);
    }

    /**
     * Reads multiple values of type T from the stream.
     *
     * Params:
     *  T = The type of data to be read.
     *  count = The number of values to read from the stream.
     *
     * Returns:
     *  An array of values read from the stream.
     */
    T[] read(T)(ptrdiff_t count)
        if (!isDynamicArray!T)
    {
        T[] arr;
        foreach (i; 0..count)
            arr ~= read!T;
        return arr;
    }

    /**
     * Peeks at multiple values of type T from the stream without advancing the stream position.
     *
     * Params:
     *  T = The type of data to peek.
     *  count = The number of values to peek from the stream.
     *
     * Returns:
     *  An array of values peeked from the stream.
     */
    T[] peek(T)(ptrdiff_t count)
        if (!isDynamicArray!T)
    {
        auto _position = position;
        scope (exit) position = _position;
        T[] arr;
        foreach (i; 0..count)
            arr ~= read!T;
        return arr;
    }

    /**
     * Reads an array of type T from the stream.
     *
     * Params:
     *  T = The type of data to be read.
     *
     * Returns:
     *  An array read from the stream.
     */
    T read(T : U[], U)()
        if (isDynamicArray!T)
    {
        return read!(ElementType!T)(cast(ptrdiff_t)read7EncodedInt());
    }

    /**
     * Peeks an array of type T from the stream without advancing the stream position.
     *
     * Params:
     *  T = The type of data to peek.
     *
     * Returns:
     *  An array peeked from the stream.
     */
    T peek(T : U[], U)()
        if (isDynamicArray!T)
    {
        return peek!(ElementType!T)(cast(ptrdiff_t)read7EncodedInt());
    }

    /**
     * Writes the provided value to the stream.
     *
     * Params:
     *   T = The type of data to be written.
     *   val = The value to be written to the stream.
     */
    void write(T)(T val)
    {        
        if (position + T.sizeof > data.length)
            throw new Throwable("Tried to write past the end of stream!");

        auto _val = val.makeEndian(endianness);
        data[position..(position += T.sizeof)] = (cast(ubyte*)&_val)[0..T.sizeof];
    }

    /**
     * Writes the provided value to the stream without advancing the stream position.
     *
     * Params:
     *   T = The type of data to be written.
     *   val = The value to be written to the stream.
     */
    void put(T)(T val)
    {
        if (position + T.sizeof > data.length)
            throw new Throwable("Tried to write past the end of stream!");

        auto _val = val.makeEndian(endianness);
        data[position..(position + T.sizeof)] = (cast(ubyte*)&_val)[0..T.sizeof];
    }

    /**
     * Writes multiple values of type T to the stream.
     *
     * Params:
     *   T = The type of data to be written.
     *   items = An array of values to be written to the stream.
     */
    void write(T, bool PREFIXED = true)(T val)
        if (isArray!T)
    {
        static if (PREFIXED)
            write7EncodedInt(cast(uint)val.length);

        foreach (u; val)
            write(u);
    }

    /**
     * Writes multiple values of type T to the stream without advancing the stream position.
     *
     * Params:
     *   T = The type of data to be written.
     *   items = An array of values to be written to the stream.
     */
    void put(T, bool PREFIXED = true)(T val)
        if (isArray!T)
    {
        auto _position = position;
        scope (exit) position = _position;
        static if (PREFIXED)
            write7EncodedInt(cast(uint)val.length);

        foreach (u; val)
            write(u);
    }

    /**
     * Reads a string from the stream considering the character width and prefixing.
     *
     * Params:
     *   CHAR = The character type used for reading the string (char, wchar, or dchar).
     *   PREFIXED = Indicates whether the string is prefixed. Default is false.
     *
     * Returns:
     *  The read string from the stream.
     */
    immutable(CHAR)[] readString(CHAR, bool PREFIXED = false)()
    {
        static if (PREFIXED)
            return cast(immutable(CHAR)[])read!(immutable(CHAR)[]);
        else
        {
            immutable(CHAR)[] ret;
            while (peek!CHAR != '\0')
                ret ~= read!CHAR;
            return ret;
        }
    }

    /**
     * Reads a string from the stream considering the character width and prefixing without advancing the stream position.
     *
     * Params:
     *   CHAR = The character type used for reading the string (char, wchar, or dchar).
     *   PREFIXED = Indicates whether the string is prefixed. Default is false.
     *
     * Returns:
     *  The read string from the stream.
     */
    immutable(CHAR)[] peekString(CHAR, bool PREFIXED = false)()
    {
        auto _position = position;
        scope (exit) position = _position;
        static if (PREFIXED)
            return cast(immutable(CHAR)[])read!(immutable(CHAR)[]);
        else
        {
            immutable(CHAR)[] ret;
            while (peek!CHAR != '\0')
                ret ~= read!CHAR;
            return ret;
        }
    }

    /**
     * Writes a string to the stream considering the character width and prefixing.
     *
     * Params:
     *   CHAR = The character type used for writing the string (char, wchar, or dchar).
     *   PREFIXED = Indicates whether the string is prefixed. Default is false.
     *   val = The string to be written to the stream.
     */
    void writeString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] val)
    {
        static if (!PREFIXED)
            val ~= '\0';

        write!(immutable(CHAR)[], PREFIXED)(val);
    }

    /**
     * Writes a string into the stream considering the character width and prefixing without advancing the stream position.
     *
     * Params:
     *   CHAR = The character type used for writing the string (char, wchar, or dchar).
     *   PREFIXED = Indicates whether the string is prefixed. Default is false.
     *   val = The string to be put into the stream.
     */
    void putString(CHAR, bool PREFIXED = false)(immutable(CHAR)[] val)
    {
        static if (!PREFIXED)
            val ~= '\0';

        put!(immutable(CHAR)[], PREFIXED)(val);
    }

    /**
     * Reads an integer value encoded in 7 bits from the stream.
     *
     * Returns:
     *  The integer value read from the stream.
     */
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

    /**
     * Writes an integer value encoded in 7 bits to the stream.
     *
     * Params:
     *   val = The integer value to be written to the stream.
     */
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

    /**
    * Reads data from a byte stream into a structured type based on specified field names and read kinds.  
    * Designed specifically for better control reading string and array fields.
    *
    * Params:
    *   T = The type representing the structure to read into.
    *   ARGS = Variadic template parameter representing field names and read kinds.
    *
    * Returns:
    *  Returns an instance of type T with fields populated based on the specified read operations.
    */
    T read(T, ARGS...)()
    {
        T val;
        foreach (field; FieldNames!T)
        {
            alias M = TypeOf!(val, field);
            bool cread;
            static foreach (i, ARG; ARGS)
            {
                static if (i % 3 == 0)
                {
                    static assert(is(typeof(ARG) == string),
                        "Field name expected, found " ~ ARG.stringof);  
                }
                else static if (i % 3 == 1)
                {
                    static assert(is(typeof(ARG) == ReadKind),
                        "Read kind expected, found " ~ ARG.stringof);  
                }
                else
                {
                    static if (field == ARGS[i - 2] || ARGS[i - 2] == "")
                    {
                        static if (!isStaticArray!M && is(M == string))
                        {
                            cread = true;
                            static if (ARGS[i - 1] == ReadKind.Field)
                            {
                                __traits(getMember, val, field) = read!char(__traits(getMember, val, ARG)).to!string;
                            }
                            else static if  (ARGS[i - 1] == ReadKind.Fixed)
                            {
                                __traits(getMember, val, field) =  read!char(ARG).to!string;
                            }
                            else
                            {
                                __traits(getMember, val, field) = readString!(char, ARG);
                            }
                        }
                        else static if (!isStaticArray!M && is(M == wstring))
                        {
                            cread = true;
                            static if (ARGS[i - 1] == ReadKind.Field)
                            {
                                __traits(getMember, val, field) = read!wchar(__traits(getMember, val, ARG)).to!string;
                            }
                            else static if  (ARGS[i - 1] == ReadKind.Fixed)
                            {
                                __traits(getMember, val, field) =  read!wchar(ARG).to!string;
                            }
                            else
                            {
                                __traits(getMember, val, field) = readString!(wchar, ARG);
                            }
                        }
                        static if (!isStaticArray!M && is(M == dstring))
                        {
                            cread = true;
                            static if (ARGS[i - 1] == ReadKind.Field)
                            {
                                __traits(getMember, val, field) = read!dchar(__traits(getMember, val, ARG)).to!string;
                            }
                            else static if  (ARGS[i - 1] == ReadKind.Fixed)
                            {
                                __traits(getMember, val, field) =  read!dchar(ARG).to!string;
                            }
                            else
                            {
                                __traits(getMember, val, field) = readString!(dchar, ARG);
                            }
                        }
                        else static if (isDynamicArray!M)
                        {
                            cread = true;
                            static if (ARGS[i - 1] == ReadKind.Field)
                            {
                                __traits(getMember, val, field) = read!(ElementType!M)(__traits(getMember, val, ARG));
                            }
                            else static if  (ARGS[i - 1] == ReadKind.Fixed)
                            {
                                __traits(getMember, val, field) = read!(ElementType!M)(ARG);
                            }
                            else
                            {
                                __traits(getMember, val, field) = read!M;
                            }
                        }
                    }
                }
            }
            if (!cread)
                __traits(getMember, val, field) = read!M;
        }
        return val;
    }

    /// ditto
    T[] read(T, ARGS...)(ptrdiff_t count)
    {
        T[] items;
        foreach (i; 0..count)
            items ~= read!(T, ARGS);
        return items;
    }

    /**
    * Reads a type from the stream using optional fields.
    *
    * Params:
    *   T = The type to be read from the stream.
    *   ARGS... = The arguments for optional fields.
    *
    * Returns:
    *  The read type read from the stream.
    */
    T readPlasticized(T, ARGS...)()
        if (ARGS.length % 3 == 0)
    {
        T val;
        foreach (field; FieldNames!T)
        {
            bool cread = true;
            static foreach (i, ARG; ARGS)
            {
                static if (i % 3 == 0)
                {
                    static assert(is(typeof(ARG) == string),
                        "Field name expected, found " ~ ARG.stringof);  
                }
                else static if (i % 3 == 1)
                {
                    static assert(is(typeof(ARG) == string),
                        "Conditional field name expected, found " ~ ARG.stringof);
                }
                else
                {
                    if (field == ARGS[i - 2] && __traits(getMember, val, ARGS[i - 1]) != ARG)
                        cread = false;
                }
            }
            if (cread)
                __traits(getMember, val, field) = read!(TypeOf!(val, field));
        }
        return val;
    }
}