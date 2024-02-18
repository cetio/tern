module tern.exec.pe.dotnet.tables.param;

public struct Param
{
public:
final:
    ushort flags;
    ushort sequence;
    ubyte[] name;
}