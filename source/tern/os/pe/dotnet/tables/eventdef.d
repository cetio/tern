module tern.os.pe.dotnet.tables.eventdef;

public enum EventAttributes : ushort
{
    /// Specifies that the event is using a special name.
    SpecialName = 0x0200,
    /// Specifies that the runtime should check the name encoding.
    RtSpecialName = 0x0400,
}

public struct EventDef
{
public:
final:
    EventAttributes eventFlags;
    int name;
    int type;
}