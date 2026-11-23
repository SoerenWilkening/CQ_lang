# CQ

CQ is C with one extra header. `CQ.h` adds four primitives, and everything else is the C you
already write. A value becomes quantum when `cq_theta` rotates it, and whatever is computed from a
quantum value is quantum as well: arithmetic, comparisons, branches, loops, function calls, pointers,
arrays and library calls. There is no quantum type, no qubit register and no gate list.

| Primitive | Meaning |
|---|---|
| `cq_theta(&x, a)` | Ry(a) on every qubit of `x`, in place. This is what makes `x` quantum. |
| `cq_phi(a)` | Multiplies the amplitude of the current branch by e^(ia). |
| `cq_measure(x)` | Measures `x` and returns the classical outcome. |
| `cq_invert_begin()` … `cq_invert_end()` | The enclosed code runs as its adjoint. |

This repository is the compiler: the driver `cqcc` and the LLVM pass `cq-lower` behind it. `cqcc`
compiles a C program with stock `clang -O1` and rewrites every operation on quantum data into
calls of a backend interface. A backend linked to the program builds the circuit from those calls
while the program runs, out of X, CX, CCX, rotations and measurement. Classical code stays ordinary
host code.

There is no "unsupported program" diagnostic. Every C program has a lowering.

## Example: Grover search with `math.h`

Find the byte whose square root is 12.

```c
#include <math.h>
#include <stdio.h>

int main(void) {
    unsigned char x = 0;
    cq_theta(&x, M_PI / 2);                 /* Ry(pi/2) on all 8 qubits: every x in 0..255 */

    int rounds = (int)floor(M_PI / 4 * sqrt(256.0));   /* classical math.h: 12 */
    for (int r = 0; r < rounds; r++) {
        if (sqrt(x) == 12.0)                /* oracle: math.h on a quantum value */
            cq_phi(M_PI);

        cq_invert_begin();                  /* diffusion: undo the preparation, */
        cq_theta(&x, M_PI / 2);
        cq_invert_end();
        if (x != 0)                         /* flip the sign of everything but 0, */
            cq_phi(M_PI);
        cq_theta(&x, M_PI / 2);             /* and prepare again */
    }

    printf("sqrt(%d) = 12\n", x);           /* prints a quantum value */
    return 0;
}
```

- `sqrt(x) == 12.0` is evaluated on all 256 values of `x` at once. The conversion, the square root
  and the comparison are computed into scratch qubits, `cq_phi` puts the phase on the comparison's
  result, and the scratch qubits are uncomputed.
- `rounds` never touches quantum data. It is ordinary classical C, and clang folds it to 12.
- `printf` receives a quantum argument. Output cannot happen inside a superposition, so the call is
  deferred: at the end of the run `x` is measured and the line is printed. A `printf` inside
  `if (x > 100) { … }` is deferred the same way and printed only when the branch is measured as
  taken.
- The program prints `sqrt(144) = 12` with probability 0.9999.

```sh
cqcc -S grover.c -o grover.lowered.ll             # the lowered LLVM IR
cqcc -S --cq-check grover.c                       # also compare the lowering with the C program
cqcc grover.c -lmybackend -o grover               # an executable, linked with a backend
```

`CQ.h` is included automatically. `--cq-check` runs the lowered program and the C program on sampled
basis inputs and reports any difference. `examples/` has Grover and Dicke-state programs whose
problem size is a run-time argument.

## Installation

Requirements:

- x86-64 macOS. The compiler targets x86-64 only.
- LLVM and clang 19.1.7 (`brew install llvm@19`), CMake 3.20 or newer, Ninja, Python 3.

The specification is in `spec/`: `CQ.h`, the rules (`CONSTRUCTION_RULES.md`), the backend
interface (`BACKEND_ABI.md`) and the examples.

```sh
git clone https://github.com/SoerenWilkening/CQ_lang.git
cd CQ_lang
cmake -S . -B build -G Ninja
cmake --build build
ln -s "$PWD/driver/cqcc" /usr/local/bin/cqcc               # optional: cqcc on the PATH
```

