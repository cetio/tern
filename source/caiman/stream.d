/// Advanced data stream support, with optional reading, file access, endianness support, and much more.
// TODO: Refactor
//       AOB/pattern scan
module caiman.stream;

import std.file;
import std.conv;
import std.algorithm.mutation;
import caiman.traits;
import std.traits;

public enum Endianness
{
    Native,
    LittleEndian,
    BigEndian
}

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

/**
* Swaps the endianness of the provided value, if applicable.
*
* Params:
*     val = The value to swap endianness.
*
* Returns:
*   The value with swapped endianness.
*/
private static @nogc T makeEndian(T)(T val, Endianness endianness)
{
    version (LittleEndian)
    {
        if (endianness == Endianness.BigEndian)
        {
            ubyte[] bytes = (cast(ubyte*)&val)[0..T.sizeof];
            bytes = bytes.reverse();
            val = *cast(T*)&bytes[0];
        }
    }
    else version (BigEndian)
    {
        if (endianness == Endianness.LittleEndian)
        {
            ubyte[] bytes = (cast(ubyte*)&val)[0..T.sizeof];
            bytes = bytes.reverse();
            val = *cast(T*)&bytes[0];
        }
    }

    return val;
}

public class Stream
{
protected:
final:
    string filePath;

public:
    ubyte[] data;
    ptrdiff_t position;
    Endianness endianness;

    this(ubyte[] data, Endianness endianness = Endianness.Native)
    {
        this.data = data.dup;
        this.endianness = endianness;
    }

    this(byte[] data, Endianness endianness = Endianness.Native)
    {
        this.data = cast(ubyte[])data.dup;
        this.endianness = endianness;
    }

    this(string filePath, Endianness endianness = Endianness.Native)
    {
        this.data = cast(ubyte[])std.file.read(filePath);
        this.endianness = endianness;
        this.filePath = filePath;
    }

    /**
        Checks if there are enough elements left in the data array to read.
        
        Params:
           size = The number of elements to try to read. Defaults to 1.
        
        Returns:
            True if there are at least size elements left to read from the current position. 
     */
    @nogc bool mayRead()(int size = 1)
    {
        return position + size - 1 < data.length;
    }

    /**
        Checks if there are enough elements left in the data array to read `T`.
        
        Params:
           T = The type to check if can be read.
        
        Returns:
            True if there are at least `T.sizeof` bytes left to read from the current position. 
     */
    @nogc bool mayRead(T)()
    {
        return position + T.sizeof - 1 < data.length;
    }

    /**
     * Moves the position in the stream by the size of type T.
     *
     * Params:
     *   T = The size of type to move the position by.
     */
    @nogc void step(T)()
    {
        position += T.sizeof;
    }

    /**
     * Moves the position in the stream by the size of type T * elements.
     *
     * Params:
     *   T = The size of type to move the position by.
     *   count = The number of elements.
     */
    @nogc void step(T)(int count)
    {
        position += T.sizeof * count;
    }

