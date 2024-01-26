module caiman.formats.pe.dotnet.tables.methoddef;

public struct MethodDef
{
public:
final:
    uint rva;
    ushort implFlags;
    ushort flags;
    ubyte[] name;
    ubyte[] signature;
    uint paramList;
}