module tern.os.pe.dotnet.tables.assemblyref;

public import tern.os.pe.dotnet.tables.assemblydef : AssemblyAttributes;

public struct AssemblyRef
{
public:
final:
    ushort majorVersion;
    ushort minorVersion;
    ushort buildNumber;
    ushort revisionNumber;
    AssemblyAttributes flags;
    int publicKeyOrToken;
    int name;
    int culture;
    int hashValue;
}