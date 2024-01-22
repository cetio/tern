/// Support for handling PE and ELF formats.
// TODO: ELF
module caiman.formats.portexec;

import caiman.data;
import caiman.mem;
import caiman.formats.pe;
import std.traits;
import std.string;

/**
 * Represents a PE file, providing methods to read its headers and optional image data.
 */
 // TODO: DataDirectory & metadata
public class PE
{
private:
final:
    /// The stream used for reading the PE file.
    Stream stream;

    /// Reads the DOS header of the PE file.
    void readDOSHeader() 
    {
        dosHeader = stream.read!DOSHeader;
    }

    /// Reads the COFF header of the PE file.
    void readCOFFHeader() 
    {
        stream.position = dosHeader.e_lfanew;
        coffHeader = stream.read!COFFHeader;
    }

    /// Reads the optional image data of the PE file.
    void readOptionalImage() 
    {
        if (coffHeader.sizeOfOptionalHeader == 0)
            return;
            
        ImageType type = stream.peek!ImageType;

        if (type == ImageType.ROM)
        {
            *cast(ROMImage*)&optionalImage = stream.read!ROMImage;
        }
        else if (type == ImageType.PE32)
        {
            optionalImage = stream.read!PE32Image.ddupa!OptionalImage;
        }
        else if (type == ImageType.PE64)
        {
            *cast(PE64Image*)&optionalImage = stream.readPlasticized!(PE64Image, "baseOfData", "type", ImageType.PE32);
        }
    }
    
    /// Reads the data directories and sections of the PE file.
    void readDirSec()
    {
        dataDirectories = stream.read!DataDirectory(optionalImage.numDataDirectories);
        sections = stream.read!Section(coffHeader.numberOfSections);
    }

    void readCor20Header()
    {
        if (dataDirectories.length < 15 || dataDirectories[14].rva == 0)
            return;
        
        stream.position = getOffset(dataDirectories[14].rva);
        cor20Header = stream.read!Cor20Header;
        stream.position = getOffset(cor20Header.metadata.rva);
        metadata = stream.read!(Metadata, "versionString", ReadKind.Field, "versionStringLength");

        foreach (i; 0..metadata.streams)
        {
            StorageStream ss;
            ss.offset = stream.read!uint;
            ss.size = stream.read!uint;
            ss.name = stream.readString!char;

            if (i < metadata.streams - 1)
                stream.stepUntil('#');
            stream.position -= 8;
            storageStreams ~= ss;
        }
    }

public:
    DOSHeader dosHeader;
    COFFHeader coffHeader;
    OptionalImage optionalImage;
    DataDirectory[] dataDirectories;
    Section[] sections;

    Cor20Header cor20Header;
    Metadata metadata;
    StorageStream[] storageStreams;

    /**
    * Reads a PE file from the specified file path.
    *
    * Params:
    *   - `filePath`: The path to the PE file to be read.
    *
    * Returns:
    *   A PE object containing the parsed data from the file.
    */
    static PE read(string filePath)
    {
        PE pe = new PE();
        pe.stream = new Stream(filePath);

        pe.readDOSHeader();
        pe.readCOFFHeader();
        pe.readOptionalImage();
        pe.readDirSec();

        pe.readCor20Header();

        return pe;
    }

    uint getOffset(uint rva)
    {
        foreach (section; sections)
        {
            if (rva >= section.virtualAddress && rva < section.virtualAddress + section.sizeOfRawData)
                return (rva - section.virtualAddress) + section.pointerToRawData;
        }
        // Section doesn't exist, rva is invalid.
        return -1;
    }
}