    /** 
     * Moves the position in the stream forward by one until `val` is peeked.
     */
    @nogc void stepUntil(T)(T val)
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
     * Does not work like a conventional seek, and will read type T from the stream, using that as the seek offset.
     *
     * Params:
     *   T = The offset value for seeking.
     *   SEEK = The direction of the seek operation (Start, Current, or End).
     */
    @nogc void seek(T, Seek SEEK)()
        if (isIntegral!T)
    {
        static if (SEEK == Seek.Start)
        {
            position = peek!T;
        }
        else static if (SEEK == Seek.Current)
        {
            position += peek!T;
        }
        else
        {
            position = data.length - peek!T;
        }
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
    @nogc T read(T)()
        if (!isArray!T || isStaticArray!T)
    {
        if (data.length <= position)
            return T.init;

        scope(exit) step!T;
        T val = *cast(T*)(&data[position]);
        return makeEndian!T(val, endianness);
    }

    /**
    * Peeks at the next value from the stream of type T without advancing the stream position.
    *
    * Params:
    *   T = The type of data to peek.
    *
    * Returns:
    *  The value peeked from the stream.
    */
    @nogc T peek(T)()
        if (!isArray!T)
    {
        if (data.length <= position)
            return T.init;

        T val = *cast(T*)(&data[position]);
        return makeEndian!T(val, endianness);
    }

    /**
    * Reads an array of type T from the stream.
    *
    * Params:
    *   T = The type of data to be read.
    *
    * Returns:
    *  An array read from the stream.
    */
    T read(T : U[], U)()
        if (!isStaticArray!T)
    {
        T items;
        foreach (ulong i; 0..read7EncodedInt())
            items ~= read!(U);
        return items;
    }

    /**
    * Peeks an array of type T from the stream without advancing the stream position.
    *
    * Params:
    *   T = The type of data to peek.
    *
    * Returns:
    *  An array peeked from the stream.
    */
    T peek(T : U[], U)()
        if (!isStaticArray!T)
    {
        ulong _position = position;
        scope(exit) position = _position;
        return read!T;
    }

    /**
    * Writes the provided value to the stream.
    *
    * Params:
    *   T = The type of data to be written.
    *   val = The value to be written to the stream.
    */
    @nogc void write(T)(T val)
    {
        if (data.length <= position)
            return;

        scope(exit) step!T;
        *cast(T*)(&data[position]) = makeEndian!T(val, endianness);
    }

    /**
    * Writes the provided value to the stream without advancing the stream position.
    *
    * Params:
    *   T = The type of data to be written.
    *   val = The value to be written to the stream.
    */
    @nogc void put(T)(T val)
    {
        if (data.length <= position)
            return;

        *cast(T*)(&data[position]) = makeEndian!T(val, endianness), key;
    }

    /**
    * Reads multiple values of type T from the stream.
    *
    * Params:
    *   T = The type of data to be read.
    *   count = The number of values to read from the stream.
    *
    * Returns:
    *  An array of values read from the stream.
    */
    T[] read(T)(ptrdiff_t count)
    {
        T[] items;
        foreach (i; 0..count)
            items ~= read!T;
        return items;
    }

    /**
    * Peeks at multiple values of type T from the stream without advancing the stream position.
    *
    * Params:
    *   T = The type of data to peek.
    *   count = The number of values to peek from the stream.
    *
    * Returns:
    *  An array of values peeked from the stream.
    */
    T[] peek(T)(ptrdiff_t count)
    {
        ulong _position = position;
        scope(exit) position = _position;
        return read!T(count);
    }

    /**
    * Writes multiple values of type T to the stream.
    *
    * Params:
    *   T = The type of data to be written.
    *   items = An array of values to be written to the stream.
    */
    @nogc void write(T, bool NOPREFIX = false)(T[] items)
    {
        static if (!NOPREFIX)
            write7EncodedInt(cast(int)items.length);

        foreach (ulong i; 0..items.length)
            write!T(items[i]);
            
    }

    /**
    * Writes multiple values of type T to the stream without advancing the stream position.
    *
    * Params:
    *   T = The type of data to be written.
    *   items = An array of values to be written to the stream.
    */
    @nogc void put(T, bool NOPREFIX = false)(T[] items)
    {
        ulong _position = position;
        scope(exit) position = _position;
        write!(T, NOPREFIX)(items);
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
    string readString(CHAR, bool PREFIXED = false)()
        if (is(CHAR == char) || is(CHAR == dchar) || is(CHAR == wchar))
    {
        static if (PREFIXED)
            return read!(CHAR[]).to!string;

        char[] chars;
        while (peek!CHAR != '\0')
            chars ~= read!CHAR;
        return makeEndian!string(chars.to!string, endianness);
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
    string peekString(CHAR, bool PREFIXED = false)()
        if (is(CHAR == char) || is(CHAR == dchar) || is(CHAR == wchar))
    {
        ulong _position = position;
        scope(exit) position = _position;
        return readString!(CHAR, PREFIXED);
    }

    /**
    * Writes a string to the stream considering the character width and prefixing.
    *
    * Params:
    *   CHAR = The character type used for writing the string (char, wchar, or dchar).
    *   PREFIXED = Indicates whether the string is prefixed. Default is false.
    *   str = The string to be written to the stream.
    */
    void writeString(CHAR, bool PREFIXED = false)(string str)
        if (is(CHAR == char) || is(CHAR == dchar) || is(CHAR == wchar))
    {
        if (!PREFIXED && str.length > 0 && str[$-1] != '\0')
            str ~= '\0';

        write!(CHAR, !PREFIXED)(str.dup.to!(CHAR[]));
    }

    /**
    * Writes a string into the stream considering the character width and prefixing without advancing the stream position.
    *
    * Params:
    *   CHAR = The character type used for writing the string (char, wchar, or dchar).
    *   PREFIXED = Indicates whether the string is prefixed. Default is false.
    *   str = The string to be put into the stream.
    */
    void putString(CHAR, bool PREFIXED = false)(string str)
        if (is(CHAR == char) || is(CHAR == dchar) || is(CHAR == wchar))
    {
        if (!PREFIXED && str.length > 0 && str[$-1] != '\0')
            str ~= '\0';
        
        put!(CHAR, !PREFIXED)(str.dup.to!(CHAR[]));
    }

    /**
    * Reads an integer value encoded in 7 bits from the stream.
    *
    * Returns:
    *  The integer value read from the stream.
    */
    @nogc int read7EncodedInt()
    {
        int result = 0;
        int shift = 0;

        foreach (int i; 0..5)
        {
            ubyte b = read!ubyte();
            result |= cast(int)(b & 0x7F) << shift;
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
    @nogc void write7EncodedInt(int val)
    {
        foreach (int i; 0..5)
        {
            byte b = cast(byte)(val & 0x7F);
            val >>= 7;
            if (val != 0)
                b |= 0x80;
            write!ubyte(b);
            if (val == 0)
                return;
        }
    }

    /**
    * Commits the results of multiple functions to a byte stream and returns the combined result.
    *
    * Params:
    *   T = The type representing the return value.
    *   FUNCS = Variadic template parameter representing the functions to be executed.
    *
    * Returns:
    *  Returns the combined result of executing the provided functions as a byte stream.
    */
    T commit(T, FUNCS...)()
    {
        ubyte[] bytes;
        foreach (FUNC; FUNCS)
        {
            auto ret = FUNC();
            bytes ~= (cast(ubyte*)&ret)[0..ReturnType!(FUNC).sizeof];
        }
        return *cast(T*)&bytes[0];
    }

    /// ditto
    T[] commit(T, FUNCS...)(ptrdiff_t count)
    {
        T[] items;
        foreach (i; 0..count)
            items ~= commit!(T, FUNCS);
        return items;
    }

    /**
    * Commits the results of multiple functions to the stream and writes it to the stream.
    *
    * Params:
    *   T = The type representing the return value.
    *   FUNCS = Variadic template parameter representing the functions to be executed.
    */
    void commitWrite(T, FUNCS...)()
    {
        ubyte[] bytes;
        foreach (FUNC; FUNCS)
        {
            auto ret = FUNC();
            bytes ~= (cast(ubyte*)&ret)[0..ReturnType!(FUNC).sizeof];
        }
        write!byte(bytes, true);
    }

    /**
    * Commits the results of multiple functions the stream and writes it to the stream without advancing the stream position.
    *
    * Params:
    *   T = The type representing the return value.
    *   FUNCS = Variadic template parameter representing the functions to be executed.
    */
    void commitPut(T, FUNCS...)()
    {
        ubyte[] bytes;
        foreach (FUNC; FUNCS)
        {
            auto ret = FUNC();
            bytes ~= (cast(ubyte*)&ret)[0..ReturnType!(FUNC).sizeof];
        }
        put!byte(bytes, true);
    }

    /**
    * Reads data from a byte stream into a structured type based on specified field names and read kinds. \
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

    /**
        Flushes the data stored in this stream to the given file path.

        Params:
           filePath = The file path to flush to.
    */
    void flush(string filePath)
    {
        if (filePath != null)
            std.file.write(filePath, data);
    }

    /// Flushes the data stored in this stream to the file path that this stream was initialized with.
    void flush()
    {
        if (this.filePath != null)
            std.file.write(this.filePath, data);
    }
}