module caiman.formats.pe.dotnet.tables.manifestresource;

public struct ManifestResource
{
public:
final:
    uint offset;
    uint flags;
    ubyte[] name;
    uint implementation;
}