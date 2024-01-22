module caiman.formats.pe.dotnet.tables.mmodule;

public struct Module
{
public:
final:
    ushort generation;
    uint name;
    uint mvid;
    uint encId;
    uint encBaseId;
}