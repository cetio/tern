module tern.os.pe.dotnet.tables.ttypedef;

public enum TypeAttributes : uint
{
    /// Class is not public scope.
    NotPublic = 0x00000000,
    /// Class is public scope.
    Public = 0x00000001,
    /// Class is nested with public visibility.
    NestedPublic = 0x00000002,
    /// Class is nested with private visibility.
    NestedPrivate = 0x00000003,
    /// Class is nested with family visibility.
    NestedFamily = 0x00000004,
    /// Class is nested with assembly visibility.
    NestedAssembly = 0x00000005,
    /// Class is nested with family and assembly visibility.
    NestedFamilyAndAssembly = 0x00000006,
    /// Class is nested with family or assembly visibility.
    NestedFamilyOrAssembly = 0x00000007,
    /// Provides a bitmask for obtaining flags related to visibility.
    VisibilityMask = 0x00000007,

    /// Class fields are auto-laid out
    AutoLayout = 0x00000000,
    /// Class fields are laid out sequentially
    SequentialLayout = 0x00000008,
    /// Layout is supplied explicitly
    ExplicitLayout = 0x00000010,
    /// Provides a bitmask for obtaining flags related to the layout of the type.
    LayoutMask = 0x00000018,

    /// BaseType is a class.
    Class = 0x00000000,
    /// BaseType is an interface.
    Interface = 0x00000020,
    /// Provides a bitmask for obtaining flags related to the semantics of the type.
    ClassSemanticsMask = 0x00000060,

    /// Class is abstract.
    Abstract = 0x00000080,
    /// Class is concrete and may not be extended.
    Sealed = 0x00000100,
    /// Class name is special. Name describes how.
    SpecialName = 0x00000400,
    /// Runtime should check name encoding.
    RuntimeSpecialName = 0x00000800,
    /// Class/interface is imported.
    Import = 0x00001000,
    /// The class is Serializable.
    Serializable = 0x00002000,

    /// LPTSTR is interpreted as ANSI in this class.
    AnsiClass = 0x00000000,
    /// LPTSTR is interpreted as UNICODE.
    UnicodeClass = 0x00010000,
    /// LPTSTR is interpreted automatically
    AutoClass = 0x00020000,
    /// A non-standard encoding specified by CustomFormatMask.
    CustomFormatClass = 0x00030000,

    /// Provides a bitmask for obtaining flag related to string format.
    StringFormatMask = 0x00030000,

    /// Initialize the class any time before first static field access.
    BeforeFieldInit = 0x00100000,
    /// This ExportedType is a type forwarder.
    Forwarder = 0x00200000,

    /// Class has security associate with it.
    HasSecurity = 0x00040000,
}

public struct TypeDef
{
public:
final:
    TypeAttributes flags;
    int name;
    int namespace;
    int extends;
    int fieldList;
    int methodList;
}