module tern.os.pe.dotnet.tables.classlayout;

public struct ClassLayout
{
public:
final:
    ushort packingSize;
    uint classSize;
    int parent;
}