An LLVM outside `/usr/local/opt/llvm@19` is named by `-DCQ_LLVM_PREFIX=<prefix>` at configure time
and by `CQ_LLVM_BIN=<prefix>/bin` when running `cqcc`. `cqcc --help` lists every option.

An executable needs a backend: a library that implements `spec/BACKEND_ABI.md`. This repository
contains none; the recommended one is described under "Recommended backend" below. `cqcc -S`,
`cqcc -c` and `--cq-check` work without one. A backend has to implement
the core gates, the memory bus, the tape and the integer operations. Floating point is optional
for it: see "Floating point from SoftFloat" below.

A backend is linked like any library: `-lmybackend` (with `-L<dir>` if it is not on the linker's
search path) or a path given to `--backend`. Built as a shared library, it is bound when the
program starts, so one executable runs against any backend installed under that name, such as a
simulator, a resource counter or hardware, with no relink. Built as an archive (`.a`), it is copied
into the executable.

## Recommended backend

[opcode_quantum_operations](https://github.com/SoerenWilkening/opcode_quantum_operations) is the
recommended backend. It implements the runtime, the memory bus, the tape and the integer operations
and turns each call into X, CNOT, CCX, Ry, controlled Ry, Rz and measurement on integer qubit indices. Floating
point comes from this repository's SoftFloat library. It needs a C11 compiler and CMake only.

```sh
git clone https://github.com/SoerenWilkening/opcode_quantum_operations.git
cmake -S opcode_quantum_operations -B opcode_quantum_operations/build \
      -DCMAKE_C_COMPILER=/usr/local/opt/llvm@19/bin/clang
cmake --build opcode_quantum_operations/build -j4
cmake --install opcode_quantum_operations/build --prefix /usr/local

cqcc prog.c -lcq_backend -lcq_gates_trace -o prog          # the backend, then a gate backend
CQ_TRACE=prog.trace ./prog                                 # writes the circuit as a trace
```

The last library on the line defines the seven gate operations. The backend ships three:

| Gate backend | What it does |
|---|---|
| `-lcq_gates_trace` | Simulates nothing and writes the circuit to the file named by `CQ_TRACE` (stdout without it). Every measurement returns 0. [qec-trace-viewer](https://github.com/SoerenWilkening/qec-trace-viewer) renders the trace: `python3 scripts/verify_view.py prog.trace -o prog.html`. |
| `-lcq_gates_replay` | Runs the circuit on classical bits and counts gates and depth. Rotations are not simulated. |
| `-lcq_gates_count` | Builds no circuit and counts gates, depth and qubits into the file named by `CQ_COUNT`. Every measurement returns 0. |

Your own simulator or hardware compiler replaces either one by defining the same seven functions.

## C coverage

### The language

The compiler works on LLVM IR, so coverage is by what clang can emit, not by syntax.

- **Types.** Every integer type including `_Bool`, `__int128` and `_BitInt`; `float`, `double`,
  `long double` and `_Float16`; `_Complex`; structs, unions, arrays, bit-fields and vectors.
- **Operators.** Integer and floating-point arithmetic, bitwise operations, shifts, comparisons and
  casts. Floating point follows IEEE 754 bit for bit, including rounding modes and the exception
  flags of `fenv.h`.
- **Control flow.** `if`, `?:`, `switch`, `goto`, every loop form, `break`, `continue`, recursion.
- **Functions.** Quantum arguments and results, function pointers, variadic functions.
- **Memory.** Pointers and pointer arithmetic, arrays indexed by a quantum value, `malloc` and
  `free`, `memcpy` and `memset`. A pointer may itself be quantum.
- **The rest.** `setjmp`/`longjmp`, atomics and `threads.h` (collapsed to one thread), `volatile`,
  inline assembly.

Some C constructs have no exact quantum counterpart. Each has one fixed meaning:

| C construct | What the program does |
|---|---|
| A loop or recursion whose exit depends on quantum data | Runs for a cutoff of K trips. K is 4 unless `CQ_K(function, k)` in the source or `-cq-k=function=k` or `-cq-k-default=k` on the command line says otherwise. |
| Output with a quantum argument or inside a quantum branch | Deferred to the end of the run, then measured and performed, in program order. |
| `exit` or `abort` inside a quantum branch | Sets a flag that is measured at the end of the run. |
| `cq_measure` inside a quantum branch | Measures unconditionally. |
| An allocation whose size is quantum | Bounded by K2 bytes (`CQ_K2(function, bytes)`, `-cq-k2=function=bytes`). |
| A call of a function with no body in the program | A host call. With a quantum argument it is deferred like output. |

### The standard library

Library functions are lowered from their own source. musl's C implementation is compiled to LLVM
IR, linked into the program and lowered like user code, so `cos(x)` on a quantum `x` is musl's
`cos`, argument reduction and polynomial included. This covers 483 functions of the C standard
library, each with quantum arguments (per function: `musl/libc_results.tsv`):

| Header | Functions |
|---|---|
| `math.h` | 171, in `float`, `double` and `long double` forms |
| `complex.h` | 66 |
| `stdio.h`, wide-character I/O | 67 |
| `string.h`, wide strings | 39 |
| `stdlib.h` | 41: conversions (`strtod`, `strtol`, `atoi`, …), `qsort`, `bsearch`, `div`, `abs`, `malloc` and `free`, `rand`, `getenv`, `atexit` |
| `ctype.h`, `wctype.h` | 32 |
| `threads.h` | 19 |
| multibyte and wide-character conversion | 17 |
| `fenv.h` | 11 |
| `time.h` | 11 |
| `locale.h`, collation | 6 |
| `signal.h` | 2 |
| `strerror` | 1 |

- `sqrt`, `fabs`, `floor`, `ceil`, `trunc`, `rint`, `round`, `fmin`, `fmax`, `copysign`, `fma` and
  `fmod` are single backend operations and need no library body.
- `sprintf`, `sscanf` and their relatives format and parse quantum data like any other function.
  Functions that write to a stream are deferred output (see the table above). Functions that read
  a stream are host calls.
- `malloc`, `calloc`, `realloc` and `free` are the compiler's own allocator.

`cqcc` takes library bodies from a bundle. The bundle in this repository holds `sin`, `pow`, `exp`,
`log`, `atan`, `atan2`, `floor`, `scalbn`, `logb`, `ilogb`, `memcmp`, the `sprintf` and `sscanf`
families and the complex multiply and divide helpers. The whole library is built once from a musl
checkout:

```sh
git clone https://git.musl-libc.org/git/musl
git -C musl checkout b1efda5b91735e33635376ca11c9b497a1c66e39
mkdir libc
python3 bundle/build.py --full --musl musl --out libc/libc.ll
echo '["libc.ll"]' > libc/manifest.json
export CQ_BUNDLE_MANIFEST="$PWD/libc/manifest.json"       # cqcc now links from the whole library
```

### Lowered libraries

By default a library function is lowered again in every program that calls it. A lowered library
is compiled once: its functions become an ordinary object or archive, and a program lowers only
its calls of them and links the library.

```sh
printf 'cos\nsin\nexp\n' > libm.roots                     # the functions the library exports
cqcc --cq-lib --cq-roots libm.roots -o libqm.a             # lower them once
cqcc prog.c --cq-roots libm.roots -L. -lqm -lmybackend     # prog's calls go to libqm.a
```

- The root list is one C function name per line. The same file is given to both commands.
  `bundle/roots/` has ready lists per header.
- `--cq-lib` takes the bodies of the roots from its input files, or from the bundle when no input
  defines them. Your own library works the same way: `cqcc --cq-lib --cq-roots my.roots my.c -o
  libmy.a`.
- A lowered library holds only quantum versions (`__cq_q_*`) and defines no C symbol. The original
  library is linked after it and provides every C function and global: for standard C functions that
  is the host C library, for your own library its ordinary build (`-lqmy -lmy`).
- Each function is exported once per arrangement of classical and quantum arguments: every
  arrangement for a function with at most 5 scalar arguments, and for a wider one the arrangements
  by class (pointers, integers, floating point, each class classical or quantum as a whole). A call
  takes the exported version with the fewest quantum arguments that covers its quantum ones, so a
  classical pointer or size stays classical.
- A call in a program with no quantum data at all is left as it is and runs the original function.
- In the program, a listed function is never lowered from source. A function that is not on the
  list is handled as before.
- The loop cutoff K is passed at every call, so one compiled library serves every K.
- The arrangements make a library larger and slower to build: the C standard library has 1,524
  exported versions for its 387 functions.

To lower standard library functions, `cqcc` needs their bodies: build the whole-library bundle
first (the five commands above, about 3 minutes) and keep `CQ_BUNDLE_MANIFEST` set. Then, for
example, all of `math.h`:

```sh
cqcc --cq-lib --cq-roots bundle/roots/math.roots -o libqm.a
cqcc prog.c --cq-roots bundle/roots/math.roots -L. -lqm -lmybackend
```

Lowering time and archive size per list, measured on one x86-64 Mac:

| Root list | Functions | Time | Archive |
|---|---|---|---|
| `math.roots` | 171 | 21 s | 13.7 MB |
| `time.roots` | 11 | 8 s | 8.5 MB |
| `stdlib.roots` | 32 | 9 s | 7.7 MB |
| `multibyte.roots` | 17 | 15 s | 19.5 MB |
| `string.roots` | 39 | 6 s | 5.3 MB |
| `ctype.roots` | 32 | 3 s | 0.6 MB |
| `locale.roots` | 6 | 3 s | 0.6 MB |
| `complex.roots` | 66 | 1 min 34 s | 4.5 MB |
| `stdio.roots` (the `sprintf` and `sscanf` families) | 13 | 18 s | 18.3 MB |

All nine lists together are the standard library as one archive, linked with one `-l`. Lower each
list on its own (one module per list) and combine the results, about 3 minutes in total:

```sh
for g in math complex string stdlib stdio ctype multibyte time locale; do
    cqcc --cq-lib --cq-roots bundle/roots/$g.roots -o libq_$g.a
done
libtool -static -o libqc.a libq_*.a              # 79 MB, one archive
cat bundle/roots/*.roots > libc.roots
cqcc prog.c --cq-roots libc.roots -L. -lqc -lmybackend
```

## C++ and Rust

The pass reads LLVM IR, not C, so a C++ or Rust program compiled to IR by its own compiler goes through the
same lowering. `cqcc` takes the `.ll` file; it does not run `clang++` or `rustc` itself yet.
[`experiments/cxx_rust/`](experiments/cxx_rust/) has the user surface for both (`cq.hpp`: overloads in place of
`_Generic`; `cq.rs`: a trait over the `cq_theta_*` functions), the build scripts and 40 one-function programs
per language, each run through the checker against its own unlowered program (`run.sh`, 40 samples, K = 8;
`results.txt`).

| | Programs | Pass the checker | Not lowered | Lowered, checker differs or times out | Not decided by the checker |
|---|---|---|---|---|---|
| C++ (clang++ 19, libc++, `-fno-exceptions`) | 40 | 26 | 3 | 8 | 3 |
| Rust 1.86 (`panic=abort`, std built from source) | 40 | 29 | 1 | 6 | 4 |

- **C++, passing:** templates, classes and operators, lambdas with `<algorithm>`, `std::vector` (also indexed by
  a quantum value and grown under a quantum condition), `std::string`, a `std::map` lookup with a quantum key,
  `unique_ptr` and `shared_ptr`, `optional` and `variant`, `dynamic_cast`, a coroutine, member pointers, `new`
  under a quantum condition, `std::complex`, and `cq_invert` with phases.
- **Rust, passing:** generics, iterator chains, `sort_unstable`, `binary_search`, enums and `match`, `Option`
  and `Result` with `?`, `Box`, `Rc<RefCell>`, boxed closures, `Vec`, `String`, `VecDeque`, `BinaryHeap`,
  `async`, `u128`, the checked and saturating integer operations, and a panic under a quantum condition.
- **Libraries.** Most of libc++ is headers, so its code is compiled into the program's module and lowered with
  it; `operator new` and `delete` are defined over `malloc` and `free` in `cq.hpp`. Rust's `core`, `alloc` and
  `std` are built from source with every panic an immediate abort (`build_std.sh`) and linked into the
  program's module by fat LTO, so a panic is the `abort` row of the table above.
- **Not lowered.** C++ exceptions: `invoke`, `landingpad` and `resume` are an internal error of the pass, so
  the three programs that throw compile only without them. Rust's float-to-integer `as` casts
  (`llvm.fptosi.sat`, `llvm.fptoui.sat`) are an internal error with a quantum operand.
- **Wrong or open.** A virtual call or `dyn Trait` call made in a loop returns a wrong result; the same
  program in C with a table of function pointers fails the same way. Iterating a `std::map`, `std::string`
  concatenation and C++ multiple inheritance also differ from the C++ program. Four programs differ only in
  the kept flag of a loop cutoff. `std::function`, a recursive tree sum and `format!` did not finish within 5
  minutes. The checker could not decide `std::unordered_map`, `BTreeMap`, `HashMap`, `Mutex`, `iostream` and
  `std::sort`.

## Floating point from SoftFloat

A lowered program calls one backend operation per floating-point instruction (`fadd`, `fmul`,
`sqrt`, a compare, a conversion). A backend does not have to implement any of them. `softfloat/`
holds Berkeley SoftFloat 3e, which computes IEEE arithmetic with integer operations only, and the
compiler lowers it into a library that defines every floating-point operation in terms of the
integer ones.

```sh
softfloat/build.sh gen
softfloat/build.sh lib                             # softfloat/build/libqsoftfloat.a
softfloat/build.sh lib softfloat/cqsf_f80.roots    # softfloat/build/libqsoftfloat_f80.a (long double)
cqcc prog.c -lmybackend -o prog                    # cqcc links both archives when they exist
```

- The library covers `float`, `double`, `_Float16`, `__bf16` and `long double`: arithmetic, `sqrt`,
  `fma`, compares, rounding, and the conversions between floating-point widths and to and from
  integers (8 to 64 bits, `__int128` and `_BitInt` widths; the generator lists which), with every
  rounding mode and the exception flags.
- It is optional. `cqcc --no-softfloat`, or simply not building it, leaves the floating-point
  operations to the backend, which must then implement them itself. With it, a backend implements no
  floating-point template at all, `fneg`, `select` and `bitcast` included; at float widths it sees only
  `cqrt_alloc`/`cqrt_copy` (and a program's own `cqrt_ry`/`cqrt_measure`) as same-width bit registers. A backend may also implement
  only some: an operation the backend defines is the backend's, the library supplies the rest.
- Results match x86 hardware bit for bit, as the C standard library coverage above assumes.

## Lowering times

Time spent in the lowering, on one x86-64 Mac:

| What | Functions | Time | Result |
|---|---|---|---|
| The C standard library, all nine root lists | 387 | 3 min | `libqc.a`, 79 MB |
| SoftFloat, `float`, `double`, `_Float16`, `__bf16` | 673 | 4 min | `libqsoftfloat.a`, 57.4 MB |
| SoftFloat, `long double` | 182 | 1 min 15 s | `libqsoftfloat_f80.a`, 17.8 MB |

## Experiments on existing C projects

[`experiments/`](experiments/) lowers existing libraries unchanged (C, and one in C++), as lowered libraries (`cqcc --cq-lib`)
that link against the precompiled C standard library and SoftFloat. Nothing in a project is rewritten
and the standard library is not recompiled per project. Sources, builds and lowered archives are not
in the repository; each project's `build_lib.sh` fetches and builds them.

Every function is also lowered on its own, under every arrangement of classical and quantum arguments
a library exports and with its callees as calls (`experiments/per_function.sh`), so one failure does
not hide another:

| Project | Functions | Lower on their own | Time | Notes |
|---|---|---|---|---|
| C standard library (musl) | 387 | 387, as the lowered library | 3 min | 1,524 exported versions |
| SoftFloat (the float templates) | 855 | 855, as two lowered libraries | 5 min | |
| GSL 2.8 | 55 sub-libraries | all 55 as lowered libraries | 35 min | 2.1 GB of archives; `specfunc` takes 6 min 54 s |
| SQLite 3 (core) | 1,542 | 1,542 | 12 min | 5 take more than 2 minutes; `sqlite3VdbeExec`, the bytecode interpreter, takes 95 s on its own |
| GLPK 5.0 (without the two minisat files) | 1,256 | 1,256 | 4 min | `_glp_zlib_inflate` takes 19 s |
| GMP 6.3.0 (generic C) | 650 | 650 | 2 min | `__gmpn_div_q` takes 10 s |
| [ABC](https://github.com/maksimKorzh/abc), a chess engine | 37 | 37 | 2 s | |
| [Game of Life](https://github.com/bluekeybo/GameOfLife) | 7 | 7 | 1 s | |
| [TinyEMU](https://github.com/dearchap/tinyemu) 2018-09-23, a RISC-V system emulator | 581 | 581, as four lowered libraries | 4 min | the 128-bit RISC-V interpreter takes 44 s on its own |
| [TinyCC](https://github.com/TinyCC/tinycc) 0.9.28rc, a C compiler | 276 | 276, as one lowered library | 3 min | `tcc_relocate_ex` takes 25 s on its own |
| [Stockfish](https://github.com/official-stockfish/Stockfish) 17, a chess engine in C++ | 707 | 707, as one lowered library | 2 min 30 s | the library build takes 2 min 8 s |

The times are for the whole project on one x86-64 Mac with the current pass: the libraries as built, the
other projects as the sweep over their functions, six at a time with a limit of 2 minutes per function.
The functions over that limit were last built with an earlier pass.

"Lowers" means the pass produced a module that passes its structural verifier. The lowered
libraries are not checked against the C programs: the checker runs programs, and the reduced cases
under `experiments/repro-round*/` are what it has run. Two of them are known faults:
`repro-round8/asrt5.c` (a wrong result: an assert on a classical condition in the body of a loop with
a quantum exit tested at its header) and `repro-round8/exitdead_leak.c` (a rail left live at exit).
A third is in SoftFloat: `fma` with only some operands quantum lowers to a version that reads an
invalid register (`experiments/arrangements/partial/fma_q1.linked.ll`); no float template calls it.

TinyEMU (`experiments/tinyemu/`: `build.sh`, then `build_lib.sh`) is the whole emulator without SDL and
the network filesystem: the RISC-V CPU at 32, 64 and 128 bits, its software floating point, the PC and
virtio devices and the SLIRP network stack. Its sources are unchanged; `compat/` supplies the Linux
headers macOS lacks. It is lowered as four libraries, one per RISC-V CPU width and one for the rest,
which call each other through `--cq-ext-roots`; a program (`drv.c`, one `add_sf64` on a quantum operand)
links them with TinyEMU's ordinary build, the lowered C library and the backend, and runs. Three softfp
functions (`add_sf64` in every rounding mode, `mul_sf32`, `sqrt_sf32`) pass the checker against the C
program on about 2,300 samples each (`spot.c`). The POSIX functions and system calls TinyEMU calls
outside the C library are effect entries (rule 16), classical calls the backend performs; with a
quantum argument the backend defers them and the program reads 0 as their result. `POSIX.md` has the
details.

TinyCC (`experiments/tinycc/`: `build.sh`, then `build_lib.sh`) is the compiler as its Makefile's one-file build
(`ONE_SOURCE`) for the native x86-64 Mach-O target, without its runtime library `lib/` (assembly). Its 276
functions lower on their own, and it lowers as one library (37 exported roots, 80 MB, 3 to 6 minutes, 1.7 GB at
most). A program (`drv.c`, `tcc_basename` on an 8-character path with one quantum character) links it with
TinyCC's ordinary build, the lowered C library and the backend. Its run does not get through the function: at
the default cutoff K = 4 the `strlen` loop over the path is cut after 4 trips and the shot ends there (52
gates), and at K = 16 the pointer walking back from the end is a quantum address of 46 bits, above the
backend's limit of 16. Three functions pass the checker against the C program (`spot.c`, about 2,300 samples
each): `btype_size`, `pstrcat` and `tcc_basename`, the last with one character of the path quantum and never the
terminator. `tcc_basename` first returned 0 where C returns 6: a pointer read after a loop with a quantum exit
kept the last trip's address, a fault older than this experiment and fixed with it. The other 273 functions are
only shown to lower, and compiling a program whose source text is quantum (`tcc_compile_string`) was not run.

Stockfish (`experiments/stockfish/`: `build.sh`, then `build_lib.sh`) is the engine at tag `sf_17` with the
flags of its Makefile's `general-64` target: no SIMD, `-fno-exceptions`, the network files not embedded. Its
sources are unchanged. The one module has 707 functions and no instruction a C program does not also produce.
All 707 lower on their own under every arrangement a library exports, and it lowers as one library (214
exported roots, 109 MB, 2 min 8 s). One function, `Tablebases::rank_root_moves`, first hit an internal error:
its `{ i64, i32 }` result packs several fields into the `i64`; that is fixed (`repro-round9/aggret_packed_leaf.c`).
Five programs (`spot.cpp`: queen attacks from a quantum square, `Position::pseudo_legal`, `see_ge`,
`attackers_to` and `UCIEngine::to_cp` on a quantum argument) link with the lowered library, Stockfish's
ordinary build, the lowered C library and the replay backend. None of their runs finished within 10 minutes,
so no Stockfish function has been checked against the C++ program: it is shown to lower and to link, not to
compute the right result.

A function whose body is in the program is lowered once per mix of classical and quantum arguments
it is called with. ABC and Game of Life were also lowered that way, one generated program per mix
except all-classical (`experiments/mask_sweep.sh`, run before the library arrangements existed): ABC
171 of 171 (`encode_move`, 7 arguments, 127 of them), Game of Life 79 of 79. Each needed one source
change. ABC's argument-less functions are declared `f()`,
which C17 reads as unprototyped; they now say `(void)`. Game of Life's display loop `while (1)` has no
exit; it is now a loop of 1000 generations.

Gate counts come from the recommended backend's counting gate backend (`-lcq_gates_count`, results
in the file named by `CQ_COUNT`), which counts gates, depth and qubits without building a circuit.
The drivers in `experiments/gsl/easy/` call one GSL function from precompiled, all-quantum GSL with
one `double` built from two qubits, at the default loop cutoff 4. These numbers are preliminary:
they were taken on intermediate builds of the pass, before the argument arrangements (every argument
was passed as a quantum register), and are not validated.

| GSL call | Gates |
|---|---|
| `gsl_stats_max` | 0.86 M |
| `gsl_sort` (4 elements) | 3.6 M |
| `gsl_fft_complex_radix2_forward` (4 points) | 6.0 M |
| `cblas_ddot` | 9.3 M |
| `cblas_dgemm` | 10.9 M |
| `cblas_dgemv` | 15.6 M |
| `gsl_poly_solve_quadratic` | 16.7 M |
| `gsl_poly_eval` | 20.5 M |
| `gsl_hypot` | 22.0 M |
| `gsl_stats_mean` | 25.6 M |
| `gsl_pow_int` | 25.8 M |
| `gsl_fit_linear` | 65.4 M |
| `gsl_stats_correlation` | 113.3 M |
| `gsl_linalg_HH_svx` (2x2 solve) | 128.2 M |
| `gsl_stats_variance` | 130.3 M |
| `gsl_complex_mul`, then `gsl_complex_abs` | 159.8 M |
| `gsl_cdf_ugaussian_P` | 369.5 M |

Game of Life is counted from its kernel (`addPadding`, then `nextGen`) on a torus with the
sizes and the two arrays' addresses classical and the cells in superposition (`experiments/gol/life.c`):

| Board | Cells in superposition | Generations | Gates | of them CCX | Depth | Qubits |
|---|---|---|---|---|---|---|
| 3 x 3 | 1 | 1 | 2,161 | 294 | 819 | 83 |
| 3 x 3 | 9 | 1 | 7,471 | 2,016 | 1,795 | 315 |
| 3 x 3 | 9 | 2 | 14,847 | 4,032 | 3,587 | 473 |
| 8 x 8 | 64 | 1 | 52,941 | 14,336 | 12,730 | 1,675 |
| 8 x 8 | 64 | 10 | 523,605 | 143,360 | 127,273 | 10,387 |
| 8 x 8 | 64 | 100 | 5,230,245 | 1,433,600 | 1,272,703 | 97,507 |
| 8 x 8 | 64 | 1,000 | 52,296,645 | 14,336,000 | 12,727,003 | 968,707 |
| 32 x 32 | 1,024 | 100 | 83,595,045 | 22,937,600 | 20,371,903 | 1,470,307 |

Every cell costs 224 CCX per generation. The qubit count grows with the generations (about 15 per cell
and generation) because nothing uncomputes a generation's overwritten cells.

Not counted yet: LU, Cholesky, Jacobi, the symmetric eigensolver and interpolation stop in the
backend, because a memory read inside a loop with a quantum exit gets an address the backend treats
as 61 to 64 quantum bits (its limit is 16). Gauss-Legendre integration and GMP's `mpn_fib2_ui`
lower and run but did not finish counting in 10 minutes.

`cqcc -cq-no-output` replaces calls to the `printf` family, `puts`, `fwrite` and `perror` on declared
streams by their error return, so a library's error reporting does not enter the count. It is meant
for building such a library, not the C standard library.

## How the lowering works

1. **One module.** `clang -O1` compiles each translation unit. The units and the library bodies
   they need are linked into one LLVM module, and the pass runs once over it.
2. **Taint.** A value is quantum exactly when it derives from a `cq_theta` result by data flow,
   through memory, calls and pointers. A module with nothing quantum comes out byte-identical.
3. **Templates.** A quantum value is an `i32` handle to a backend register. Each instruction on
   quantum operands becomes one call of a reversible template that computes its result into a
   fresh register. When the result is no longer needed, the template's inverse (`_unc`) clears the
   register and it is freed. The oracle of the example becomes:

   ```llvm
   %9  = call i32 @cq_template_uitofp_i8_to_f64(i32 %8)                        ; (double)x
   %10 = call i32 @cq_template_sqrt_f64(i32 %9)                                ; sqrt
   %11 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %10, double 1.200000e+01)   ; == 12.0, one flag qubit
   call void @cqrt_rz_i1(i32 %11, double 0x400921FB54442D18)                   ; cq_phi(pi): a phase on the flag
   call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %11, i32 %10, double 1.200000e+01)
   call void @cqrt_free(i32 %11)
   call void @cq_template_sqrt_f64_unc(i32 %10, i32 %9)
   call void @cqrt_free(i32 %10)
   call void @cq_template_uitofp_i8_to_f64_unc(i32 %9, i32 %8)
   call void @cqrt_free(i32 %9)
   ```

4. **Control flow.** A branch on a quantum condition becomes a flag qubit. The pure computations
   of both arms run unconditionally and are merged by a select on the flag. Phases, rotations and
   stores are controlled by it. A branch on a classical condition stays a real branch.
5. **Calls.** A function is cloned once per pattern of quantum arguments, together with its
   inverse and its controlled form.
6. **Memory.** All memory is one bus of byte cells indexed by the x86-64 address. An access at a
   classical address touches one cell. An access at a quantum address is one quantum-addressed
   read or write.
7. **Self-check.** The pass verifies the structure of its own output on every run: every register
   is uncomputed before it is freed, no quantum value reaches a classical instruction, and no
   measurement appears that the program did not write.

The rules are specified in `spec/CONSTRUCTION_RULES.md`.
