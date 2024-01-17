module caiman.formats.pe.directories;

import caiman.formats.pe.optional;
import std.bitmanip;

public struct ExportTable
{
public:
final:
    uint flags;
    uint timeStamp;
    ushort majorVersion;
    ushort minorVersion;
    uint nameRVA;
    uint ordinalBase;
    uint numAddresses;
    uint numNames;
    uint addressTableRVA;
    uint namePointerRVA;
    uint ordinalTableRVA;
}

public struct ImportTable
{
public:
final:
    uint importLookupTableRVA;
    uint timeStamp;
    uint forwarderChain;
    uint nameRVA;
    uint importAddressTableRVA;
}

/* public struct ImportLookupTable
{
public:
final:
    mixin(bitfields!(
        bool, "importByName", 1,
        ushort, "ordinalNumber", 16,
        uint, "nameTableRVA", 31
    ));
} */

public struct NameTable
{
public:
final:
    ushort hint;
    string name;
}

public struct ResourceTable
{
public:
final:
    ushort characteristics;
    ushort timeDateStamp;
    ushort majorVersion;
    ushort minorVersion;
    ushort numberOfNameEntries;
    ushort numberOfIDEntries;
}

public struct AttributeCertificateEntry 
{
public:
final:
    uint dwLength;
    ushort wRevision;
    ushort wCertificateType;
    ubyte[] bCertificate;
}

public struct RelocEntry
{
public:
final:
    ushort type;
    ushort offset;
}

public struct RelocTable 
{
public:
final:
    uint pageRVA;
    RelocEntry[] entries;
}

public struct ClrRuntimeHeader
{
public:
final:
    uint size;
    ushort majorRuntimeVersion;
    ushort minorRuntimeVersion;
    DataDirectory metaData;
    uint flags;
    uint entryPointToken;
    DataDirectory resources;
    DataDirectory strongNameSignature;
    DataDirectory codeManagerTable;
    DataDirectory vtableFixups;
    DataDirectory exportAddressTableJumps;
    DataDirectory managedNativeHeader;
}