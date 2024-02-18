module tern.exec.pe.dotnet.tables.ttypedef;

public struct TypeDef
{
public:
final:
    uint flags;
    ubyte[] name;
    ubyte[] namespace;
    uint extends;
    uint fieldList;
    uint methodList;
}