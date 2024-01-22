module caiman.formats.pe.dotnet.tables.property;

public struct Property
{
public:
final:
    ushort flags;
    uint name;
    uint type;
}