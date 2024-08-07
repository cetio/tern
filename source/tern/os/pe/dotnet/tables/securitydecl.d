module tern.os.pe.dotnet.tables.securitydecl;

public enum SecurityAction : ushort
{
    /// Indicates all callers higher in the call stack are required to have been granted the permission specified
    /// by the current permission object.
    Demand = 2,
    /// Indicates the calling code can access the resource identified by the current permission object,
    /// even if callers higher in the stack have not been granted permission to access the resource.
    Assert = 3,
    /// Indicates the ability to access the resource specified by the current permission object is denied to callers,
    /// even if they have been granted permission to access it.
    Deny = 4,
    /// Indicatges only the resources specified by this permission object can be accessed, even if the code has
    /// been granted permission to access other resources.
    PermitOnly = 5,
    /// Indicates the immediate caller is required to have been granted the specified permission.
    LinkDemand = 6,
    /// Indicates the derived class inheriting the class or overriding a method is required to have been granted the
    /// specified permission.
    InheritanceDemand = 7,
    /// Indicates the request for the minimum permissions required for code to run. This action can only be used
    /// within the scope of the assembly.
    RequestMinimum = 8,
    /// Indicates the request for additional permissions that are optional (not required to run). This request
    /// implicitly refuses all other permissions not specifically requested. This action can only be used within
    /// the scope of the assembly.
    RequestOptional = 9,
    /// The request that permissions that might be misused will not be granted to the calling code.
    /// This action can only be used within the scope of the assembly.
    RequestRefuse = 10,
}

public struct SecurityDecl
{
public:
final:
    SecurityAction action;
    int parent;
    int permissionSet;
}