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

> **Rule 18 (bd `p119`, 2026-07-06):** compiling a **library function ALWAYS means its
> source is injected** (an openlibm-style body inlined to opcodes *before* the pass) —
> coverage of a library function is measured **only** by source injection, never by
> recognizing `@llvm.<fn>` / `@<fn>` by name. Name-recognition survives **only** for the
> **hardware-backed intrinsics** that codegen to a HW instruction and have no injectable
> body: `sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma/fmuladd
> lrint llrint`. So `probe.py`'s number below counts what lowers **by recognition** (the
> hardware survivors + opcode-macros); every transcendental / direct-libm / by-ref
> function **declines loudly** without injection and is measured by the
> [source-injection census](tools/library_coverage/INJECTION-CENSUS.md), where
> off-the-shelf openlibm currently compiles ~0 of them (blocked by tainted control flow /
> scratch memory). The old **165/174 (95%)** was the retired name-recognition claim.

`math.h` is the flagship (pure numerical functions); `stdlib.h`'s integer `abs` island is the
second. The format is **adaptable** — a new library is one `Lib(...)` entry plus its spec
(see [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) §"Adding a
library"; scouted-but-unwired headers like `ctype.h`/`string.h`/`complex.h` are in
[`SCOPED-CANDIDATES.md`](tools/library_coverage/SCOPED-CANDIDATES.md)).

A function counts as **Covered** only when *every* applicable mixture is **golden-verified** —
exit-zero is not verification, and a loud decline is a *correct* (just uncovered) outcome,
never papered over to inflate the number (the Prime Directive). Note that most of math.h now
falls in **injection-required** (a library function — decline without source injection), not
the small **cannot-compile-at-all** by-design set (e.g. `nan(const char*)` has no quantum input).

<!-- LIBRARY-COVERAGE:START -->
**Standard-library quantum-coverage — lowering-verified: 48/213 (22.5%)** &nbsp;·&nbsp; backend-available: 21/213 (9.9%).

Two axes (bd e4jv): **Lowering** = the compiler emits + links + golden-matches the reversible-template sequence. **Backend-available** = 🟩 `standard` (a correct reversible routine is directly obtainable) **and** it lowers — vs 🟨 `synthesizable` / 🟥 `open` (no known elementary reversible circuit — the transcendentals). The trace-only runtime proves the lowering, not the backend.

| Library | Lowers | Verified | Backend-avail | 🟩 std | 🟨 syn | 🟥 open | By-design |
|---|---|---|---|---|---|---|---|
| [`math.h`](tools/library_coverage/coverage/mathh.md) | 45/174 (26%) | 45/174 (26%) | 18/174 (10%) | 42 | 45 | 84 | 3 |
| [`stdlib.h`](tools/library_coverage/coverage/stdlib.md) | 3/39 (8%) | 3/39 (8%) | 3/39 (8%) | 6 | 0 | 0 | 8 |

> **Two DISJOINT coverage scoreboards (bd `libm-scoreboard-two-numbers`) — never merged.** The `math.h` `Lowers`/`Verified` columns are the **recognition floor** — fns that lower because `clang -O1` emits a hardware-backed intrinsic the pass recognizes (`sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma lrint llrint` + variants) — a *fixed floor, not injection progress*. **Injection-covered** — genuine library bodies compiled by source injection (Rule 18), the number the libm campaign actually moves — is **2/32** of the `math.h` double surface ([source-injection census](tools/library_coverage/INJECTION-CENSUS.md)). The two sets are disjoint; a library function that declines under injection stays declined (and ticketed), never counted via recognition.

Full tables: [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) (regenerate: `python3 tools/library_coverage/probe.py run`).
<!-- LIBRARY-COVERAGE:END -->

The table above is the **recognition floor** — the hardware-backed intrinsic survivors
(`sqrt`/rounding/`copysign`/`fmin`/`fmax`/`fma`/`lrint`/`llrint`) plus the opcode-macros
(`isnan`, `isfinite`, …). It is **not** a per-function template surface for library functions
any more (Rule 18 retired that). The genuine library functions are measured **separately and
disjointly** by [`INJECTION-CENSUS.md`](tools/library_coverage/INJECTION-CENSUS.md) — the
**source-injection** strategy (inject a real libm body's source so LLVM inlines it to stock
opcodes *before* the pass, no per-function template). Current: **2 / 32 genuine `math.h`
library bodies compile** — `exp` and `log`, both via **hand-authored branchless soft-bodies**
(`tools/library_coverage/branchless/`, bd `3c6m.10` L1; each with a linked+diffed e2e golden
slice). The off-the-shelf openlibm baseline remains 0/32: every branchy libm body declines on
**tainted control flow**, **scratch memory**, a **nested transcendental**, or a
**dynamic-index table read**, and *not one* on a missing opcode (the opcode surface is
already sufficient; branchy/memory-heavy libm bodies are the blocker). `fabs`/`copysign` are
**not** counted here as injection wins — they "compile" only because `clang -O1` folds their
bit-tricks to the recognized `@llvm.fabs`/`@llvm.copysign`, so they belong to the recognition
floor above, not to injection (bd `libm-scoreboard-two-numbers`).

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
