module tern.os.pe.dotnet.tables.fileref;

public enum FileAttributes : uint
{
    /// Specifies the file reference contains metadata.
    ContainsMetadata,
    /// Specifies the file references doesn't contain metadata.
    ContainsNoMetadata,
}

public struct File
{
public:
final:
    FileAttributes flags;
    int name;
    int hashValue;
}