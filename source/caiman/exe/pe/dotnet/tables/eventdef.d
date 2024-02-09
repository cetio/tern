module caiman.exe.pe.dotnet.tables.eventdef;

public struct EventDef
{
public:
final:
    ushort eventFlags;
    ubyte[] name;
    uint eventType;
}