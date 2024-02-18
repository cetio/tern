module tern.exec.pe.dotnet.tables.implmap;

public struct ImplMap
{
public:
final:
    ushort mappingflags;
    uint memberForwarded;
    uint importName;
    uint importScope;
}