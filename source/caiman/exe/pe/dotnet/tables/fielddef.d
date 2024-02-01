module caiman.exe.pe.dotnet.tables.fielddef;

public struct FieldDef
{
public:
final:
    ushort flags;
    ubyte[] name;
    ubyte[] signature;
}