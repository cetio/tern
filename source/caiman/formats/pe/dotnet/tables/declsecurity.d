module caiman.formats.pe.dotnet.tables.declsecurity;

public struct DeclSecurity
{
public:
final:
    ushort action;
    uint parent;
    uint permissionSet;
}