module tern.os.pe.dotnet.tables.genericparam;

public enum GenericParameterAttributes : ushort
{
    /// Specifies the generic parameter has no special variance rules applied to it.
    NonVariant = 0x0000,
    /// Specifies the generic parameter is covariant and can appear as the result type of a method, the type of a read-only field, a declared base type or an implemented interface.
    Covariant = 0x0001,
    /// Specifies the generic parameter is contravariant and can appear as a parameter type in method signatures.
    Contravariant = 0x0002,
    /// Provides a mask for variance of type parameters, only applicable to generic parameters for generic interfaces and delegates
    VarianceMask = 0x0003,
    /// Provides a mask for additional constraint rules.
    SpecialConstraintMask = 0x001C,
    /// Specifies the generic parameter's type argument must be a type reference.
    ReferenceTypeConstraint = 0x0004,
    /// Specifies the generic parameter's type argument must be a value type and not nullable.
    NotNullableValueTypeConstraint = 0x0008,
    /// Specifies the generic parameter's type argument must have a public default constructor.
    DefaultConstructorConstraint = 0x0010,
}

public struct GenericParam
{
public:
final:
    ushort number;
    GenericParameterAttributes flags;
    int owner;
    int name;
}