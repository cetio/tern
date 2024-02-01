module caiman.exe.pe.dotnet.tables.memberref;

public struct MemberRef
{
public:
final:
    uint _class;
    ubyte[] name;
    ubyte[] signature;
}