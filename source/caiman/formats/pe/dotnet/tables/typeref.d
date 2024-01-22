module caiman.formats.pe.dotnet.tables.typeref;

public struct TypeRef
{
public:
final:
    uint resolutionScope;
    uint typeName;
    uint typeNamespace;
}