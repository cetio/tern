module tern.os.pe.dotnet.tables.methodsemantics;

public enum MethodSemanticsAttributes : ushort
{
    /// The method is a setter for a property.
    Setter = 0x0001,
    /// The method is a getter for a property.
    Getter = 0x0002,
    /// The method is an unspecified method for a property or event.
    Other = 0x0004,
    /// The method is an AddOn for an event.
    AddOn = 0x0008,
    /// The method is a RemoveOn for an event.
    RemoveOn = 0x0010,
    /// The method is used to fire an event.
    Fire = 0x0020,
}

public struct MethodSemantics
{
public:
final:
    MethodSemanticsAttributes semantics;
    int method;
    int association;
}