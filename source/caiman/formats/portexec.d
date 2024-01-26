/// Support for handling PE and ELF formats.
// TODO: ELF
module caiman.formats.portexec;

import caiman.container.stream;
import caiman.memory.ops;
import caiman.state;
import caiman.formats.pe;
import caiman.meta.traits;
import std.string;

public struct ClrMetadata
{
    MetadataTable metadataTable;

    StorageStream[] storageStreams;
    TablesStream tablesStream;
    char[] stringsStream;
    char[] usStream;
    ubyte[] guidStream;
    ubyte[] blobStream;

    Assembly[] assembly;
    AssemblyOS[] assemblyOS;
    AssemblyProcessor[] assemblyProcessor;
    AssemblyRef[] assemblyRef;
    AssemblyRefOS[] assemblyRefOS;
    AssemblyRefProcessor[] assemblyRefProcessor;
    ClassLayout[] classLayout;
    Constant[] constant;
    CustomAttribute[] customAttribute;
    DeclSecurity[] declSecurity;
    Event[] event;
    EventMap[] eventMap;
    ExportedType[] exportedType;
    FieldDef[] fieldDef;
    FieldLayout[] fieldLayout;
    FieldMarshal[] fieldMarshal;
    FieldRVA[] fieldRVA;
    File[] file;
    GenericParam[] genericParam;
    GenericParamConstraint[] genericParamConstraint;
    ImplMap[] implMap;
    InterfaceImpl[] interfaceImpl;
    ManifestResource[] manifestResource;
    MemberRef[] memberRef;
    MethodDef[] methodDef;
    MethodImpl[] methodImpl;
    MethodSemantics[] methodSemantics;
    ModuleDef[] moduleDef;
    ModuleRef[] moduleRef;
    NestedClass[] nestedClass;
    Param[] param;
    Property[] property;
    PropertyMap[] propertyMap;
    StandAloneSig[] standAloneSig;
    TypeDef[] typeDef;
    TypeRef[] typeRef;
    TypeSpec[] typeSpec;
    MethodSpec[] methodSpec;
}

