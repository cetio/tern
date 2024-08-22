# Tern
<p align="center">
  <a href="https://code.dlang.org/packages/tern"> <img src="https://img.shields.io/dub/v/tern"/> </a>
  <a href="https://github.com/cetio/tern"><img src="https://img.shields.io/github/repo-size/cetio/tern.svg" alt="GitHub repo size"/></a>
  <a href="https://github.com/cetio/tern"><img src="https://img.shields.io/github/languages/code-size/cetio/tern.svg" alt="GitHub code size"/></a>
  <a href="https://github.com/cetio/tern"><img src="https://img.shields.io/github/commit-activity/t/cetio/tern" alt="GitHub commits"/></a>
  <a href="https://raw.githubusercontent.com/cetio/tern/main/LICENSE.txt"><img src="https://img.shields.io/github/license/cetio/tern.svg" alt="GitHub repo license"/></a>
</p>

## FUNCTIONAL

- `tern.algorithm` algorithms, lazy ranges, and common range functionality.
  - `tern.algorithm.iteration`
  - `tern.algorithm.lazy_filter`
  - `tern.algorithm.lazy_map`
  - `tern.algorithm.lazy_substitute`
  - `tern.algorithm.mutation`
  - `tern.algorithm.searching`
- `tern.functional` various implementations for functional programming and iteration.
  - `plane` for arbitrary iteration with a predicate across a range.
  - `tap` for maintaining local purity and calling an impure function.
  - `juxt` call multiple functions async.
  - `denature` flatten function to remove args.
  - `renature` unflatten function to add args.
  - provides support for invoking lambdas dynamically based on arguments, ie: `(ref index, element, sum) => ...` and everything in-between.

## COMPTIME

- `tern.accessors` automatic accessor/property generation with support for any flags that are present.
- `tern.object` for arbitrary and specialized fast interaction with objects.
- `tern.meta` tiny algorithms and comparisons for `AliasSeq`.
- `tern.traits` expansion on `std.traits`.
  - more comparisons, better comparisons, and generation of signatures of type members.

- `tern.typecons.automem`
  - `tern.typecons.automem.Unique` scope-disposed non-reassignable/copyable pointer.
  - `tern.typecons.automem.Scoped` scope-disposed reassignable/copyable pointer.
  - `tern.typecons.automem.RefCounted` ref-counted reassignable/copyable pointer.
  - `tern.typecons.automem.Tracked` cache -> free based pointer.
  - `tern.typecons.automem.Disposable` scope-disposed type wrapper.
- `tern.typecons.common`
  - `tern.typecons.common.BlackHole`
  - `tern.typecons.common.WhiteHole`
  - `tern.typecons.common.Singleton`
  - `tern.typecons.common.Enumerable` copy-based un-immutable range wrapper.
  - `tern.typecons.common.series` index-by-slice based array which uses `[]` for historical reference and `()` for element indexing.
- `tern.typecons.security`
  - `tern.typecons.security.Atomic`
  - `tern.typecons.security.Blind` timing/power attack protected type wrapper.
- `tern.typecons.variant`
  - `tern.typecons.variant.VadType` for partial mocking and arbitrary field modification/addition.

## THREADING

- `tern.atomic` improved atomic operations, built upon `core.atomic`.
- `tern.concurrency` arbitrary threaded function execution and parallel processing
  - `await` and `async` for calling a function on a new thread.
- `tern.typecons.security.Atomic` for wrapping any type to be thread-safe (not accounting for statics.)
- `tern.experimental.monitor` creating and deleting object monitors.
- `tern.functional` 
  - `juxt` call multiple functions async.
  - `denature` flatten function to remove args.

## MEMORY

- `tern.experimental.constexpr` data segment allocated type wrapper.
- `tern.experimental.ds_allocator` data segment allocator.
- `tern.experimental.heap_allocator` fast slab-based heap allocator with optional thread-safety.
- `tern.stream.memory_stream` simple, fast memory stream.
- `tern.memory` various general-purpose memory utilities.
  - hardware-accelerated `copy` and `memset`.
- `tern.serialization` serialization for arbitrarily typed data.
- `tern.object` specialized storing, loading, and more.

## DATA

- `tern.stream` various different performant stream implementations.
  - `tern.stream.atomic_stream`
  - `tern.stream.binary_stream`
  - `tern.stream.memory_stream`
  - `tern.stream.file_stream`
- `tern.algorithm` algorithms, lazy ranges, and common range functionality
  - `tern.algorithm.iteration`
  - `tern.algorithm.lazy_filter`
  - `tern.algorithm.lazy_map`
  - `tern.algorithm.lazy_substitute`
  - `tern.algorithm.mutation`
  - `tern.algorithm.searching`
- `tern.string` algorithms and utilities for working with strings.
- `tern.serialization` serialization for arbitrarily typed data.
- `tern.state` enum flags and mask interactions.
- `tern.os` Various system format implementations.
  - `tern.os.pe` Portable Executable format.
  - `tern.os.elf` ELF format.
  - `tern.os.hresult` Windows HResult.
  - `tern.os.process` Windows processes.

## CRYPTO

- `tern.digest` digest implementation and crypto algorithms.
  - `tern.digest.adler32`
  - `tern.digest.anura`
    - `Anura256` `Anura1024`
  - `tern.digest.berus`
  - `tern.digest.chacha20`
  - `tern.digest.cipher` imports all ciphers.
  - `tern.digest.circe`
  - `tern.digest.cityhash`
  - `tern.digest.crc32`
  - `tern.digest.djb2`
  - `tern.digest.elfhash`
  - `tern.digest.fnv1`
  - `tern.digest.gimli`
  - `tern.digest.hash` implements all hashes.
  - `tern.digest.hight`
  - `tern.digest.md5`
  - `tern.digest.mira`
    - `Mira256` `Mira512`
  - `tern.digest.murmurhash`
  - `tern.digest.pira`
  - `tern.digest.rc4`
  - `tern.digest.ripemd`
  - `tern.digest.salsa20`
  - `tern.digest.sha`
    - `SHA1` `SHA256` `SHA512` `SHA224` `SHA384`
  - `tern.digest.superfasthash`
  - `tern.digest.tea`
    - `TEA` `XTEA` `XXTEA`
  - `tern.digest.xxhash`
- `tern.typecons.security.Blind` timing/power attack protected type wrapper.

## MISC

- `tern.experimental.assembly` assembly shenannigans and ABI support.
- `tern.legacy` outdated or deprecated features.
  - `tern.exception`
  - `tern.tensor`
  - `tern.matrix`
  - `tern.vector`
  - `tern.eval`
- `tern.integer` arbitrary sized integers.
- `tern.benchmark` configurable parameterized benchmarking with global benchmark keeping.