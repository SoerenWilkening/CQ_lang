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

    cq_theta(&a, 0.5);             /* Ry(0.5) in place — a is now tainted (quantum) */

    int c = a + b;                  /* taint propagates: c is quantum too  */

    int result = cq_measure(c);     /* explicit measurement — sole sink    */

    return result;
}
```

The intrinsic surface is small: `cq_theta` (the only taint source),
`cq_phi(θ)` (the branch phase — register-free, no data operand),
`cq_measure` (the only sink), and a manual
inversion bracket `cq_invert_begin` / `cq_invert_end` (declared in `CQ.h`, not
lowered yet: [`docs/frontend.md`](docs/frontend.md) §3.5). No quantum
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

CQ requires LLVM 19 and its development CMake package. The installer discovers
LLVM automatically from `LLVM_DIR`, `llvm-config`, or Homebrew's `llvm@19` keg.
You can still set `LLVM_DIR` explicitly when multiple LLVM versions are
installed:

```bash
brew install llvm@19
export LLVM_DIR="$(brew --prefix llvm@19)/lib/cmake/llvm"
```

The installer builds and installs the pass, `cq-opt`, the
headers, runtime archives, and CMake package files. A production backend must be
selected explicitly; the installer validates its archive and ABI manifest and
records it as `CQ::backend`:

```bash
python3 tools/install_cq.py \
  --backend mybackend \
  --backend-library /absolute/path/libmybackend.a \
  --backend-manifest /absolute/path/backend-manifest.json \
  --backend-link-item m \
  --parallel "$(sysctl -n hw.ncpu)"
```

`--parallel N` forwards to `cmake --build --parallel N`; use `--parallel`
without a number to let CMake choose its native default.

The default installation prefix is `~/.local`; use `--prefix PATH` to choose a
different location.

Use `--backend trace` when installing only the trace/test backend. There is no
implicit production-to-trace fallback. CMake applications can then use the
selected backend with `find_package(CQ CONFIG REQUIRED)` and
`target_link_libraries(app PRIVATE CQ::backend)`. See
[`docs/backend-provider.md`](docs/backend-provider.md) for the backend archive
and manifest contract.

For the complete production stack, `--backend cqops` builds
[`opcode_quantum_operations`](https://github.com/SoerenWilkening/opcode_quantum_operations)
with [`C_quantum_error_correction`](https://github.com/SoerenWilkening/C_quantum_error_correction)
and installs the circuit backend plus its QEC archives into the same prefix:

```bash
python3 tools/install_cq.py \
  --backend cqops \
  --parallel "$(sysctl -n hw.ncpu)"
```

The installer automatically clones pinned revisions of both repositories into
`~/.cache/cq/sources` (override with `--dependency-source-dir`) and builds the
QEC repository's `qec/` subdirectory first. Existing checkouts can be supplied
with `--cqops-dir` and `--qec-dir` for offline or development builds. The
default build directories are `qec/build-cq-install` in the QEC checkout and
`build-cqops-install` in the current directory; override them only when needed.
The installed prefix contains `cqc`, `libCQPass.so`,
`libcqops.a`, `libqec.a`, `libtommath.a`, and `libcjson.a` under its `bin/` and
`lib/cq/` directories. The installer validates the CQ ABI manifest and records
the complete static-link order; CQ's trace archives are not linked.

The QEC sink is selected when the compiled program runs, because its code
distance and device configuration are application-specific:

```bash
export CQOPS_SINK=qec
export CQOPS_QEC_CONFIG=/absolute/path/to/qec-config.json
cqc program.c -o program
./program
```

The installer also installs `cqc`. It reads the backend selection written by
`install_cq.py`, so compiling through the installed driver links exactly that
backend:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
source "$HOME/.zshrc"
cqc program.c -o program
./program
```

The first two commands add the install directory to future zsh sessions. For
bash, use `~/.bashrc` instead. Alternatively, set `PATH` only for the current
shell with `export PATH="$HOME/.local/bin:$PATH"`. If it is not on `PATH`,
invoke the driver by its full path:
`"$HOME/.local/bin/cqc" program.c -o program`.

