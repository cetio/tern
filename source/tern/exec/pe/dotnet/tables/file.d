module tern.exec.pe.dotnet.tables.file;

public struct File
{
public:
final:
    uint flags;
    ubyte[] name;
    uint hashValue;
}