module caiman.formats.pe.dotnet.tables.event;

public struct Event
{
public:
final:
    ushort eventFlags;
    uint name;
    uint eventType;
}