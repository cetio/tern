module caiman.formats.pe.dotnet.headers;

import caiman.formats.pe.optional;

public struct Cor20Header
{
public:
final:
    uint size;
    ushort majorRuntimeVersion;
    ushort minorRuntimeVersion;
    DataDirectory metadata;
    uint flags;
    uint entryPointToken;
    DataDirectory resources;
    DataDirectory strongNameSignature;
    DataDirectory codeManagerTable;
    DataDirectory vtableFixups;
    DataDirectory exportAddressTableJumps;
    DataDirectory managedNativeHeader;
}

public struct Metadata
{
public:
final:
    char[4] signature;
    ushort majorVersion;
    ushort minorVersion;
    uint reserved;
    uint versionStringLength;
    char[] versionString;
    bool extraData;
    ubyte padding;
    ushort streams;
}

