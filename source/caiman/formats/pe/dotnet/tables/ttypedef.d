module caiman.formats.pe.dotnet.tables.ttypedef;

public struct TypeDef
{
public:
final:
    uint flags;
    uint name;
    uint namespace;
    uint extends;
    uint fieldList;
    uint methodList;
}