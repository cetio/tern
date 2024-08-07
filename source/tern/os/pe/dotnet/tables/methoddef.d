module tern.os.pe.dotnet.tables.methoddef;

public enum MethodAttributes : ushort
{
    /// <summary>
    /// Specifies the method can't be referenced.
    CompilerControlled = 0x0000,
    /// <summary>
    /// Specifies the method can only be accessed by its declaring type.
    Private = 0x0001,
    /// <summary>
    /// Specifies the method can only be accessed by sub-types in the same assembly.
    FamilyAndAssembly = 0x0002,
    /// <summary>
    /// Specifies the method can only be accessed by members in the same assembly.
    Assembly = 0x0003,
    /// <summary>
    /// Specifies that the method can only be accessed by this type and sub-types.
    Family = 0x0004,
    /// <summary>
    /// Specifies the method can only be accessed by sub-types and anyone in the assembly.
    FamilyOrAssembly = 0x0005,
    /// <summary>
    /// Specifies the method can be accesed by anyone who has visibility to this scope.
    Public = 0x0006,
    /// <summary>
    /// Provides a bitmask for all flags related to member access.
    MemberAccessMask = 0x7,
    /// <summary>
    /// Indicates that the managed method is exported by thunk to unmanaged code.
    UnmanagedExport = 0x8,
    /// <summary>
    /// Specifies the method can be accessed without requiring an instance.
    Static = 0x0010,
    /// <summary>
    /// Specifies the method cannot be overridden.
    Final = 0x20,
    /// <summary>
    /// Specifies the method is virtual.
    Virtual = 0x40,
    /// <summary>
    /// Specifies the method is being distinguished by it's name + signature.
    HideBySig = 0x80,
    /// <summary>
    /// Specifies the method reuses an existing slot in vtable.
    ReuseSlot = 0x0,
    /// <summary>
    /// Specifies the method always gets a new slot in the vtable.
    NewSlot = 0x100,
    /// <summary>
    /// Provides a bitmask for flags related to the vtable layout.
    VtableLayoutMask = 0x100,
    /// <summary>
    /// Indicates that the method can only be overridden when it is also accessible.
    CheckAccessOnOverride = 0x200,
    /// <summary>
    /// Indicates the method is abstract and needs to be overridden in a derived class.
    Abstract = 0x400,
    /// <summary>
    /// Specifies that the method uses a special name.
    SpecialName = 0x800,
    /// <summary>
    /// Specifies that the runtime should check the name encoding.
    RuntimeSpecialName = 0x1000,
    /// <summary>
    /// Specifies that the method is an implementation that is being forwarded through PInvoke.
    PInvokeImpl = 0x2000,
    /// <summary>
    /// Specifies the method has security associate with it.
    HasSecurity = 0x4000,
    /// <summary>
    /// Specifies the method calls another method containing security code.
    RequireSecObject = 0x8000,
}

public enum MethodImplAttributes : ushort
{
    /// <summary>
    /// Method implementation is IL.
    IL = 0x0000,
    /// Method implementation is native.
    Native = 0x0001,
    /// Method implementation is OPTIL.
    OPTIL = 0x0002,
    /// Method implementation is provided by the runtime.
    Runtime = 0x0003,
    /// Provides a bitmask for obtaining the flags related to the code type of the method.
    CodeTypeMask = 0x0003,
    /// Method implementation is unmanaged.
    Unmanaged = 0x0004,
    /// Method implementation is managed.
    Managed = 0x0000,
    /// Provides a bitmask for obtaining the flags specifying whether the code is managed or unmanaged.
    ManagedMask = 0x0004,
    /// Indicates the method is defined; used primarily in merge scenarios.
    ForwardRef = 0x0010,
    /// Method will not be optimized when generating native code.
    NoOptimization = 0x0040,
    /// Indicates the method signature is not to be mangled to do HRESULT conversion.
    PreserveSig = 0x0080,
    /// Reserved for internal use.
    InternalCall = 0x1000,
    /// Method is single threaded through the body.
    Synchronized = 0x0020,
    /// Method may not be inlined.
    NoInlining = 0x0008,
    /// Method should be inlined if possible.
    AggressiveInlining = 0x0100,
    /// Method may contain hot code and should be aggressively optimized.
    AggressiveOptimization = 0x0200,
    /// Specifies that the JIT compiler should look for security mitigation attributes, such as the user-defined
    /// System.Runtime.CompilerServices.SecurityMitigationsAttribute. If found, the JIT compiler applies
    /// any related security mitigations. Available starting with .NET Framework 4.8.
    SecurityMitigations,
}

public struct MethodDef
{
public:
final:
    uint rva;
    MethodImplAttributes implFlags;
    MethodAttributes flags;
    int name;
    int signature;
    int paramList;
}