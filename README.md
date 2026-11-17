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
- The specification repository `CQ_spec`, checked out next to this one. It holds `CQ.h` and the
  backend interface, `BACKEND_ABI.md`.

```sh
git clone https://github.com/SoerenWilkening/CQ_lang.git   # with CQ_spec as its sibling directory
cd CQ_lang
cmake -S . -B build -G Ninja
cmake --build build
ln -s "$PWD/driver/cqcc" /usr/local/bin/cqcc               # optional: cqcc on the PATH
```

An LLVM outside `/usr/local/opt/llvm@19` is named by `-DCQ_LLVM_PREFIX=<prefix>` at configure time
and by `CQ_LLVM_BIN=<prefix>/bin` when running `cqcc`. A `CQ_spec` elsewhere is named by
`CQ_SPEC_DIR`. `cqcc --help` lists every option.

An executable needs a backend: a library that implements `BACKEND_ABI.md`. This repository
contains none. `cqcc -S`, `cqcc -c` and `--cq-check` work without one.

A backend is linked like any library: `-lmybackend` (with `-L<dir>` if it is not on the linker's
search path) or a path given to `--backend`. Built as a shared library, it is bound when the
program starts, so one executable runs against any backend installed under that name, such as a
simulator, a resource counter or hardware, with no relink. Built as an archive (`.a`), it is copied
into the executable.

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

The rules are specified in `CONSTRUCTION_RULES.md` of `CQ_spec`.
