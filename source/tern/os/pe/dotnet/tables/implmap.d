module tern.os.pe.dotnet.tables.implmap;

public enum ImplMapAttributes : ushort
{
    /// Indicates no name mangling was used.
    NoMangle = 0x0001,
    /// Indicates the character set was not specified.
    CharSetNotSpec = 0x0000,
    /// Indicates the character set used is ANSI.
    CharSetAnsi = 0x0002,
    /// Indicates the character set used is unicode.
    CharSetUnicode = 0x0004,
    /// Indicates the character set is determined by the runtime.
    CharSetAuto = 0x0006,
    /// Provides a mask for the character set.
    CharSetMask = 0x0006,
    /// Indicates best fit mapping behavior when converting Unicode characters to ANSI characters is determined
    /// by the runtime.
    BestFitUseAssem = 0x0000,
    /// Indicates best-fit mapping behavior when converting Unicode characters to ANSI characters is enabled.
    BestFitEnabled = 0x0010,
    /// Indicates best-fit mapping behavior when converting Unicode characters to ANSI characters is disabled.
    BestFitDisabled = 0x0020,
    /// Provides a mask for the best-fit behaviour.
    BestFitMask = 0x0030,
    /// Indicates the throw behaviour on an unmappable Unicode character is undefined.
    ThrowOnUnmappableCharUseAssem = 0x0000,
    /// Indicates the runtime will throw an exception on an unmappable Unicode character that is converted to an
    /// ANSI "?" character.
    ThrowOnUnmappableCharEnabled = 0x1000,
    /// Indicates the runtime will not throw an exception on an unmappable Unicode character that is converted to an
    /// ANSI "?" character.
    ThrowOnUnmappableCharDisabled = 0x2000,
    /// Provides a mask for the throw on unmappable behaviour.
    ThrowOnUnmappableCharMask = 0x3000,
    /// Indicates whether the callee calls the SetLastError Win32 API function before returning from the attributed
    /// method.
    SupportsLastError = 0x0040,
    /// Indicates P/Invoke will use the native calling convention appropriate to target windows platform.
    CallConvWinapi = 0x0100,
    /// Indicates P/Invoke will use the C calling convention.
    CallConvCdecl = 0x0200,
    /// Indicates P/Invoke will use the stdcall calling convention.
    CallConvStdcall = 0x0300,
    /// Indicates P/Invoke will use the thiscall calling convention.
    CallConvThiscall = 0x0400,
    /// Indicates P/Invoke will use the fastcall calling convention.
    CallConvFastcall = 0x0500,
    /// Provides a mask for the calling convention flags.
    CallConvMask = 0x0700,
}

public struct ImplMap
{
public:
final:
    ImplMapAttributes flags;
    int memberForwarded;
    int importName;
    int importScope;
}