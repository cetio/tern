module caiman.formats.pe.dotnet.tables.assembly;

public struct Assembly
{
public:
final:
    uint hashAlgoId;
    ushort majorVersion;
    ushort minorVersion;
    ushort buildNumber;
    ushort revisionNumber;
    uint flags;
    uint publicKey;
    uint name;
    uint culture;
}