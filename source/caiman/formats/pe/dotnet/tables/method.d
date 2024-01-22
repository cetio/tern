module caiman.formats.pe.dotnet.tables.method;

public struct Method
{
public:
final:
    uint rva;
    ushort implFlags;
    ushort flags;
    uint name;
    uint signature;
    uint paramList;
}