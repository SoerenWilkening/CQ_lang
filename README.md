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
`cq_phi` (phase rotation), `cq_measure` (the only sink), and a manual
inversion bracket `cq_invert_begin` / `cq_invert_end`. No quantum
arithmetic intrinsics — stock LLVM opcodes on tainted operands are
lowered to reversible template calls by the IR pass.

## Pipeline

Stock Clang compiles plain C plus the `CQ.h` header to LLVM IR; an
out-of-tree LLVM pass (`cq-lowering`) computes forward taint, inserts
qubit allocation at the first `cq_theta`, lowers tainted opcodes to
runtime template calls, and links against `libcq_runtime`. There is no
AST rewriter and no LLVM fork.

## Demonstrator — standard-library coverage under tainted inputs

The headline demonstrator for CQ is **how much of the C standard library the IR pass
lowers to reversible quantum templates** when its inputs are **tainted** — automatically,
with no source changes. Coverage is measured empirically and per-library by
[`tools/library_coverage/probe.py`](tools/library_coverage/probe.py), which runs every
function through every applicable classical/quantum argument **mixture** (`HL`, `LH`, `QQ`,
…) over the full pipeline and records, per cell, whether it lowers, links, runs, and matches
a committed golden trace.

`math.h` is the flagship (pure numerical functions); `stdlib.h`'s integer `abs` island is the
second. The format is **adaptable** — a new library is one `Lib(...)` entry plus its spec
(see [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) §"Adding a
library"; scouted-but-unwired headers like `ctype.h`/`string.h`/`complex.h` are in
[`SCOPED-CANDIDATES.md`](tools/library_coverage/SCOPED-CANDIDATES.md)).

A function counts as **Covered** only when *every* applicable mixture is **golden-verified** —
exit-zero is not verification, and a loud decline is a *correct* (just uncovered) outcome,
never papered over to inflate the number (the Prime Directive). The tables separate
**cannot-compile-at-the-moment** (fixable future work — e.g. `long double` needs an f80/f128
width) from **cannot-compile-at-all** (by design — e.g. `nan(const char*)` has no quantum input).

<!-- LIBRARY-COVERAGE:START -->
**Standard-library quantum-coverage — compiles: 61/213 (28.6%)** &nbsp;·&nbsp; golden-verified: 61/213 (28.6%).

| Library | Compiles | Golden-verified | Cannot-yet (fixable) | By-design |
|---|---|---|---|---|
| [`math.h`](tools/library_coverage/coverage/mathh.md) | 58/174 (33%) | 58/174 (33%) | 113 | 3 |
| [`stdlib.h`](tools/library_coverage/coverage/stdlib.md) | 3/39 (8%) | 3/39 (8%) | 28 | 8 |

Full tables: [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) (regenerate: `python3 tools/library_coverage/probe.py run`).
<!-- LIBRARY-COVERAGE:END -->

## Documentation

- [`ROADMAP.md`](ROADMAP.md) — phase-by-phase trajectory and
  cross-cutting design principles
- [`docs/frontend.md`](docs/frontend.md) — the user-facing intrinsic
  surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the
  Clang/`-O1` stage that prepares the IR
- [`docs/backend.md`](docs/backend.md) — the IR pass, the runtime ABI,
  and how tainted opcodes become reversible templates
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
