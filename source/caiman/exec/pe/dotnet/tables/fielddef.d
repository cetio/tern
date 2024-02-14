module caiman.exec.pe.dotnet.tables.fielddef;

public struct FieldDef
{
public:
final:
    ushort flags;
    ubyte[] name;
    ubyte[] signature;
}