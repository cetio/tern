module caiman.formats.pe.dotnet.tables.field;

public struct Field
{
public:
final:
    ushort flags;
    uint name;
    uint signature;
}