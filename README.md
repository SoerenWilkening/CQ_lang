# CQ_lang — A Taint-Driven Quantum-C Compiler

CQ is a small extension of C for writing quantum programs. There is no
`quantum` keyword and no special type: a value becomes quantum by
passing through a `cq_*` primitive, and the LLVM IR pass propagates
that *taint* forward through stock C arithmetic, control flow, and
calls.

```c
#include <CQ.h>

int main(void) {
    int a = 3;
    int b = 5;

    a = cq_theta(a, 0.5);          /* Ry(0.5) — a is now tainted (quantum) */

    int c = a + b;                  /* taint propagates: c is quantum too  */

    int result = cq_measure(c);     /* explicit measurement — sole sink    */

    return result;
}
```

The intrinsic surface is small: `cq_theta` (the only taint source),
`cq_phi(θ)` (the branch phase — register-free, no data operand),
`cq_measure` (the only sink), and a manual
inversion bracket `cq_invert_begin` / `cq_invert_end`. No quantum
arithmetic intrinsics — stock LLVM opcodes on tainted operands are
lowered to reversible template calls by the IR pass.

## Pipeline

Stock Clang compiles plain C plus the `CQ.h` header to LLVM IR; an
out-of-tree LLVM pass (`cq-lowering`) computes forward taint, inserts
qubit allocation at the first `cq_theta`, lowers tainted opcodes to
runtime template calls, and links against `libcq_runtime`. There is no
AST rewriter and no LLVM fork.

For an installed toolchain, the linked backend is explicit. The bundled
`CQ::trace_backend` remains the regression-test implementation; a precompiled
production archive such as `libcqops.a` replaces it through `CQ::backend` and
is reused across applications. See the [backend-provider contract](docs/backend-provider.md)
and `python3 tools/install_cq.py --help`. A production backend and the trace
archives must never share one link line.

## Install and run

CQ requires LLVM 19. The installer builds and installs the pass, `cq-opt`, the
headers, runtime archives, and CMake package files. A production backend must be
selected explicitly; the installer validates its archive and ABI manifest and
records it as `CQ::backend`:

```bash
python3 tools/install_cq.py \
  --prefix "$HOME/.local" \
  --backend mybackend \
  --backend-library /absolute/path/libmybackend.a \
  --backend-manifest /absolute/path/backend-manifest.json \
  --backend-link-item m
```

Use `--backend trace` when installing only the trace/test backend. There is no
implicit production-to-trace fallback. CMake applications can then use the
selected backend with `find_package(CQ CONFIG REQUIRED)` and
`target_link_libraries(app PRIVATE CQ::backend)`. See
[`docs/backend-provider.md`](docs/backend-provider.md) for the backend archive
and manifest contract.

For a CMake application, the installed selection is the default backend:

```cmake
find_package(CQ CONFIG REQUIRED)

add_executable(my_quantum_app main.c)
target_link_libraries(my_quantum_app PRIVATE CQ::backend)
```

Configure with the installation prefix and build normally:

```bash
cmake -S . -B build-user -DCMAKE_PREFIX_PATH="$HOME/.local"
cmake --build build-user
```

`CQ::backend` resolves to the backend selected by `install_cq.py`; the
application must not also link CQ's trace archives. `tools/cqc` is still a
source-tree convenience driver and does not yet consume this installed CMake
target automatically.

The repository also includes [`tools/cqc`](tools/cqc), a single-command driver
for compiling a CQ source file to an executable:

```bash
tools/cqc program.c -o program
./program
```

It runs the validated `clang -O1` → `llvm-link` → `opt -passes=cq-lowering` →
Clang link pipeline. The driver is currently a source-tree helper: it locates
the in-tree/build trace archives directly and is not installed by
`install_cq.py`. For an installed production backend, use the exported CMake
target (`CQ::backend`) in your application link, or pass the backend archive
through your own build integration; do not link a production backend together
with the trace archives.

## Demonstrator — standard-library coverage under tainted inputs

**Current coverage:** `math.h` **159/183 cells (87%)** — **101/120** real-body
injection, **6/6** CQ-provided leaves, **42/42** recognition cases, **10/12**
type-generic macros, and **0/3** `nan` cases (no quantum input by design).

The broader library probe reports **48/222 (21.6%) lowering-verified** cases and
**28/222 (12.6%) backend-available** cases. Injection coverage comes from the
full-surface census using real openlibm bodies; the other rows are separate
recognition/CQ-provided scoreboards. “Verified” means the lowered template trace
links, runs, and matches a committed golden; the trace runtime does not simulate
a unitary. See [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md)
for the generated tables and methodology.

For users, the normal setup is simply a C source file plus the standard
library headers and runtime supplied by the host toolchain. Compile it with
`tools/cqc` as shown below. The coverage numbers use a separate developer
harness that injects openlibm source bodies before LLVM sees the program; that
source-injection path is not currently exposed as a `tools/cqc` option and
should not be treated as a user installation step.

Example: taint a `math.h` input and measure the lowered result:

```c
#include <CQ.h>
#include <math.h>

int main(void) {
    double x = cq_theta(1.0, 0.25);  /* x becomes quantum */
    double y = sqrt(x);              /* taint flows through math.h */
    return cq_measure(y);            /* explicit measurement */
}
```

Compile it with the CQ driver:

```bash
tools/cqc tainted_sqrt.c -o tainted_sqrt
./tainted_sqrt
```

This `cqc` example uses the compiler’s recognized `sqrt` route. It does **not**
use a source-injected openlibm body: `tools/cqc` does not automatically inject
or link one. Passing an openlibm `.c` file as an additional
`tools/cqc` input would compile it as a separate classical translation unit,
but would not by itself vendor and rename the coverage slice or make that body
the selected `math.h` implementation.

## Documentation

- [`ROADMAP.md`](ROADMAP.md) — phase-by-phase trajectory and
  cross-cutting design principles
- [`docs/frontend.md`](docs/frontend.md) — the user-facing intrinsic
  surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the
  Clang/`-O1` stage that prepares the IR
- [`docs/backend.md`](docs/backend.md) — the IR pass, the runtime ABI,
  and how tainted opcodes become reversible templates
- [`docs/backend-provider.md`](docs/backend-provider.md) — packaging,
  validating, installing, and selecting interchangeable static backends
- [`docs/quantum-classical-handling.md`](docs/quantum-classical-handling.md)
  — taint as the Q/C boundary; mixed-operand semantics
- [`docs/example.md`](docs/example.md) — end-to-end worked walkthrough
  of a small program through every stage
- [`docs/llvm-implementation.md`](docs/llvm-implementation.md) — the
  stock LLVM C++ APIs the pipeline depends on
- [`docs/bennett-jl-comparison.md`](docs/bennett-jl-comparison.md) —
  comparison against Bennett-style and Quantum.jl-style approaches
- [`docs/rationale/proposal-taint-driven-pipeline.md`](docs/rationale/proposal-taint-driven-pipeline.md)
  — the proposal that motivated the current design
- [`docs/archive/old-design/`](docs/archive/old-design/) — the
  retired `quantum`-keyword design, preserved for reference

## Status

The taint-driven design is the current trajectory; phase work is
tracked in [`ROADMAP.md`](ROADMAP.md). The pre-redesign Phase 1
artifacts are archived under `docs/archive/old-design/`.
