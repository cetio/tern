module tern.os.process;

import core.sys.windows.windows;
import core.sys.windows.tlhelp32;
import core.sys.windows.winbase;
import core.sys.windows.psapi;
import std.datetime;
import std.string;
import std.conv;

version (Windows)
{
public struct Process
{
public:
final:
    void* handle;
    Module mainModule;
    alias mainModule this;
    /* void*[] handles;
    uint handleCount;
    string name;
    string path;
    string machine;
    string title;
    uint pid;
    uint sid;
    void* baseAddress;
    size_t virtualSize;
    bool responding;
    SysTime startTime;
    SysTime exitTime;
    uint exitCode;
    Duration totalProcessorTime;
    Duration userProcessorTime;
    Module[] modules; */

    // TODO: Use syscall for NtQueryInformationProcess
    /* void* handles()
    {
        if (handle == null) 
            throw new Exception("Process handle failed to open or is invalid.");

        void* snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPHANDLES, 0);
        if (snapshot == null)
        {
            throw new Exception("Snapshot handle failed to create or is invalid.");
            CloseHandle(snapshot);
        }

        void*[] handles;

        void* curr = Handle32First(snapshot, &handles);
        while (curr != null) 
        {
            handles ~= curr;
            hHandle = Handle32Next(snapshot, &handles);
        }

        CloseHandle(snapshot);
        return handles;
    } */

    /* Window[] windows()
    {
        static Window[] ret;
        ret = null;
        extern (Windows) static int enumWindowsProc(void* hWnd, long pid) nothrow
        {
            uint _pid;
            GetWindowThreadProcessId(hWnd, &_pid);

            if (_pid == pid) 
                ret ~= Window(hWnd);
            return true;
        }
        
        EnumWindows(&enumWindowsProc, pid);
        return ret;
    } */

    this(void* handle)
    {
        this.handle = handle;
        mainModule = modules[0];
    }

    Module[] modules()
    {
        Module[] ret;
        void*[1024] modules;
        uint bytesNeeded;

        if (EnumProcessModules(handle, &modules[0], modules.length * size_t.sizeof, &bytesNeeded)) 
        {
            foreach (i; 0..(bytesNeeded / size_t.sizeof)) 
            {
                MODULEINFO moduleInfo;
                if (GetModuleInformation(handle, modules[i], &moduleInfo, MODULEINFO.sizeof)) 
                {
                    wchar[MAX_PATH] _path;
                    if (GetModuleFileNameEx(handle, modules[i], _path.ptr, MAX_PATH) > 0) 
                    {
                        string path = _path.fromStringz.to!string;
                        string name = path[(path.lastIndexOf("\\") + 1)..$];
                        ret ~= Module(name, path, moduleInfo.lpBaseOfDll, moduleInfo.EntryPoint, moduleInfo.SizeOfImage);
                    }
                }
            }
        }

        return ret;
    }

static:
    Process current() => Process(OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, GetCurrentProcessId()));
}

public struct Window
{
public:
final:
    void* handle;
    /* string title; */
}

public struct Module
{
public:
final:
    string name;
    string path;
    void* baseAddress;
    void* entryPoint;
    size_t virtualSize;
}
}