module tern.os.syscall;

version (Windows)
{
import core.sys.windows.winbase;
import tern.os.pe;
import tern.os.process;
import tern.algorithm;

private:
static:
PE ntdll;
PE win32u;
void*[string] dispatch;

shared static this()
{
    Process proc = Process.current;
    size_t nti = proc.modules.indexOf!((x) => x.name == "ntdll.dll");
    size_t wui = proc.modules.indexOf!((x) => x.name == "win32u.dll");

    if (nti == -1 || wui == -1)
        throw new Exception("Failed to load modules!");

    ntdll = new PE(proc.modules[nti].path);
    win32u = new PE(proc.modules[wui].path);
}

/* void* createDispatch(string name)
{
    size_t nti = ntdll.optionalImage.exportTable.entries.indexOf((x) => x.name == name);
    size_t wui = win32u.optionalImage.exportTable.entries.indexOf((x) => x.name == name);
    
    if (nti == -1 || wui == -1)
        throw new Exception("Unknown function '"~name~"' was attempted to be called!");

    ExportEntry entry = nti == -1 ? win32u.optionalImage.exportTable.entries[wui] : ntdll.optionalImage.exportTable.entries[nti];

    // IDEAS:

    // 1. Step through code to nop out the final syscall and then call the function, we then extract EAX.
    // This is, to my knowledge, the best way we can effectively get the id no matter the conditions, but
    // will also trigger any hooks that may be present.

    // 2. Step through the code removing any potential hooks that will execute arbitrary code and then extract EAX.
    // This will not trigger hooks and should generally work, unless a special routing hook has been set up that is required
    // to be called to properly evaluate EAX.
    
} */

public:
}