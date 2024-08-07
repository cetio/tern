module tern.os.pe;

public import tern.os.pe.dotnet;
public import tern.os.pe.directories;
public import tern.os.pe.optional;
public import tern.os.pe.standard;
import tern.stream.binary_stream;
import std.file;

public struct RVA
{
package:
final:
    PE pe;

public:
    uint raw;

    // This is flawed for loaded images, but generally should be fine...
    @property ulong offset() const
    {
        foreach (section; pe.sections)
        {
            if (raw >= section.virtualRva.raw && raw < section.virtualRva.raw + section.size)
                return (raw - section.virtualRva.raw) + section.raw;  
        }
        
        if (raw >= pe.optionalImage.imageBase && raw < pe.optionalImage.imageBase + pe.optionalImage.imageSize)
            return raw + pe.optionalImage.imageBase;

        // Section doesn't exist, RVA is invalid.
        return -1;
    }

    @property ulong offset(ulong val)
    {
        return raw += cast(uint)(offset - val);
    }

    @property ulong objective() const => raw;

    @property void* ptr() const => cast(void*)offset;
    @property void* ptr(void* val) => cast(void*)(offset = cast(ulong)val);
}

public class PE
{
package:
final:
    BinaryStream stream;
    alias stream this;

public:
    DOSHeader dosHeader;
    COFFHeader coffHeader;
    OptionalImage optionalImage;
    Section[] sections;

    this(string path)
    {
        this(cast(ubyte[])read(path));
    }

    this(ubyte[] data)
    {
        stream = new BinaryStream(data);

        dosHeader = DOSHeader(this);
        coffHeader = COFFHeader(this);
        optionalImage = OptionalImage(this);

        // This code is horrendous and somebody needs to turn it to sand!
        size_t _position = position;
        position += 16 * 8;
        foreach (i; 0..coffHeader.numSections)
            sections ~= Section(this);

        position = _position;
        if (optionalImage.numDirectories >= 1)
            optionalImage.exportTable = ExportTable(this);

        if (optionalImage.numDirectories >= 2)
            optionalImage.importTable = ImportTable(this);

        if (optionalImage.numDirectories >= 3)
            optionalImage.resourceTable = ResourceTable(this);

        if (optionalImage.numDirectories >= 4)
            position += 8;
            //exceptionTable = ExceptionTable(pe);

        if (optionalImage.numDirectories >= 5)
            position += 8;
            //certTable = CertificateTable(pe);

        if (optionalImage.numDirectories >= 6)
            optionalImage.relocTable = RelocTable(this);

        if (optionalImage.numDirectories >= 7)
            position += 8;
            //debugData = DebugData(pe);

        if (optionalImage.numDirectories >= 8)
            position += 8;

        if (optionalImage.numDirectories >= 9)
            optionalImage.globalPointer = DataDirectory(this);

        if (optionalImage.numDirectories >= 10)
            position += 8;
            //tlsTable = TLSTable(pe);

        if (optionalImage.numDirectories >= 11)
            position += 8;
            //loadCfgTable = LoadConfigTable(pe);

        if (optionalImage.numDirectories >= 12)
            optionalImage.boundImport = DataDirectory(this);

        if (optionalImage.numDirectories >= 13)
            optionalImage.importAddrTable = DataDirectory(this);

        if (optionalImage.numDirectories >= 14)
            position += 8;
            //delayImportDesc = DelayImportDesc(pe);

        if (optionalImage.numDirectories >= 15)
            optionalImage.cor20Header = Cor20Header(this);
            
        if (optionalImage.numDirectories >= 16)
            position += 8;
    }
}