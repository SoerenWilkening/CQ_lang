# CQ user manual

How to write, compile, check and run CQ programs. [`../README.md`](../README.md) has the
installation and the backend; [`EXPERIMENTS.md`](EXPERIMENTS.md) has the measurements on existing
projects; [`../spec/CONSTRUCTION_RULES.md`](../spec/CONSTRUCTION_RULES.md) is the normative
definition of what the compiler emits. [`../llms.txt`](../llms.txt) is a one-page version of this
manual for AI assistants.

Contents: [Writing CQ](#writing-cq) · [Using cqcc](#using-cqcc) · [Loop cutoffs](#loop-cutoffs-k-and-k2) ·
[Checking a program](#checking-a-program) · [When something goes wrong](#when-something-goes-wrong) ·
[C coverage](#c-coverage) · [C++ and Rust](#c-and-rust) · [Floating point from SoftFloat](#floating-point-from-softfloat) ·
[How the lowering works](#how-the-lowering-works)

## Writing CQ

A CQ program is a C program. `CQ.h` is included automatically and adds four primitives:

| Primitive | Meaning |
|---|---|
| `cq_theta(&x, a)` | Ry(a) on every qubit of `x`, in place. `x` is any integer or floating-point l-value. This is what makes `x` quantum. |
| `cq_phi(a)` | Multiplies the amplitude of the current branch by e^(ia). |
| `cq_measure(x)` | Measures `x` and returns the classical outcome, with the type of `x`. |
| `cq_invert_begin()` … `cq_invert_end()` | The enclosed code runs as its adjoint. |

Nothing is declared quantum. A value is quantum when it derives from a `cq_theta` result, through
arithmetic, memory, calls and pointers; everything else is classical and runs as ordinary host code.
Angles, loop bounds and iteration counts are usually classical C.

### Idioms

| You want | You write |
|---|---|
| A uniform superposition of an integer | `unsigned char x = 0; cq_theta(&x, M_PI / 2);` |
| One qubit | `bool q = 0; cq_theta(&q, a);` |
| A controlled Ry | `if (c) cq_theta(&q, a);` and doubly controlled: `if (c && d) cq_theta(&q, a);` |
| A CNOT | `t ^= c;` on two `bool` values |
| A phase oracle | `if (pred(x)) cq_phi(M_PI);` |
| The adjoint of `f` | `cq_invert_begin(); f(x); cq_invert_end();` |
| A measurement | `int r = cq_measure(x);` |
| A lookup at a quantum index | `y = table[x];` |

- **`x += y` and `x ^= y` are in place.** When the old `x` is not read afterwards, the update is one
  gate on `x`'s own register and uses no extra register. This is decided from the compiled code,
  not from the spelling: `z = x + y` with `x` never used again is in place too, and `x -= y`,
  `if (c) x += y` and a loop accumulator are not (they compute into a fresh register, and the old
  one is cleared and freed).
- **Scratch is uncomputed for you.** In `if (sqrt(x) == 12.0) cq_phi(M_PI);` the conversion, the
  square root and the comparison go into scratch registers that the compiler clears and frees.
- **A register of qubits is a `bool` array.** `cq_theta(&q[i], a)` is a one-qubit gate on that cell
  and `q[a] ^= q[b]` is a CNOT on two cells. With the bits of one wide integer, a single-qubit
  rotation needs the bit extracted into a temporary and written back, which C turns into a rotated
  copy plus a kept old value, not a gate on the register. An integer view of the array for an
  oracle is one loop (`value()` in `examples/grover/grover.c`).
- **A branch on a quantum condition runs both arms.** Phases, rotations and stores are controlled
  by the condition; pure computation in the arms runs unconditionally and is selected afterwards.
- **`cq_measure` inside a quantum branch measures unconditionally.**
- **Output of a quantum value is deferred**: `printf("%d\n", x)` measures `x` at the end of the run
  and prints then. The table under [C coverage](#c-coverage) lists every such fixed meaning.
- **Undefined behaviour stays undefined.** An input on which the C program divides by zero, shifts
  by the width or reads past an object is outside what the lowered program promises.

`examples/` has two complete programs, Grover search and Dicke-state preparation, with the problem
size as a run-time argument; `examples/README.md` explains them.

## Using cqcc

```sh
cqcc prog.c -lmybackend -o prog        # an executable, linked with a backend
cqcc -S prog.c -o prog.lowered.ll      # the lowered LLVM IR, no backend needed
cqcc -c prog.c -o prog.o               # an object file
cqcc -S --cq-check prog.c              # lower, then compare with the C program
cqcc a.c b.cpp c.ll -lmybackend        # several units; the whole program is one module
```

| Option | Meaning |
|---|---|
| `-S`, `-c`, `-o FILE` | Output kind and path. `-c -emit-llvm` writes bitcode. |
| `-cq-k=<fn>=<k>,...`, `-cq-k-default=<k>` | Loop cutoff per function, and for every function. |
| `-cq-k2=<fn>=<bytes>,...`, `-cq-k2-default=<bytes>` | Byte bound of allocations with a quantum size. |
| `--backend LIB` | A backend library for the link: a path, `-lname` or `-Ldir`. Repeatable. |
| `--no-softfloat` | Leave the floating-point operations to the backend. |
| `--cq-check`, `--cq-entry FN`, `--cq-samples N` | Run the checker on the result, from `FN` (default `main`). |
| `--cq-lib`, `--cq-roots FILE`, `--cq-ext-roots FILE` | Build or use a lowered library ([Lowered libraries](#lowered-libraries)). |
| `-cq-no-output` | Stream output functions fail as on a closed stream; for libraries whose error paths print. |
| `--save-temps DIR` | Keep the compiled units, `linked.ll` (what the pass reads) and `lowered.ll`. |
| `-v` | Print every command before running it. |
| `-I -D -U -include -isystem -std= -W -f`, `-Xclang-cc ARG` | Passed to the C compile. |

Inputs are taken by suffix: `.c` and `.i` are compiled with `clang -O1`, `.cpp`/`.cc`/`.cxx` with
`clang++ -O1 -fno-exceptions`, `.ll` and `.bc` are linked as given, and `.o`, `.a`, `.dylib` go to
the final link. Environment: `CQ_LLVM_BIN`, `CQ_BUILD_DIR`, `CQ_PLUGIN`, `CQ_SPEC_DIR`,
`CQ_BUNDLE_MANIFEST`. `cqcc --help` is the full reference.

A failing step exits with that step's status and writes no output.

## Loop cutoffs: K and K2

A loop whose exit test reads quantum data cannot stop at a different trip on each branch of the
superposition. It runs exactly K trips, and on a branch whose C loop has already exited the further
trips change nothing. The same holds for recursion whose depth is quantum. A loop with a classical
exit test is an ordinary loop and has no cutoff, whatever its body does.

K of a loop in function `f`, first match wins:

1. `-cq-k=f=<k>` on the command line,
2. `CQ_K(f, k)` at file scope in the source,
3. `-cq-k-default=<k>`,
4. the built-in default 4.

On a branch where the C loop needs more than K trips, the loop is cut after trip K and the lowered
program differs from the C program from there on. Circuit size grows with K, so choose the smallest
K that covers the inputs in superposition. For library functions that means their real trip counts:
`strlen` of a string with quantum characters needs K above the string's length, and musl's `fmod`
needs up to 2046.

K2 is the same idea for `malloc(n)` with a quantum `n`: the allocation is bounded by K2 bytes.
`CQ_K2(f, bytes)`, `-cq-k2=f=<bytes>` and `-cq-k2-default=<bytes>` set it.

## Checking a program

```sh
cqcc -S --cq-check --cq-entry grover_3 examples/grover/grover.c
```

The checker runs the lowered program in a classical evaluator on sampled basis inputs and compares
it with the C program: results, registers left live, and every rotation and phase with its
condition. Exit status 0 is a pass, 1 a difference (the reasons are printed) and 2 undecided. The
output file is written also when the check fails.

- Every argument of the entry function is classical and is sampled. The quantum inputs are the
  `cq_theta` calls reached from it: each is replaced by a sampled basis value on both sides. So the
  entry is `main` or a function that prepares its own quantum data.
- Both sides run with the same K, so a loop cut at K is compared up to the cut.
- The checker tests the permutation and the rotation list on basis states. It does not simulate
  amplitudes; a backend simulator does that.

By hand, from `checker/`: `python3 -m cqcheck user --o1 prog.O1.ll --lowered prog.lowered.ll --entry f`.
`--light` is a quick smoke test with fewer samples, not a verdict.

## When something goes wrong

| You see | It means | Do |
|---|---|---|
| `cq: internal error: …` and no output | A compiler bug. There is no unsupported program: every C program is meant to lower. | Report it with `linked.ll` from `--save-temps DIR`. |
| `cq: note: unbuilt: … site: …` | The pass went through a construction it has not finished; the output may be wrong. | Run `--cq-check`, and report it. |
| `--cq-check` exits 1 | The lowered program differs from the C program on a printed input. | First rule out a loop that needs more than K trips; otherwise report it. |
| `--cq-check` exits 2 | The checker ran out of its search budget without finding a difference. | Check a smaller entry function with `--cq-entry`. |
| Undefined `cq_template_*` or `cqrt_*` at link time | No backend on the line, or the backend lacks that operation or width. | Link a backend; for `cq_template_f*` build `softfloat/` ([below](#floating-point-from-softfloat)). |
| Undefined `__cq_q_<fn>_…` at link time | A function on a `--cq-roots` list whose lowered library is not linked, or was built from another list. | Link the library built with the same root list. |
| The backend stops on an address wider than its limit | A memory access at a quantum address with more quantum bits than the backend handles (16 in the recommended one). | Index an array by a narrow quantum value instead of walking a quantum pointer. |
| The result looks cut short | A loop with a quantum exit hit its cutoff. | Raise K for that function. |
| Lowering is slow or the circuit is huge | Library bodies are lowered again per program, and every float operation is a large integer circuit. | Use [lowered libraries](#lowered-libraries); count with `-lcq_gates_count` before simulating. |

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
same lowering. `cqcc` compiles `.cpp`, `.cc` and `.cxx` inputs itself, with `clang++ -O1 -fno-exceptions` and
`driver/cq.hpp` in place of `CQ.h`, also mixed with C units in one program. A Rust program is compiled to a
`.ll` file first (`experiments/cxx_rust/rust.sh`), which `cqcc` takes.
[`experiments/cxx_rust/`](../experiments/cxx_rust/) has the user surface for Rust and the test helpers for both (`driver/cq.hpp`: overloads in place of
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

## How the lowering works

1. **One module.** `clang -O1` compiles each translation unit. The units and the library bodies
   they need are linked into one LLVM module, and the pass runs once over it.
2. **Taint.** A value is quantum exactly when it derives from a `cq_theta` result by data flow,
   through memory, calls and pointers. A module with nothing quantum comes out byte-identical.
3. **Templates.** A quantum value is an `i32` handle to a backend register. Each instruction on
   quantum operands becomes one call of a reversible template that computes its result into a
   fresh register. When the result is no longer needed, the template's inverse (`_unc`) clears the
   register and it is freed. The exception is an `add` or `xor` whose old value is never needed
   again (`x += y`, `x ^= y`, `x += 3`): it is one in-place gate on the register that holds `x`,
   with no fresh register (`cqrt_add`, `cqrt_addc`, `cqrt_copy`, `cqrt_xorc`). The oracle of the
   example becomes:

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

The rules are specified in [`spec/CONSTRUCTION_RULES.md`](../spec/CONSTRUCTION_RULES.md).
