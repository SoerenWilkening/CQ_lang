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

## Demonstrator — standard-library coverage under tainted inputs

<!-- MATHH-HEADLINE:START -->
> ### `math.h` coverage: **159/183 cells (87%)**
>
> **101/120** injection · **6/6** CQ-PROVIDED · **42/42** recognition keep-set · **10/12** type-generic macros · **0/3** nan (by design).
>
> Read it as *"CQ compiles 159 of the 183 modelled `math.h` cells"* — a caller of `sqrt()` gets a real lowering. It is **not** *"CQ compiled openlibm's body 159 times"*: the recognition cells have **no injectable body at all** (Rule 18) and the CQ-PROVIDED cells use **CQ's own reversible leaf**, not upstream's. **The number that tracks COMPILER progress is the injection row alone** — recognition and CQ-PROVIDED move without any compiler work. Computed, never hand-copied (`probe.mathh_union_scoreboard()`), and **-3** if `fma{,f,l}`'s *partial* cells are excluded. Owner ruling 2026-08-22, bd `fhas`; composition is mandatory wherever the total appears.
<!-- MATHH-HEADLINE:END -->

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
> [source-injection census](tools/library_coverage/INJECTION-CENSUS.md). That census
> reports **32/32 injection-covered**, but read it precisely: those 32 are **hand-authored
> branchless bodies** (`branchless/`, bd `3c6m.10`) for the **double** surface, deliberately
> written to bypass the open lowering levers. The [**full-surface census**](tools/library_coverage/full_surface/)
> injects the **real off-the-shelf openlibm** at every width and, as of **2026-08-23**
> (O1 baseline, bd `3c6m.63`), compiles **97/120 upstream-injectable cells (81%)** —
> **all 97 of which are also VERIFIED** (a committed `slice_libm_real_*` golden that
> links, runs and byte-matches at the true `clang -O1 → cq-lowering` ship floor). The
> two numbers are still measured apart and never merged; that they coincide today is a
> MEASUREMENT, not an invariant — and it is now enforced by ctest `e2e-census-slice-sync`
> rather than re-checked by hand. The remaining **23 decline** on the tracked levers:
> loop-carried 9 · unsupported opcode 4 · control (flat/diamond) 3 · L6 nested control 3 ·
> fp-copy/specialization 2 · memory-store (Shadow) 2.
>
> **⚠ THAT NUMERATOR WENT DOWN ON 2026-08-23 — 100 → 97 — AND IT IS A CORRECTION, NOT A
> REGRESSION.** The census corpus was building ten openlibm translation units from
> `ld80/` whose basenames also exist in `src/`, and openlibm's own build **excludes all
> ten**, so three cells were scored as compiling **a program that ships nowhere**
> (`nextafterl.f80`, `nexttoward.f64`, `nexttowardf.f32`). No compiler capability was
> lost; the number stopped measuring the wrong program. This is the retired `165/174`
> error class caught again, and the recipe is now an executable, self-checking script
> (`full_surface/build_corpus.py`) instead of prose nobody ran.
>
> **⚡ A THIRD ROW exists as of 2026-07-31 (Rule 18 amendment, owner ruling, bd `guwr`):
> CQ-PROVIDED — 6/6.** For `sin`/`cos`/`tan` at f64 and `sinl`/`cosl`/`tanl` at f80, CQ
> **ships its own reversible libm source** and the pipeline injects **CQ's leaf instead
> of upstream's body** — what openlibm is to a C compiler, not "CQ compiled openlibm's
> `sin`". Admission is gated on Bennett concrete-branchless backing **and** a committed
> e2e golden **at that width** **and** an explicit owner ruling per function, so
> `sinf`/`cosf`/`tanf` are **rejected** (no f32 leaf; bd `eur4`) and still decline above.
> It is **never merged into** the injection number and, like recognition, is **not
> campaign progress** — it moves only when a leaf is authored.
> **The injection numerator did not move: 97 before the amendment, 97 after.** All six
> cells that left were declines, so the earlier `97/123 (79%)` became `97/117 (83%)` by
> **denominator alone**. Track the numerator. *(It has moved since: `97 → 98` (bd `k710`,
> `nexttowardf.f32`) and `98 → 100` (bd `ww4c.3`, `ilogb.f64` + `ilogbf.f32`) on compiler
> work, while bd `bcv4` took the denominator `117 → 120` by entering three never-probed
> cells — and then `100 → 97` (bd `3c6m.63`, the corpus correction above, which retracted
> `k710`'s cell along with two others). Today's **97/120** is therefore NOT the same 97 as
> the pre-amendment one even though the fraction is identical: it is that set minus
> `nextafterl.f80` and `nexttoward.f64`, plus `ilogb.f64` and `ilogbf.f32`. Never diff two
> generations of this number by their level.)*
> Read the two numbers precisely (Rule 2, bd `libm-scoreboard-two-numbers`):
> *injection-covered* and *verified* are measured SEPARATELY and merely happen to coincide
> right now — and **"verified" certifies the LOWERING, not the unitary**. The runtime is
> trace-only (each `cq_template_*` prints its symbol; `measure` returns 0; no simulation),
> so whether a correct reversible *implementation* of those templates exists is the
> separate — and much lower — **backend** axis in the badge below. The old **165/174 (95%)**
> was the retired name-recognition claim; the honest campaign number moves on real-body
> injection, not authored substitutes.

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
**`math.h` coverage: 159/183 cells (87%)** — 101/120 injection + 6/6 CQ-PROVIDED + 42/42 recognition keep-set + 10/12 type-generic macros + 0/3 nan (by design). Summable only with that composition shown (bd `fhas`); the COMPILER-progress number is the injection row alone.

**Standard-library quantum-coverage — lowering-verified: 48/222 (21.6%)** &nbsp;·&nbsp; backend-available: 28/222 (12.6%) — *a DIFFERENT instrument: the per-function probe harness, across all libraries. It does not count injected openlibm bodies, which is why its `math.h` row is lower than the headline above.*

Two axes (bd e4jv): **Lowering** = the compiler emits + links + golden-matches the reversible-template sequence. **Backend-available** = 🟩 `standard` (a correct reversible routine is directly obtainable) **and** it lowers — vs 🟨 `synthesizable` / 🟥 `open` (no known elementary reversible circuit — the transcendentals). The trace-only runtime proves the lowering, not the backend.

| Library | Lowers | Verified | Backend-avail | 🟩 std | 🟨 syn | 🟥 open | By-design |
|---|---|---|---|---|---|---|---|
| [`math.h`](tools/library_coverage/coverage/mathh.md) | 52/183 (28%) | 45/183 (25%) | 25/183 (14%) | 51 | 45 | 84 | 3 |
| [`stdlib.h`](tools/library_coverage/coverage/stdlib.md) | 3/39 (8%) | 3/39 (8%) | 3/39 (8%) | 6 | 0 | 0 | 8 |

> ## `math.h` coverage: **159/183 cells (87%)**
>
> **Composition — 101/120 injection + 6/6 CQ-PROVIDED + 42/42 recognition keep-set + 10/12 type-generic macros + 0/3 nan (by design).** The routes are measured SEPARATELY and stay separately quotable; since the owner ruling of 2026-08-22 (bd `fhas`) they may be summed, but **only with this composition shown**. Read the total as *"CQ compiles 159 of the 183 modelled `math.h` cells"* — which is true, a user calling `sqrt()` gets a real lowering. It is **NOT** *"CQ compiled openlibm's body 159 times"*: the recognition cells have **no injectable body at all** (Rule 18) and the CQ-PROVIDED cells use **CQ's own leaf**, not upstream's. Sensitivity, so the figure is never quoted barer than it is: **-3** if `fma{,f,l}`'s *partial* cells are excluded, and the 3 by-design `nan` cells arguably do not belong in a denominator at all (nothing to taint). **The campaign number for COMPILER progress remains the injection row alone** — rows (1) and (3) move with no compiler work.
>
> **Three separately-measured coverage scoreboards (bd `libm-scoreboard-two-numbers`) — summable ONLY as above, never silently blended.** The `math.h` `Lowers`/`Verified` columns are the **recognition floor** — fns that lower because `clang -O1` emits a hardware-backed intrinsic the pass recognizes (`sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma lrint llrint` + variants) — a *fixed floor, not injection progress*. The **AUTHORITATIVE libm-campaign number** is the full-surface REAL-openlibm injection census: **101/120 injection-covered (84%), 101 verified** of the reconciled 120-cell surface ([full-depth census](tools/library_coverage/FULL_DEPTH_CENSUS.md) §11) — the injectable subset of this table's denominator (`120 injection + 6 CQ-provided + 42 recognition + 12 macros + 3 nan`). A **third** row, **CQ-PROVIDED** (**6/6 CQ-provided (6 with a committed e2e golden)**), covers functions whose reversible leaf **CQ ships itself** and injects instead of upstream's body (Rule 18 amendment, bd `guwr`) — `sin`/`cos`/`tan` at f64+f80 only; it is **never merged into** the injection number and is not campaign progress. The double-only authored-branchless number (**32/32**, [source-injection census](tools/library_coverage/INJECTION-CENSUS.md)) is a hand-written-substitute subset, superseded by the full-surface census. The three sets are disjoint; a library function that declines under injection stays declined (and ticketed), never counted via recognition.

Full tables: [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) (regenerate: `python3 tools/library_coverage/probe.py run`).
<!-- LIBRARY-COVERAGE:END -->

The table above is the **recognition floor** — the hardware-backed intrinsic survivors
(`sqrt`/rounding/`copysign`/`fmin`/`fmax`/`fma`/`lrint`/`llrint`) plus the opcode-macros
(`isnan`, `isfinite`, …). It is **not** a per-function template surface for library functions
any more (Rule 18 retired that). The genuine library functions are measured **separately and
disjointly** by [`INJECTION-CENSUS.md`](tools/library_coverage/INJECTION-CENSUS.md) — the
**source-injection** strategy (inject a real libm body's source so LLVM inlines it to stock
opcodes *before* the pass, no per-function template).

> **⚠ The "7 / 32 … off-the-shelf openlibm baseline remains 0/32" text that stood here
> was from the 2026-07-10 double-only era and had been contradicted by this page's own
> badge for weeks. Corrected 2026-07-31 (bd `guwr`).** The authoritative measurement is
> the **full-surface** census linked in the badge above, not the legacy 32-cell one:
> **100 / 120 upstream-injectable cells compile and are golden-verified**, on **real
> off-the-shelf openlibm bodies at every width** — so the openlibm baseline is emphatically
> not 0. Of the 20 that still decline, only **2 are actionable** (`scope: lever-gap`); the
> rest are owner-decided, deferred, or corpus gaps. The `branchless/` hand-authored bodies
> are a **separate, retired** scoreboard — except for the six that now pass the Rule 18
> **CQ-PROVIDED** gate (`sin`/`cos`/`tan` at f64+f80), which are counted on their own third
> row and never merged into the injection number.

Every remaining decline is on
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
