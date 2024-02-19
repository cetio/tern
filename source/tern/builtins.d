module tern.builtins;

public:
static:
void prefetch(bool RW, bool LOCALITY)(void* ptr)
{
    version(GDC)
        __builtin_prefetch(ptr, RW, LOCALITY);
    else version (LDC)
        llvm_prefetch(ptr, RW, LOCALITY, 1);
    else
        prefetch!(RW == 1, LOCALITY)(ptr);
}