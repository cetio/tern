module tern.exec.pe.dotnet.tables.assemblyref;

public struct AssemblyRef
{
public:
final:
    ushort majorVersion;
    ushort minorVersion;
    ushort buildNumber;
    ushort revisionNumber;
    uint flags;
    uint publicKeyOrToken;
    ubyte[] name;
    uint culture;
    uint hashValue;
}