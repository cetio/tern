module caiman.formats.pe.dotnet.stream;

public struct StorageStream
{
public:
final:
    uint offset;
    uint size;
    string name;
}

public enum HeapFlags : ubyte
{
    BigStrings = 1,
    BigBlob = 2,
    Reserved = 4,
    ExtraData = 8,
    BigGuid = 16,
    Padding = 32,
    DeltaOnly = 64,
    HasDelete = 128
}

public enum TableTokens : ulong
{
    Module = 0x1,
    TypeRef = 0x2,
    TypeDef = 0x4,
    Field = 0x10,
    MethodDef = 0x40,
    Param = 0x100,
    InterfaceImpl = 0x200,
    MemberRef = 0x400,
    Constant = 0x800,
    CustomAttribute = 0x1000,
    FieldMarshal = 0x2000,
    DeclSecurity = 0x4000,
    ClassLayout = 0x8000,
    FieldLayout = 0x10000,
    StandAloneSig = 0x20000,
    EventMap = 0x40000,
    Event = 0x100000,
    PropertyMap = 0x200000,
    Property = 0x800000,
    MethodSemantics = 0x1000000,
    MethodImpl = 0x2000000,
    ModuleRef = 0x4000000,
    TypeSpec = 0x8000000,
    ImplMap = 0x10000000,
    FieldRva = 0x20000000,
    Assembly = 0x100000000,
    AssemblyProcessor = 0x200000000,
    AssemblyOS = 0x400000000,
    AssemblyRef = 0x800000000,
    AssemblyRefProcessor = 0x1000000000,
    AssemblyRefOS = 0x2000000000,
    File = 0x4000000000,
    ExportedType = 0x8000000000,
    ManifestResource = 0x10000000000,
    NestedClass = 0x20000000000,
    GenericParam = 0x40000000000,
    MethodSpec = 0x80000000000,
    GenericParamConstraint = 0x100000000000
}

public struct TablesStream
{
public:
final:
    uint reserved;
    ubyte majorVersion;
    ubyte minorVersion;
    HeapFlags heapFlags;
    ubyte rid;
    TableTokens tokens;
    ulong sorted;
}