/**
 * Represents a PE file, providing methods to read its headers and optional image data.
 */
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

    void readClr()
    {
        if (dataDirectories.length < 15 || dataDirectories[14].rva == 0)
            return;
        
        stream.position = getOffset(dataDirectories[14].rva);
        cor20Header = stream.read!Cor20Header;
        stream.position = getOffset(cor20Header.metadata.rva);
        clrMetadata.metadataTable = stream.read!(MetadataTable, "versionString", ReadKind.Field, "versionStringLength");

        foreach (i; 0..clrMetadata.metadataTable.streams)
        {
            auto ss = StorageStream(
                stream.read!uint,
                stream.read!uint,
                stream.readString!char
            );

            if (i < clrMetadata.metadataTable.streams - 1)
                stream.stepUntil('#');
                
            stream.position -= 8;
            clrMetadata.storageStreams ~= ss;
        }

        ptrdiff_t position;
        foreach (ss; clrMetadata.storageStreams)
        {
            if (ss.name == "#~" || ss.name == "#-")
            {
                stream.position = getOffset(cor20Header.metadata.rva) + ss.offset;
                position = stream.position;
                clrMetadata.tablesStream = stream.read!TablesStream;

                if (clrMetadata.tablesStream.heapFlags.hasFlag(HeapFlags.ExtraData))
                    stream.step!uint;
            }
            else if (ss.name == "#Strings")
            {
                stream.position = getOffset(cor20Header.metadata.rva) + ss.offset;
                clrMetadata.stringsStream = stream.read!char(ss.size);
            }
            else if (ss.name == "#US")
            {
                stream.position = getOffset(cor20Header.metadata.rva) + ss.offset;
                clrMetadata.usStream = stream.read!char(ss.size);
            }
            else if (ss.name == "#GUID")
            {
                stream.position = getOffset(cor20Header.metadata.rva) + ss.offset;
                clrMetadata.guidStream = stream.read!ubyte(ss.size);
            }
            else if (ss.name == "#Blob")
            {
                stream.position = getOffset(cor20Header.metadata.rva) + ss.offset;
                clrMetadata.blobStream = stream.read!ubyte(ss.size);
            }
        }
        stream.position = position + TablesStream.sizeof;

        foreach (member; FieldNames!TableTokens)
        {
            if (!clrMetadata.tablesStream.tokens.hasFlag(__traits(getMember, TableTokens, member)))
                continue;

            if (member == "Module")
                clrMetadata.moduleDef = new ModuleDef[stream.read!uint];
            else if (member == "TypeRef")
                clrMetadata.typeRef = new TypeRef[stream.read!uint];
            else if (member == "TypeDef")
                clrMetadata.typeDef = new TypeDef[stream.read!uint];
            else if (member == "Field")
                clrMetadata.fieldDef = new FieldDef[stream.read!uint];
            else if (member == "MethodDef")
                clrMetadata.methodDef = new MethodDef[stream.read!uint];
            else if (member == "Param")
                clrMetadata.param = new Param[stream.read!uint];
            else if (member == "InterfaceImpl")
                clrMetadata.interfaceImpl = new InterfaceImpl[stream.read!uint];
            else if (member == "MemberRef")
                clrMetadata.memberRef = new MemberRef[stream.read!uint];
            else if (member == "Constant")
                clrMetadata.constant = new Constant[stream.read!uint];
            else if (member == "CustomAttribute")
                clrMetadata.customAttribute = new CustomAttribute[stream.read!uint];
            else if (member == "FieldMarshal")
                clrMetadata.fieldMarshal = new FieldMarshal[stream.read!uint];
            else if (member == "DeclSecurity")
                clrMetadata.declSecurity = new DeclSecurity[stream.read!uint];
            else if (member == "ClassLayout")
                clrMetadata.classLayout = new ClassLayout[stream.read!uint];
            else if (member == "FieldLayout")
                clrMetadata.fieldLayout = new FieldLayout[stream.read!uint];
            else if (member == "StandAloneSig")
                clrMetadata.standAloneSig = new StandAloneSig[stream.read!uint];
            else if (member == "EventMap")
                clrMetadata.eventMap = new EventMap[stream.read!uint];
            else if (member == "Event")
                clrMetadata.event = new Event[stream.read!uint];
            else if (member == "PropertyMap")
                clrMetadata.propertyMap = new PropertyMap[stream.read!uint];
            else if (member == "Property")
                clrMetadata.property = new Property[stream.read!uint];
            else if (member == "MethodSemantics")
                clrMetadata.methodSemantics = new MethodSemantics[stream.read!uint];
            else if (member == "MethodImpl")
                clrMetadata.methodImpl = new MethodImpl[stream.read!uint];
            else if (member == "ModuleRef")
                clrMetadata.moduleRef = new ModuleRef[stream.read!uint];
            else if (member == "TypeSpec")
                clrMetadata.typeSpec = new TypeSpec[stream.read!uint];
            else if (member == "ImplMap")
                clrMetadata.implMap = new ImplMap[stream.read!uint];
            else if (member == "FieldRva")
                clrMetadata.fieldRVA = new FieldRVA[stream.read!uint];
            else if (member == "Assembly")
                clrMetadata.assembly = new Assembly[stream.read!uint];
            else if (member == "AssemblyProcessor")
                clrMetadata.assemblyProcessor = new AssemblyProcessor[stream.read!uint];
            else if (member == "AssemblyOS")
                clrMetadata.assemblyOS = new AssemblyOS[stream.read!uint];
            else if (member == "AssemblyRef")
                clrMetadata.assemblyRef = new AssemblyRef[stream.read!uint];
            else if (member == "AssemblyRefProcessor")
                clrMetadata.assemblyRefProcessor = new AssemblyRefProcessor[stream.read!uint];
            else if (member == "AssemblyRefOS")
                clrMetadata.assemblyRefOS = new AssemblyRefOS[stream.read!uint];
            else if (member == "File")
                clrMetadata.file = new File[stream.read!uint];
            else if (member == "ExportedType")
                clrMetadata.exportedType = new ExportedType[stream.read!uint];
            else if (member == "ManifestResource")
                clrMetadata.manifestResource = new ManifestResource[stream.read!uint];
            else if (member == "NestedClass")
                clrMetadata.nestedClass = new NestedClass[stream.read!uint];
            else if (member == "GenericParam")
                clrMetadata.genericParam = new GenericParam[stream.read!uint];
            else if (member == "MethodSpec")
                clrMetadata.methodSpec = new MethodSpec[stream.read!uint];
            else if (member == "GenericParamConstraint")
                clrMetadata.genericParamConstraint = new GenericParamConstraint[stream.read!uint];
        }

        foreach (member; FieldNames!TableTokens)
        {
            if (member == "Module")
                clrMetadata.moduleDef = stream.read!(ModuleDef, 
                    "", ReadKind.Fixed, 2)
                (clrMetadata.moduleDef.length);
        }
    }

public:
    DOSHeader dosHeader;
    COFFHeader coffHeader;
    OptionalImage optionalImage;
    DataDirectory[] dataDirectories;
    Section[] sections;

    Cor20Header cor20Header;
    ClrMetadata clrMetadata;

    /**
    * Reads a PE file from the specified file path.
    *
    * Params:
    *    filePath = The path to the PE file to be read.
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

        pe.readClr();

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