To remove CQ, run:

```bash
cqc --uninstall
```

The installed driver derives its prefix from its own location, checks the
installer-generated ownership manifest, shows the prefix, and asks for
confirmation before removing only CQ-owned files. Use `cqc --uninstall --yes`
for a non-interactive uninstall. Installations created before ownership
manifests were introduced must be reinstalled once before this command is
available.

It runs the validated `clang -O1` → `llvm-link` → `opt -passes=cq-lowering` →
Clang link pipeline. A production backend and the trace archives are never put
on the same link line. The repository copy, [`tools/cqc`](tools/cqc), remains
usable for source-tree development and falls back to the in-tree trace backend
when no installer selection exists.

## Demonstrator — standard-library coverage under tainted inputs

<!-- MATHH-HEADLINE:START -->
> ### `math.h` coverage through `cqc`: **71/180 scalar-input cells (39%)**
>
> **19/120** source-injected · **6/6** CQ-provided · **36/42** intrinsic · **3/3** classical-only · **10/12** macro. A cell counts when every runtime C/Q mixture builds, lowers, links and trace-runs through `tools/cqc`, the driver a user runs ([detail](tools/library_coverage/runtime_census.md); regenerate with `python3 tools/library_coverage/runtime_census.py --output tools/library_coverage/runtime_census.json`). The `nan` row is classical-only and outside the scalar total.
>
> The lab-harness scoreboards in [`COVERAGE.md`](tools/library_coverage/COVERAGE.md) inject openlibm bodies `cqc` does not ship (bd `3c6m.70`, `3c6m.72`). They measure what the compiler can lower inside that harness, not what a user can compile.
<!-- MATHH-HEADLINE:END -->

The headline counts what `tools/cqc` compiles: every probe uses runtime operands
and every classical/quantum argument combination ([northstar](NORTHSTAR.md) goal 2).
`cqc` injects the real openlibm source (CQ's own branchless code for `sin`/`cos`/`tan`)
for a math.h call with a quantum operand; a classical call keeps the system libm.
A body whose quantum branches the function lifter cannot lower yet still fails
loudly, and is a compiler gap (bd `p3kd`).

“Verified” in the lab scoreboards means the lowered template trace links, runs,
and matches a committed golden; the trace runtime does not simulate a unitary.

Example: taint a `math.h` input and measure the lowered result:

```c
#include <CQ.h>
#include <math.h>

int main(void) {
    double x = 1.0;
    cq_theta(&x, 0.25);              /* x becomes quantum */
    double y = sqrt(x);              /* taint flows through math.h */
    return cq_measure(y);            /* explicit measurement */
}
```

Compile it with the CQ driver:

```bash
tools/cqc tainted_sqrt.c -o tainted_sqrt
./tainted_sqrt
```

This example uses the hardware route for `sqrt`. A call such as `sin(x)` or
`cbrt(x)` on a quantum `x` instead lifts the openlibm (or CQ) body `cqc` injects;
the build fetches openlibm at a pinned commit (`CQ_OPENLIBM_SOURCE_DIR` points it at
a local checkout instead).

## Documentation

- [`NORTHSTAR.md`](NORTHSTAR.md) — the three goals and the design principles
- [`CLAUDE.md`](CLAUDE.md) — operating rules for contributors and AI agents
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
- [`docs/design/qram-local-array-uncompute.md`](docs/design/qram-local-array-uncompute.md)
  — design note: uncompute and escape of a local QRAM array whose load is
  measured or returned

## Status

[`NORTHSTAR.md`](NORTHSTAR.md) is the plan of record: a decline is valid only if physics
forbids the program, `math.h` coverage counts only for non-trivial input, and every known
quantum routine must be implementable. Agent operating rules are in [`CLAUDE.md`](CLAUDE.md).
The retired roadmap, per-phase records and old manual are in git at tag `pre-northstar`.
