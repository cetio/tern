module tern.os.pe.dotnet.tables.param;

public enum ParamAttributes : ushort
{
    /// Parameter is an input parameter.
    In = 0x0001,
    /// Parameter is an output parameter.
    Out = 0x0002,
    /// Parameter is an optional parameter.
    Optional = 0x0010,
    /// Parameter has got a default value.
    HasDefault = 0x1000,
    /// Parameter has got field marshalling information.
    HasFieldMarshal = 0x2000,
} 

public struct Param
{
public:
final:
    ParamAttributes flags;
    ushort sequence;
    int name;
}