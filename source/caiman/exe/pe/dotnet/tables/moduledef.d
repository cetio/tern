module caiman.exe.pe.dotnet.tables.moduledef;

public struct ModuleDef
{
public:
final:
    ushort generation;
    ubyte[] name;
    ubyte[] mvid;
    ubyte[] encId;
    ubyte[] encBaseId;
}