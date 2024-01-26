# Caiman

[![Godwit](https://img.shields.io/badge/Godwit-orange?style=for-the-badge&logo=github)](https://github.com/cetio/godwit)

Library with various different utilities, mostly centered around filling comptime niches and improving parts of the standard library that I deem lacking.

## Formats

Currently only contains support for reading PE files, but is intended to add support for reading CS (csharp) and ELF files.

### Portexec

- PE Reading
    - Data directories (not implemented, but the structures are all present)
    - Optional headers
    - Standard headers

Depends on `caiman.memory.stream`.

## Mem

Various different memory utilities, including interacting with ABIs, shallow and deep cloning, stacks, and advanced data streams.

### ABI

Provides advanced support for interacting with types as you see fit, moving them as arguments or specifically into registers, with the ability to treat them as different types.

For example, this makes it possible to use a string as an `inout` parameter despite the actual parameter not being `inout`, `out`, or `ref`.

- All 32-128 bit registers
- 20 arguments
- Specifically designed for SystemV and MSABI (automatically picks by OS)
- Aliases for determining how a type is interacted with by the ABI
    - `isFloat`
    - `isSplit`
    - `isNative`
    - `isReference`
    - `isPaired`
    - `isOverflow`
- Types/aliases for specific type interactions
    - `FLOAT` (`float`)
    - `NATIVE` (`ptrdiff_t`)
    - `ARRAY` (`void[]`)
    - `REFERENCE` (`struct byte[33]`)
    - `INOUT`

Depends on `caiman.memory.ddup` and `caiman.traits`.

### DDUP

Deep and shallow cloning support.

- `dup` for shallow cloning any type
    - Will use the default object.dup() for arrays
        - This is heresy, because object.dup() isn't even actually a shallow clone, it's a deep clone; but we must try to retain portability.
- `ddup` for deep cloning any type, including arrays
    - Acts identically to object.dup() on arrays.
- `drip` for direct copying bytes from any type to another type.

No dependencies.

### Stack

Wrapper for stack arrays & interface for popping/pushing on arrays with support for LIFO and FILO.

- `push`, `pop`, and `peek` for interacting with arrays like stacks.
- Stack structures.

No dependencies.

### Stream

Very advanced data stream support, with optional reading, file access, endianness support, and much more.

- All of what you'd expect out of a data stream reader.
- Designed after C#'s `BinaryReader` and `BinaryWriter`
- Has ~~a ton of bloat~~ support for a lot of different options, like reading either a zero terminated or prefixed length string, different char sizes, endianness, optional reading, writing arrays, writing multiple elements from an array, etc.

No dependencies.

## Regex

Fast, highly efficient regex designed for both runtime and comptime.

- `regex` for all your comptime needs, including building `Regex` at comptime for using it later at runtime, or doing comptime regex operations.
- `Regex` for all your runtime needs.

Depends on `caiman.state`.

## Make

Binding generation for C# and header files.

- Generates binding only based on a root (package) module given, retrieving all publicly imported modules.
- Namespaces and classes based on root module name and file structure.
- Very advanced C# support, will try to perfectly match the native signatures and methodology.
- Creates all necessary structures/enums for binding.
- Relies on Godwit.Importer for C# and `caiman.traits.accessors` for all binding (or use the same export mangling)

Depends on `caiman.regex` and `caiman.traits`.

## State

Provides interface for enums and HResult, namely, adds full and very simple HResult support and different QOL flags interactions, such as `hasFlag` or `hasFlagMasked`.

- Checking for flag with or without mask.
- Setting flag with or without mask.
- Clearing or toggling mask/flag (with or without masks.)
- All common HResult values in the form of an enum and easy functions for checking states of any HResult.

Depends on `caiman.traits` very loosely (only for `@exempt` attribute.)

## Traits

Largely fills in any gaps of std.traits, while also providing some unique reflection.

- Aliases and templates for checking properties of types/functions.
    - `isIndirection(T)`
    - `isReference(T)`
    - `isValueType(T)`
    - `isExport(T)`
    - `isTemplate(T)`
    - `isModule(T)`
    - `isPackage(T)`
    - `isField(T)`
    - `hasParents(T)`
    - `wrapsIndirection(T)`
- Templates for getting data from types and modules.
    - `ElementType(T)`
    - `getImplements(T)`
    - `getFields(alias)`
    - `getFunctions(alias)`
    - `getTypes(alias)`
    - `getTemplates(alias)`
    - `getImports(alias)`
    - `indirections(T)`
- Ease of use template for automatically generating properties for all fields (unless marked `@exempt`) and their possible flag states (if enum type and enum is marked `@flags`.)
- `pragmatize` for stripping all special characters from a string and replacing all of the important ones with literals.

No dependencies.

## License

[MPL-2](/LICENSE.txt)
