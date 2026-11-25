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
for it: see [Floating point from SoftFloat](docs/MANUAL.md#floating-point-from-softfloat).

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

## Documentation

| | |
|---|---|
| [`docs/MANUAL.md`](docs/MANUAL.md) | The user manual: idioms, `cqcc`, loop cutoffs, checking, troubleshooting, C and library coverage, C++ and Rust, SoftFloat, how the lowering works. |
| [`llms.txt`](llms.txt) | The manual on one page, for AI assistants writing CQ. |
| [`examples/`](examples/) | Grover search and Dicke-state preparation with a run-time problem size. |
| [`docs/EXPERIMENTS.md`](docs/EXPERIMENTS.md) | Existing projects lowered unchanged (musl, GSL, SQLite, GMP, GLPK, TinyCC, TinyEMU, Stockfish), lowering times and gate counts. |
| [`spec/`](spec/) | The specification: `CQ.h`, `CONSTRUCTION_RULES.md` (normative), `BACKEND_ABI.md` (what a backend implements). |
| [`NORTHSTAR.md`](NORTHSTAR.md), [`CLAUDE.md`](CLAUDE.md) | Goals and principles; how to work on the compiler. |
