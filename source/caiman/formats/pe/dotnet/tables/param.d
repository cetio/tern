module caiman.formats.pe.dotnet.tables.param;

public struct Param
{
public:
final:
    ushort flags;
    ushort sequence;
    ubyte[] name;
}