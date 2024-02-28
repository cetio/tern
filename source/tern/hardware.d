/// Tools for getting hardware identifiers to validate device identity
module tern.hardware;

import tern.string;
import tern.digest;
import tern.digest.sha;
version (Windows)
{
    import std.windows.registry;
}
else version (linux)
{
    import std.process;
    import std.file;
    import std.stdio : lines;
}

version (X86)
{
    /// True if the current processor supports SIMD-128
    public enum supportsSIMD128 = __traits(compiles, { asm { vxorps XMM0, XMM0, XMM0; } });
    /// True if the current processor supports SIMD-256
    public enum supportsSIMD256 = __traits(compiles, { asm { vxorps YMM0, YMM0, YMM0; } });
    /// True if the current processor supports SIMD-512
    public enum supportsSIMD512 = __traits(compiles, { asm { vxorps ZMM0, ZMM0, ZMM0; } });
}

public:
static:
// This implementation is not fast, but neither are most hwid extractions \_( -.-)_/
version (Windows)
{    
    /// Retrieves the motherboard serial number. May fail and return null.
    string moboSerial()
    {
        try
        {
            Key hKey = Registry.localMachine.getKey(r"SYSTEM\HardwareConfig");
            return hKey.getValue("LastConfig").value_SZ.toLower()[1..$-1];
        }
        catch (RegistryException ex)
        {
            
        }

        try
        {
            Key hKey = Registry.users.getKey(r".DEFAULT\Software\Microsoft\Office\Common\ClientTelemetry");
            return hKey.getValue("MotherboardUUID").value_SZ.toLower()[1..$-1];
        }
        catch (RegistryException ex)
        {
            
        }

        try
        {
            Key hKey = Registry.currentUser.getKey(r"Software\Microsoft\Office\Common\ClientTelemetry");
            return hKey.getValue("MotherboardUUID").value_SZ.toLower()[1..$-1];
        }
        catch (RegistryException ex)
        {
            return null;
        }
    }

    /// Retrieves the monitor serial number. May fail and return null.
    string monitorSerial()
    {
        try
        {
            Key hKey = Registry.localMachine.getKey(r"SYSTEM\CurrentControlSet\Enum\DISPLAY\");
            hKey = hKey.keys[0];
            hKey = hKey.keys[0];
            hKey = hKey.keys[0];
            return digest!SHA1(cast(ubyte[])hKey.getValue("EDID").value_BINARY).toHexString().toLower();
        }
        catch (RegistryException ex)
        {
            return null;
        }
    }

    /// Retrieves the disk serial number. May fail and return null.
    string diskSerial()
    {
        try
        {
            Key hKey = Registry.localMachine.getKey(r"HARDWARE\DEVICEMAP\Scsi\Scsi Port 0\Scsi Bus 0\Target Id 0\Logical Unit Id 0");
            return hKey.getValue("SerialNumber").value_SZ.toLower();
        }
        catch (RegistryException ex)
        {

        }

        try
        {
            Key hKey = Registry.localMachine.getKey(r"HARDWARE\DESCRIPTION\System\MultifunctionAdapter\0\DiskController\0\DiskPeripheral");
            hKey = hKey.keys[0];
            return hKey.getValue("Identifier").value_SZ.toLower();
        }
        catch (RegistryException ex)
        {
            return null;
        }
    }

    /// Retrieves the sum SMBios serial number. May fail and return null.
    string biosSerial()
    {
        try
        {
            Key hKey = Registry.localMachine.getKey(r"SYSTEM\CurrentControlSet\Services\mssmbios\Data");
            byte[] table = hKey.getValue("AcpiData").value_BINARY~hKey.getValue("BiosData").value_BINARY~
                hKey.getValue("RegistersData").value_BINARY~hKey.getValue("SMBiosData").value_BINARY;
            return digest!SHA1(cast(ubyte[])table).toHexString().toLower();
        }
        catch (RegistryException ex)
        {
            return null;
        }
    }

    /// Summation of all serials hashes into a single hardware id. Could be an invalid identifier but unlikely.
    string hardwareId()
    {
        ubyte[] serials = cast(ubyte[])moboSerial()~cast(ubyte[])monitorSerial()~cast(ubyte[])diskSerial()~cast(ubyte[])biosSerial();
        return digest!SHA1(serials).toHexString().toLower();
    }
}
else version (linux)
{
    /// Retrieves the motherboard serial number. Will never return null.
    string moboSerial()
    {
        return readText(r"/sys/class/dmi/id/board_serial");
    }

    /// Retrieves the chassis serial number. Will never return null.
    string chassisSerial()
    {
        return readText(r"/sys/class/dmi/id/chassis_serial");
    }

    /// Retrieves the disk serial number. May fail and return null.
    string diskSerial()
    {
        auto process = pipeProcess("lsblk -no serial", Redirect.stdout);
        wait(process.pid);
        foreach (string line; lines(process.stdout))
        {
            if (!line.length) continue;
            return line;
        }
        return null;
    }

    /// Summation of all serials hashes into a single hardware id. Could be an invalid identifier but unlikely.
    string hardwareId()
    {
        ubyte[] serials = cast(ubyte[])moboSerial()~cast(ubyte[])chassisSerial()~cast(ubyte[])diskSerial();
        return digest!SHA1(serials).toHexString().toLower();
    }
}