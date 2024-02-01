module caiman.exe.pe.dotnet.tables.event;

public struct Event
{
public:
final:
    ushort eventFlags;
    ubyte[] name;
    uint eventType;
}