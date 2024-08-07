module tern.os.pe.dotnet.tables.property;

public enum PropertyAttributes : ushort
{
    /// The property has no attribute.
    None = 0x0000,
    /// The property uses a special name.
    SpecialName = 0x0200,
    /// The runtime should check the name encoding.
    RuntimeSpecialName = 0x0400,
    /// The property has got a default value.
    HasDefault = 0x1000,
}

public struct Property
{
public:
final:
    PropertyAttributes flags;
    int name;
    int type;
}