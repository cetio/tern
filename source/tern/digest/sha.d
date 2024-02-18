module tern.digest.sha;

import tern.digest;

public static @digester class SHA1
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA1)(data);
    }
}

public static @digester class SHA256
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA256)(data);
    }
}

public static @digester class SHA512
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA512)(data);
    }
}

public static @digester class SHA224
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA224)(data);
    }
}   

public static @digester class SHA384
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA384)(data);
    }
}   