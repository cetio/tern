module tern.os.pe.dotnet.tables.manifestresource;

public enum ManifestResourceAttributes : uint
{
    /// Specifies the resource is exported from the asembly.
    Public = 0x0001,
    /// Specifies the resource is private to the assembly.
    Private = 0x0002,
}

public struct ManifestResource
{
public:
final:
    uint offset;
    ManifestResourceAttributes flags;
    int name;
    int impl;
}