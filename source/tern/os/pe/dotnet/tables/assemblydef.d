module tern.os.pe.dotnet.tables.assemblydef;

public enum AssemblyHashAlgorithm : uint
{
    None = 0x0000,
    Md2 = 0x8001,
    Md4 = 0x8002,
    Md5 = 0x8003,
    Sha1 = 0x8004,
    Mac = 0x8005,
    Ripemd = 0x8006,
    Ripemd160 = 0x8007,
    Ssl3Shamd5 = 0x8008,
    Hmac = 0x8009,
    Tls1Prf = 0x800A,
    HashReplaceOwf = 0x800B,
    Sha256 = 0x800C,
    Sha384 = 0x800D,
    Sha512 = 0x800E,
}

public enum AssemblyAttributes : uint
{
    /// The assembly holds the full (unhashed) public key.
    PublicKey = 0x0001,
    /// The assembly uses an unspecified processor architecture.
    ArchitectureNone = 0x0000,
    /// The assembly uses a neutral processor architecture.
    ArchitectureMsil = 0x0010,
    /// The assembly uses a x86 pe32 processor architecture.
    ArchitectureX86 = 0x0020,
    /// The assembly uses an itanium pe32+ processor architecture.
    ArchitectureIa64 = 0x0030,
    /// The assembly uses an AMD x64 pe32+ processor architecture.
    ArchitectureAmd64 = 0x0040,
    /// Bits describing the processor architecture.
    ArchitectureMask = 0x0070,
    /// Propagate PA flags to Assembly record.
    Specified = 0x0080,
    /// Bits describing the PA incl. Specified.
    FullMask = 0x00F0,
    /// From "DebuggableAttribute".
    EnableJitCompileTracking = 0x8000,
    /// From "DebuggableAttribute".
    DisableJitCompileOptimizer = 0x4000,
    /// The assembly can be retargeted (at runtime) to an assembly from a different publisher.
    Retargetable = 0x0100,
    /// The assembly contains .NET Framework code.
    ContentDefault         = 0x0000,
    /// The assembly contains Windows Runtime code.
    ContentWindowsRuntime  = 0x0200,
    /// Bits describing the content type.
    ContentMask            = 0x0E00
}

public struct AssemblyDef
{
public:
final:
    AssemblyHashAlgorithm hashAlgoId;
    ushort majorVersion;
    ushort minorVersion;
    ushort buildNumber;
    ushort revisionNumber;
    AssemblyAttributes flags;
    int publicKey;
    int name;
    int culture;
}