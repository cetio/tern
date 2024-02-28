/// Access to creation and deletion of object monitors abstracted out by the runtime.
module tern.experimental.monitor;

import core.atomic, core.stdc.stdlib, core.stdc.string;
import core.sync.mutex;
import std.traits;
version (Windows)
{
    version (CRuntime_DigitalMars)
    {
        pragma(lib, "snn.lib");
    }
    import core.sys.windows.winbase /+: CRITICAL_SECTION, DeleteCriticalSection,
        EnterCriticalSection, InitializeCriticalSection, LeaveCriticalSection+/;
}

version (Windows)
{
    private alias Mutex = CRITICAL_SECTION;

    private alias initMutex = InitializeCriticalSection;
    private alias destroyMutex = DeleteCriticalSection;
    private alias lockMutex = EnterCriticalSection;
    private alias unlockMutex = LeaveCriticalSection;
}
else version (Posix)
{
    import core.sys.posix.pthread;

    private alias Mutex = pthread_mutex_t;
    private __gshared pthread_mutexattr_t gattr;

    private void initMutex(pthread_mutex_t* mtx)
    {
        pthread_mutex_init(mtx, &gattr) && assert(0);
    }

    private void destroyMutex(pthread_mutex_t* mtx)
    {
        pthread_mutex_destroy(mtx) && assert(0);
    }

    private void lockMutex(pthread_mutex_t* mtx)
    {
        pthread_mutex_lock(mtx) && assert(0);
    }

    private void unlockMutex(pthread_mutex_t* mtx)
    {
        pthread_mutex_unlock(mtx) && assert(0);
    }
}
else
{
    static assert(0, "Unsupported platform");
}

alias IMonitor = Object.Monitor;
alias DEvent = void delegate(Object);

private struct Monitor
{
public:
final:
    IMonitor impl; // for user-level monitors
    DEvent[] devt; // for internal monitors
    size_t refs; // reference count
    Mutex mtx;
}

private shared static core.sync.mutex.Mutex mutex;

shared static this()
{
    mutex = new shared core.sync.mutex.Mutex();
}

public:
static:
/** 
 * Creates a monitor for `val`.
 *
 * Params:
 *  val = Value to create a monitor for.
 *
 * Returns: 
 *  True if the monitor was successfully created.
 */
bool createMonitor(T)(ref T val)
    if (isAssignable!(T, Object))
{
    if (auto m = val.getMonitor() !is null)
        return m;

    Monitor* m = cast(Monitor*)calloc(Monitor.sizeof, 1);
    initMutex(&m.mtx);

    synchronized (mutex)
    {
        if (val.getMonitor() is null)
        {
            m.refs = 1;
            val.setMonitor(cast(shared)m);
            return true;
        }
        destroyMonitor(m);
        return false;
    }
}

/** 
 * Deletes the monitor `m`.
 *
 * Params:
 *  m = Pointer to the monitor to be deleted.
 */
void destroyMonitor(Monitor* m)
{
    destroyMutex(&m.mtx);
    free(m);
}

pure:
@property ref shared(Monitor*) monitor(T)(return scope T val)
    if (isAssignable!(T, Object))
{
    return *cast(shared Monitor**)&val.__monitor;
}

/** 
 * Gets the monitor of `val`.
 *
 * Params:
 *  val = Value to get the monitor of.
 *
 * Returns: 
 *  The monitor of `val`.
 */
shared(Monitor)* getMonitor(T)(T val)
    if (isAssignable!(T, Object))
{
    return atomicLoad!(MemoryOrder.acq)(val.monitor);
}

/** 
 * Sets the monitor of `val`.
 *
 * Params:
 *  val = Value to set the monitor of.
 *  m = The new monitor of `val`.
 */
void setMonitor(T)(T val, shared(Monitor)* m)
    if (isAssignable!(T, Object))
{
    atomicStore!(MemoryOrder.rel)(val.monitor, m);
}