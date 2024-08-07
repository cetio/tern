module tern.os.pe.dotnet.tables.exportedtype;

import tern.os.pe.dotnet.tables.ttypedef : TypeAttributes;

public struct ExportedType
{
public:
final:
    TypeAttributes flags;
    uint typeDefId;
    int name;
    int namespace;
    int impl;
}