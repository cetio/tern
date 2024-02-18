module tern.exec.pe.dotnet.tables.property;

public struct Property
{
public:
final:
    ushort flags;
    ubyte[] name;
    uint type;
}