# C standard library coverage of the CQ_spec corpus

Measured 2026-10-20 and re-measured 2026-10-27 against the 192-example corpus with `_tools/libc_census.py <musl>` and
`_tools/libc_census.py <musl> --arch-cq` (`--arch-cq` builds musl with `_tools/musl_arch_cq/` in place of the asm arch
primitives; the 2026-10-27 run reports 51 covered intrinsics measured from the examples). The census counts an intrinsic as covered only when it occurs
in some `examples/*/*.O1.ll` (constrained FP intrinsics by the 80–82 template grammar when the plain op does).
Not part of the spec: `examples/` and `CQ.h` are the spec; this file records a measurement.

## Method

Every C-standard-library translation unit of **musl** (commit `b1efda5`, 2026-10-05) is compiled with
`clang 19 -O1 -emit-llvm -target x86_64-linux-musl` (musl's own flags: `-std=c99 -nostdinc -ffreestanding
-frounding-math -fno-strict-aliasing`). A TU is **clean** when every IR construct it contains (instruction
kind, `llvm.*` intrinsic, inline asm) has an example in `examples/`. The directories are musl's
`ctype errno exit fenv locale malloc multibyte prng search setjmp signal stdio stdlib string time env math
complex` plus the C11 `threads.h` wrappers in `thread` (`thrd_* mtx_* cnd_* tss_* call_once`); the POSIX-only
directories and the pthread implementation (network, process, the rest of `thread`, ...) are not part of the C
standard and are not counted.

Coverage of a construct means a lowering target exists for it, not that a compiler implements it. The examples
themselves are checked by their traces and by the basis-sample checker (`_tools/sample_check.py`); a compiler is
accepted by matching them under CONSTRUCTION_RULES.md §6.

## Result: 752 of 752 TUs (100 %) in the library bundle build (CQ arch headers)

The bundle build is the one the library is made with (owner, 2026-10-20), so the C standard library is fully
covered. The stock x86-64 asm build, which the bundle never uses, reads 666 of 752; its table follows.

| directory | clean / TUs | the rest |
|---|---|---|
| complex | 68 / 68 | |
| fenv | 7 / 7 | |
| prng | 11 / 11 | |
| search | 8 / 8 | |
| setjmp | 2 / 2 | |
| math | 231 / 232 | `fma.c`: `bsr` inline asm |
| string | 74 / 74 | |
| stdlib | 21 / 22 | `qsort.c`: `bsf` inline asm |
| ctype | 36 / 37 | TLS (locale pointer) |
| malloc | 8 / 9 | syscall (`mmap`) |
| stdio | 87 / 116 | syscalls 22, TLS 14, atomics 8 |
| signal | 28 / 38 | syscalls 10, TLS 1, atomic 1 |
| time | 26 / 40 | syscalls 11, TLS 3, atomics 3, trap 1 |
| multibyte | 14 / 20 | TLS 6 |
| locale | 16 / 26 | TLS 10, atomic 1 |
| exit | 5 / 8 | syscalls 3, TLS 2, traps 2, atomic 1 |
| env | 7 / 11 | syscalls 2, TLS 2, traps 3, barrier 1 |
| errno | 0 / 2 | TLS (`__errno_location`) |
| thread (C11) | 17 / 21 | atomics 2, syscall 1, TLS 1 |
| **total, stock asm** | **666 / 752** | 86 TUs, all inline asm |
| **total, `--arch-cq`** | **752 / 752** | — |

The per-directory rows are the stock build; with `--arch-cq` every directory is clean (measured 2026-10-27).

The 86 stock-build non-clean TUs all carry inline asm and nothing else uncovered: `syscall` 50, thread-local storage
(`%fs:`) 42, x86 atomics (`lock`/`xchg`) 16, traps (`hlt`/`ud2`) 6, `bsf`/`bsr` 2 (an empty asm with a memory clobber is
a compiler fence and is not counted). That is the
kernel/CPU boundary: it stays classical and is where the tape (47, 99, 102) hands effects over. The two
`bsf`/`bsr` cases are the only asm that computes a value; they are `llvm.cttz`/`llvm.ctlz` in disguise (56).

## Which examples closed which construct

| construct (first seen in the census) | example |
|---|---|
| quantum pointers: select/phi of pointers, deref of a multi-origin pointer | 84, 85 |
| pointer difference and comparison, pointer-carried loop, `int **`, stored pointers | 86, 87, 88 |
| `ptrtoint` / `inttoptr` | 89 |
| `llvm.memcpy` / `memset` with a tainted length | 90 |
| `malloc` / `realloc` / `free` with a quantum size, allocation in a loop | 91 |
| `llvm.*.with.overflow`, `llvm.*.sat` | 92 |
| `i128` | 93 |
| `cmpxchg`, `atomicrmw`, `fence`, atomic load/store | 94 |
| `va_start` / `va_arg` | 95 |
| indirect call through a classical pointer, through a quantum pointer | 96, 97 |
| recursion with quantum depth | 98 |
| byte output | 99 |
| `fesetenv(FE_DFL_ENV)`, narrow exception masks, constrained op in a quantum arm, quantum `fesetround` | 100 |
| `setjmp` / `longjmp` | 101 |
| `raise`, `signal`, `remove` under a quantum predicate | 102 |
| `<2 x float>` (the x86-64 ABI of `float _Complex`) | 103 |
| `llvm.is.fpclass` | 104 |
| `llvm.ptrmask` | 105 |
| `pthread_create` / `join`, mutexes (single-thread collapse) | 106 |
| union of pointer and integer: punning on values and through a slot | 107 |
| `llvm.cttz`, `llvm.trap` under a quantum predicate, a thread-local slot (the CQ arch primitives) | 108 |
| `llvm.smin`, `llvm.bswap`, `llvm.usub.sat`, `llvm.va_copy`, `llvm.stacksave`/`stackrestore` | 109 |
| C23 `_BitInt(N)` (templates per width N on demand) | 110 |
| C23 `_Float16` (`half`, promoted through `fpext`/`fptrunc`) | 111 |
| `llvm.uadd`/`usub.with.overflow`, `llvm.fshr` (LLVM libc's libm) | 112 |

## What the asm boundary is, and the intended library build

Every asm kind reduces to an existing example once it is spelled as IR, so the asm is a spelling problem of
the library build (like openlibm's `src/` vs `.S`), not a lowering gap:

| asm kind | model | lowering | TUs it alone explains |
|---|---|---|---|
| atomics, barriers | ordinary memory ops; a fence is nothing | 94 | 1 |
| TLS (`%fs:` thread pointer) | one thread: the TLS block is a global object | 67/71 | 30 cumulative |
| `bsf`/`bsr` | `cttz`/`ctlz` | 56 | 32 |
| traps | `abort` | 45 | 34 |
| `syscall` | a classical host call; quantum args or a quantum predicate make it a tape entry | 47/102 | the remaining 49 |

Threads (owner, 2026-10-20): reversibility needs a deterministic program, so pthread/`threads.h` code is lowered
under the **single-thread collapse** (Bennett.jl's stance): data-race-free fork/join gives the same result under
every schedule, and the sequential one is taken (106: `create` = a clone call, `join` = nothing, locks = no-ops).
Condition variables, barriers and busy-waits need a scheduler and stay out of scope. Multi-QPU placement is a
backend matter over the handle graph, not a lowering concern.

The musl build for the library bundle is `_tools/musl_arch_cq/` (owner, 2026-10-20): three headers replacing musl's
arch primitives by the builtin with the same contract — `atomic_arch.h` → `__atomic_*`, `__builtin_ctzll`/`clzll`,
`__builtin_trap`; `pthread_arch.h` → the address of one bundle-provided TLS object `__cq_tp` (one thread); `syscall_arch.h`
→ a bodiless `__cq_syscall(n, a1..a6)`. Measured with them: **752/752**; the single classical boundary is `__cq_syscall`,
a host call with classical arguments and a tape entry (102) under quantum control.

## openlibm (math.h, complex.h), measured earlier the same day

openlibm declares 192 `math.h` functions (171 C11 + 21 BSD extras) and 66 `complex.h` functions. With the
portable `src/` C (never the amd64 `.S` overrides) every one has a C body. A user call reaches the library only
when `clang -O1` leaves it a call: on x86-64, 93 `math.h` functions become `llvm.*` intrinsics and
`fmod`/`fmodf`/`fmodl` become `frem` (83). An intrinsic with a template in CONSTRUCTION_RULES.md §1.2 (`sqrt`,
`fabs`, `floor`, `ceil`, `trunc`, `rint`, `round`, `copysign`, `fmax`/`fmin`, `fma`) and `frem` lower to that
template. Every other math intrinsic (`llvm.sin`, `llvm.exp`, `llvm.pow`, …) is the call of the libm function of
the same name (rule 18). Those calls, the other 96 `math.h` functions, all 66 `complex.h` functions and the six
compiler-rt helpers `__{mul,div}{s,d,x}c3` are lifted from injected source (rule 18), or called as declared clones
of a linked lowered library (rule 27). The openlibm and LLVM libc figures in this file are from 2026-10-20 and
were not re-run on 2026-10-27 (no checkout on this host); the corpus has only grown since, so they cannot drop.

## Deferred: Rust and C++ (owner, 2026-10-20)

The pass is frontend-neutral; a Rust frontend is a crate declaring the same `extern "C"` `cq_*` symbols, a
C++ frontend is `CQ.h` inside `extern "C"`. Their standard libraries are compiled source like musl/openlibm.
No examples yet; the two IR constructs they add that the corpus lacks, to be pinned when the work starts:

1. `invoke` / `landingpad` / `resume` (C++ exceptions, Rust `panic=unwind`): 101's mechanism generalised — the
   callee's clone returns `{ result, unwound }`, the landing pad is the escaped continuation, destructors and
   drops are clones run under the unwound flag. With `-fno-exceptions` / `-C panic=abort` it reduces to 45.
2. The Rust scalar-pair ABI (`{ i64, i64 }` for small aggregates) and `sret` for large returns: width
   variants of 64/70.

Everything else (slices, `Option<&T>` niches, enums, bounds checks, vtables, generics, `Box`/`Vec`, closures,
atomics) maps onto examples 22, 45, 64, 84–97. Rust must be compiled at `-C opt-level=1` (its level 0 leaves
every alloca, like C `-O0`). A census of libc++ / Rust `core`+`alloc` with `_tools/libc_census.py`'s method is
the first measurement to take.

## C23 (measured 2026-10-20 with clang 19 `-std=c23`)

The pass sees IR, so C23 matters only where it adds a type or an intrinsic. Compiling C23 constructs with clang 19 shows:

| C23 addition | IR clang 19 emits | corpus |
|---|---|---|
| `_BitInt(N)` | integer ops at any width (`mul i100`, `add nsw i7`, `zext i64 to i100`), passed as `{ i64, i64 }` across calls | **110**: templates are generated per width N; the runtime's width set is a generator parameter, not a limit |
| `_Float16` | `half`, arithmetic promoted to `float` (`fpext half to float`, op, `fptrunc float to half`) | **111**: the two casts as width variants of 19 |
| `_Float128` | clang 19 does not accept the type in C; `__float128` gives `fp128` ops on Linux targets only (not on this Darwin host) | width variant of 19 (`fdiv fp128`); no example, nothing to trace here |
| `_Decimal32/64/128` | not implemented by clang | nothing to lower |
| `stdckdint.h` (`ckd_add`…) | `llvm.*.with.overflow` + `extractvalue` + `select` | 92 |
| `stdbit.h` | `__builtin_clzg`/`ctzg`/`popcountg` → `ctlz`/`cttz`/`ctpop` | 56, 108 (the header itself is the libc's; clang 19 ships none and musl b1efda5 has none yet) |
| `unreachable()`, `#embed`, `nullptr`, `typeof`, `constexpr`, `auto`, binary literals, attributes, enum underlying types | `unreachable` (45), constant data (29/50), or nothing | covered / none |

So C23 costs one rule (parametric widths, 110) and one width example (111): every other language addition folds into IR the corpus already pins.

**C23 library additions.** The standard adds about 40 `math.h` names (`exp10`, `exp2m1`, `exp10m1`, `log2p1`, `log10p1`,
`logp1`, `roundeven`, `fromfp`/`ufromfp`/`fromfpx`/`ufromfpx`, `llogb`, `nextup`/`nextdown`, the eight `fmaximum`/`fminimum`
variants, `compoundn`, `pown`, `powr`, `rootn`, `rsqrt`, `sinpi`…`atan2pi`, `totalorder`, `totalordermag`, `canonicalize`,
`getpayload`/`setpayload`/`setpayloadsig`) in three precisions each, 12 narrowing functions (`fadd`…`dsqrt`), `strfromd/f/l`,
`memalignment`, `free_sized`, `free_aligned_sized`, `memccpy`, `strdup`, `strndup`, `wcsdup`, `timegm`, `gmtime_r`,
`localtime_r` (the list is from the standard by hand; treat the count as approximate). None of them needs a new IR
construct: they are the same floating-point arithmetic, classification and string code as the C17 library. What is
missing is **source to lift**: musl b1efda5 implements only `exp10`, `memccpy`, `strdup`, `strndup`, `wcsdup`, `timegm`,
`gmtime_r`, `localtime_r` of them; openlibm none of the math names. glibc 2.41 implements most, but is GCC-only and
not usable as a clang-built bundle. glibc is not usable as a clang-built bundle; **LLVM libc** is: a freestanding C++17 libm built with clang,
and the most C23-complete one that exists.

### LLVM libc as the C23 math source (measured 2026-10-20, llvm-project 819e35c4, `_tools/llvmlibc_census.py`)

`libc/src/math/generic/*.cpp` compiled with `clang++ -std=c++17 -O1 -ffreestanding -fno-exceptions -fno-rtti`:

| | |
|---|---|
| TUs | 503; 454 compile on this host (the 48 others use `float128`/`bfloat16` types clang 19 cannot build on Darwin) |
| clean (every construct has an example) | **454 / 454** after example 112 (before it: 337; the only gaps were the `uadd`/`usub.with.overflow` and `fshr` variants) |
| C++-only constructs seen (`invoke`, `landingpad`, vtables) | none: the libm is plain scalar code, templates monomorphized |
| C23 math names with a body | **43 of 52** names, 95 of 138 (name, precision) pairs |
| missing names | `log2p1`, `log10p1`, `logp1`, `compoundn`, `pown`, `powr`, `rootn`, `atanpi`, `atan2pi` |
| missing precisions | `double` and `long double` of `exp2m1`, `exp10m1`, `rsqrt`, `sinpi`, `cospi`, `tanpi`, `acospi`; `long double` of `exp10`, `asinpi` |

So the C23 library coverage by available bodies is 43/52 of the new math names (plus the 8 non-math names musl has),
every one of them lowering with constructs already in the corpus. The bundle composition is: musl (CQ arch) for the
C library, openlibm or LLVM libc for the C17 libm, LLVM libc for the C23 names. Its C++ is a frontend matter only:
the pass sees the same IR; the C++ examples deferred above concern constructs this code does not use.
