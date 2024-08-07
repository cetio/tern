module tern.os.pe.dotnet.tables.fielddef;

public enum FieldAttributes : ushort
{
    /// The bitmask that is being used to get the access level of the field.
    FieldAccessMask = 0x0007,
    /// Specifies the field cannot be referenced.
    PrivateScope = 0x0000,
    /// Specifies the field can only be accessed by its declaring type.
    Private = 0x0001,
    /// Specifies the field can only be accessed by sub-types in the same assembly.
    FamilyAndAssembly = 0x0002,
    /// Specifies the field can only be accessed by members in the same assembly.
    Assembly = 0x0003,
    /// Specifies the field can only be accessed by this type and sub-types.
    Family = 0x0004,
    /// Specifies the field can only be accessed by sub-types and anyone in the assembly.
    FamilyOrAssembly = 0x0005,
    /// Specifies the field can be accesed by anyone who has visibility to this scope.
    Public = 0x0006,
    /// Specifies the field can be accessed without requiring an instance.
    Static = 0x0010,
    /// Specifies the field can only be initialized and not being written after the initialization.
    InitOnly = 0x0020,
    /// Specifies the field's value is at compile time constant.
    Literal = 0x0040,
    /// Specifies the field does not have to be serialized when the type is remoted.
    NotSerialized = 0x0080,
    /// Specifies the field uses a special name.
    SpecialName = 0x0200,
    /// Specifies the field is an implementation that is being forwarded through PInvoke.
    PInvokeImpl = 0x2000,
    /// Reserved flags for runtime use only.
    ReservedMask = 0x9500,
    /// Specifies the runtime should check the name encoding.
    RuntimeSpecialName = 0x0400,
    /// Specifies the field has got marshalling information.
    HasFieldMarshal = 0x1000,
    /// Specifies the field has got a default value.
    HasDefault = 0x8000,
    /// Specifies the field has got an Rva.
    HasFieldRva = 0x0100,
}

public struct FieldDef
{
public:
final:
    FieldAttributes flags;
    int name;
    int signature;
}