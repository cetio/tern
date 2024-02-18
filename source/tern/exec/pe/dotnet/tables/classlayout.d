module tern.exec.pe.dotnet.tables.classlayout;

public struct ClassLayout
{
public:
final:
    ushort packingSize;
    uint classSize;
    uint parent;
}