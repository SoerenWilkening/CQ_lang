# CQ_lang Phase 1 PRD — First End-to-End Vertical Slice

## Goal

A CQ source file of the worked-example shape ([`docs/example.md`](../../docs/example.md)) compiles **end-to-end** through the new pipeline (rewriter → Clang → CQ IR pass → stub `libcq_runtime`) and runs, producing a deterministic log of runtime calls. This is "v1 ported onto the new architecture" — the minimum viable vertical slice through every layer of the pipeline architecture settled 2026-05-21 / 2026-05-22 ([`docs/architecture.md`](../../docs/architecture.md)).

Phase 1 is a proof-of-pipeline: the same architectural shape that Phases 2–10 will broaden. **Backend correctness is explicitly not in scope** — stubs are trace-only.

## Scope

Phase 1 implements the v1-equivalent feature subset (single integer width, one binary operator, measurement-by-cast), but flowing through all four pipeline stages instead of stopping at transpiled C. Concretely:

- `quantum int x = N;` (classical literal init)
- `quantum int z = a + b;` (quantum-quantum add)
- `quantum int z = a + N;` (mixed; classical operand splices into stock arithmetic per architecture §5.2)
- `(int) q` (measurement-as-cast)

No other operators, no other widths, no control flow on quantum conditions, no functions, no inversion, no uncomputation (the only enclosing scope is `main`, where Phase 5's auto-uncomp rule suppresses adjoint emission).

## Marker syntax (input)

Inherited from v1: `quantum` is a macro expanding to `__attribute__((annotate("quantum")))`. After preprocessing, Clang sees `VarDecl`s carrying `AnnotateAttr("quantum")`. The rewriter matches on the attribute via `transpiler/src/QuantumAttr.cpp` (no change to recognition machinery).

The only surface change from v1 here: the `#define quantum …` line moves out of user source and into the new `CQ.h` header. Users write `#include <CQ.h>` instead.

## Supported source patterns and rewrites

The table below supersedes v1's rewriter patterns. Multi-decl statements (`quantum int a = 3, b = 2;`) are supported as in v1 by decomposition.

| # | Source | Rewritten output |
|---|---|---|
| 1 | `quantum int x;` | `qint_mid_t x = cq_init_i32(0);` |
| 2 | `quantum int x = E;` (E classical) | `qint_mid_t x = cq_init_i32(E);` |
| 3 | `quantum int z = a + b;` (both quantum) | `qint_mid_t z; z.val = a.val + b.val;` |
| 4 | `quantum int z = a + E;` (`a` quantum, `E` classical) | `qint_mid_t z; z.val = a.val + E;` |
| 5 | `(int) q` (q quantum) | `cq_measure_i32(q)` |

### Width resolution

`int` resolves to `i32` (and `cq_init_i32` / `cq_measure_i32`) via Clang's `TargetInfo` for the active target — *not* hardcoded. On typical 64-bit hosts this is i32; on a 16-bit-int target the rewriter would emit `cq_init_i16` instead. Phase 1 only exercises i32 in tests, but the policy is target-aware so the rewriter doesn't acquire a Phase-2 carry-forward debt.

### No QQ/QC dispatch (architecture §5.2)

Pattern 4's classical operand `E` splices into stock `.val` arithmetic directly. The IR pass identifies quantum-ness via taint propagation; the rewriter does not maintain per-pattern QQ/QC branches as v1 did.

## CQ.h and cq_mid.h (new files)

Two new headers under `include/`, split by audience:

- **`include/CQ.h`** — user-facing. The bare minimum a quantum-algorithm author needs to `#include`:
  - The `quantum` keyword macro (`#define quantum __attribute__((annotate("quantum")))`)

  That's the entire surface. `qint_mid_t` and the per-width intrinsics are pipeline plumbing, not author-facing vocabulary.

- **`include/cq_mid.h`** — transpiled-C ABI; emitted into rewriter output, never `#include`d by authors:
  - The `qint_mid_t` struct type (`struct { int32_t val; }`, per architecture §3 / §6.1 decision 2026-05-22)
  - The Phase 1 intrinsic surface (taint sources, sinks):
    - `qint_mid_t cq_init_i32(int32_t value);`
    - `int32_t    cq_measure_i32(qint_mid_t);`

  The rewriter (or `cqc` driver via `-include cq_mid.h`) is responsible for threading this header into the transpiled output before Stage 2 compilation.

Other intrinsic families (`cq_theta`, `cq_phi`, `cq_when_*`, `cq_invert_*`, other-width init/measure) are declared in `cq_mid.h` in later phases as they are exercised. Phase 1's surface is deliberately minimal.

## Pipeline

```
  example.c
     │  (#include <CQ.h>)
     ▼
┌─────────────────────────┐
│ quantum_transpiler      │  libtooling rewriter (extends v1)
│  - VarDecl + AnnotateAttr  → qint_mid_t + cq_init_<W>(E)
│  - quantum BinaryOp        → .val-field arithmetic
│  - CStyleCast q→classical → cq_measure_<W>(q)
└─────────────────────────┘
     │
     ▼
  example.transpiled.c    (still valid C; includes CQ.h decls)
     │
     ▼
  clang -O1 -emit-llvm    (mem2reg + sroa flatten qint_mid_t inside bodies)
     │
     ▼
  example.bc              LLVM IR with @cq_init_i32 taint sources,
                          stock add i32 for quantum arithmetic,
                          @cq_measure_i32 taint sinks
     │
     ▼
┌─────────────────────────┐
│ CQ IR pass plugin       │  productionized from prototype/cq_pass.cpp
│  1. Forward taint propagation from @cq_init_i32 returns
│  2. Lower @cq_init_<W>(v)     → cqrt_alloc_classical_<W>(v)
│  3. Lower tainted add i32     → cq_template_add_i32(...)
│  4. Lower @cq_measure_<W>(q)  → cqrt_measure_<W>(handle)
│  (No uncomputation: enclosing scope is main, per architecture §7.4)
└─────────────────────────┘
     │  opt -load-pass-plugin=libCQPass.so -passes='cq-lowering'
     ▼
  example.lowered.bc      LLVM IR with only cqrt_* and cq_template_* calls
     │
     ▼
  clang link              against stub libcq_runtime + stub template library
     │
     ▼
  example                 binary
     │
     ▼ (./example)
  call trace log          stdout — deterministic sequence of stub-call lines
```

The whole pipeline is orchestrated by a `cqc` shell driver (see Deliverables).

## Stub `libcq_runtime` (new)

Trace-only. Each function `printf`s its name and arguments and returns a deterministic sentinel (e.g., a monotonic handle counter for `cqrt_alloc_*`; `0` for `cqrt_measure_*`). No classical simulation; no value tracking through handles. Phase 1 acceptance is **call-sequence shape**, not **answer correctness**.

Phase 1 ships these symbols:

```c
int     cqrt_alloc_classical_i32(int32_t value);   // returns fresh handle
int32_t cqrt_measure_i32(int handle);              // taint sink (returns 0)
void    cqrt_free(int handle);                     // declared but unused in Phase 1
```

`cqrt_alloc_i32` (non-classical, fresh-ancilla) is **not** in Phase 1. The rewriter only emits `cq_init_i32(value)`; the IR pass only ever lowers to `cqrt_alloc_classical_i32`. Fresh-ancilla allocation enters when XOR-copy / Phase 5 uncomputation lands.

## Stub template library (new)

Trace-only, same idea. Phase 1 ships just one template:

```c
void cq_template_add_i32(/* signature TBD at PRD-impl time */);
```

Signature is decided during implementation; the unit of acceptance is the trace log, not the symbol shape. The IR pass emits one `cq_template_add_i32` call per tainted `add i32` instruction. **Note:** in-place vs out-of-place add semantics (and the implied need for an XOR-copy primitive) is **explicitly deferred** to a later phase — Phase 1 emits a single template call per `add`, and the resulting trace is sufficient for pipeline validation even if it elides the copy step that real quantum addition would require.

Inverse and controlled variants are deferred (Phases 3 / 5).

## IR pass plugin (productionized from prototype)

The prototype at `prototype/cq_pass.cpp` already implements taint propagation, mid-struct → handle rebinding, and template-call lowering for the Phase 1 worked-example shape (i32 add only). Phase 1 productionizes this slice:

- Promote to a permanent home (e.g., `ir-pass/` — exact path decided at impl time).
- Register as an LLVM new-PM pass plugin loadable via `opt -load-pass-plugin=libCQPass.so -passes='cq-lowering'`.
- Add a `copyMetadata()` discipline on instruction substitution to passively preserve `!dbg` (see Diagnostics below).
- Integrate into top-level CMake.

The prototype's other slices (`cq-uncompute`, `cq-specialize`, `cq-control`) remain prototypes; Phases 4 / 5 / 7 productionize them when their phases land.

## `cqc` driver (new)

A shell script at `tools/cqc` (or `bin/cqc`) that orchestrates the four pipeline stages from a single user command:

```bash
cqc example.c -o example
# internally:
#   quantum_transpiler example.c -- -std=c11 -I<include-path> > example.transpiled.c
#   clang -O1 -emit-llvm -c example.transpiled.c -I<include-path> -o example.bc
#   opt -load-pass-plugin=<…>/libCQPass.so -passes='cq-lowering' example.bc -o example.lowered.bc
#   clang example.lowered.bc -lcq_runtime -lcq_templates -o example
```

A CMake macro `add_cq_executable()` is **out of scope** for Phase 1 (punted to a later phase per the design discussion).

## Diagnostics baseline

Passive preservation only:

- Rewriter preserves `SourceLocation` on emitted AST nodes (already true in v1).
- IR pass calls `copyMetadata()` whenever it substitutes an instruction, so `!dbg` survives lowering of substituted instructions.

**No active diagnostic emission in Phase 1.** Source-location-precise error reporting at use-site (e.g., for non-reversibilizable operations) becomes a real concern in Phase 5; Phase 1 just commits to not destroying the metadata Clang gives us.

## Testing

Three layers from day one:

### Layer 1 — End-to-end (acceptance contract)

Golden call-log per CQ program. A small set of fixtures under `tests/e2e/` (path TBD at impl), each consisting of:

- `input.c` — CQ source
- `expected.log` — byte-exact golden of the running binary's stdout

The test harness invokes `cqc input.c -o bin`, runs `./bin`, and `diff`s against `expected.log`. Any deviation fails the test.

**Acceptance:** the worked-example program ([`docs/example.md`](../../docs/example.md)) + at least one mixed-operand variant + at least one multi-decl variant ship as e2e fixtures, all green.

### Layer 2 — Rewriter unit tests (debug aid)

Extend `transpiler/tests/unit/` with goldens on the rewriter's emitted C for each pattern in the supported-rewrites table above. v1's existing unit tests get repointed to the new emission targets (`qint_t` → `qint_mid_t`, `init_qint` → `cq_init_i32`, etc.).

### Layer 3 — IR pass unit tests (debug aid)

LLVM `lit` + FileCheck-style tests, productionized from `prototype/test/`. Each test consists of:

- `input.ll` — hand-written / Clang-emitted IR fragment
- FileCheck directives asserting the pass produces the expected `cqrt_*` / `cq_template_*` call sequence

When end-to-end goldens fail, Layers 2 and 3 are how we localize whether the rewriter or the IR pass is at fault.

## Out of scope (deferred to later phases)

| Phase | Item |
|---|---|
| 2 | Other widths (`quantum char`, `quantum short`, `quantum long`, `quantum bool`, `quantum float`, `quantum double`); other `cq_init_*` / `cq_measure_*` variants |
| 3 | All operators except `+`; XOR-copy (and in-place add semantics); structural copy/swap; classical-mask views; mixed-width promotion |
| 4 | `if (q_cond)` → `cq_when_*` regions; controlled templates |
| 5 | Auto uncomputation; inverse-template emission; non-`main` scope handling; real diagnostics |
| 6 | `for` loops with classical bounds |
| 7 | User-defined quantum functions; `invert(...)` |
| 8 | Quantum arrays; QRAM; pointer aliasing |
| 9 | `struct` / `union` / `_Complex` / remaining C surface |
| 10 | Quantum-conditioned `while` |
| 11 | Frontend freeze; ABI lock; CMake macro polish; binary `cqc` driver; MLIR re-evaluation |
| Backend | Real `cq_template_*` gate-sequence bodies; real `libcq_runtime` (OpenQASM / simulator / hardware); classical simulation in the stub runtime |

## Deliverables

### New files

- `include/CQ.h` — user-facing header (quantum macro only; deliberately minimal)
- `include/cq_mid.h` — transpiled-C ABI header (`qint_mid_t` + Phase 1 intrinsic decls); emitted into rewriter output, never `#include`d by authors
- `runtime/libcq_runtime.c` + header — stub trace-only runtime (path TBD)
- `runtime/cq_templates.c` + header — stub trace-only template library (just `cq_template_add_i32`)
- `ir-pass/CQPass.cpp` (or similar; productionized `prototype/cq_pass.cpp`) — LLVM new-PM pass plugin
- `ir-pass/CMakeLists.txt`
- `ir-pass/test/` — LIT + FileCheck tests
- `tests/e2e/` — top-level end-to-end golden fixtures and harness (`run_e2e.sh` or equivalent)
- `tools/cqc` — shell driver script

### Modified files

- `transpiler/src/{Codegen,DeclStmtRewrite,Matcher,TypeMap,...}.cpp` — emission targets change from v1's `qint_t`/`init_qint`/`add` to the new intrinsic surface; rewriter logic for Pattern 5 (cast → `cq_measure_i32`) added
- `transpiler/tests/unit/` — goldens repointed to new emission
- `transpiler/tests/e2e/` — existing v1 e2e fixtures either repointed to the new pipeline (acceptable since they exercise the v1 patterns Phase 1 supersedes) or retired with equivalent coverage moving to `tests/e2e/`
- Top-level `CMakeLists.txt` — orchestrate sub-builds (transpiler + ir-pass + runtime + templates)
- `docs/example.md` — rewritten to match architecture's current per-width intrinsic surface (currently stale; pre-2026-05-22 form)

### Retired

- v1's `qint.h` (stub `qint_t` backend header) — superseded by `CQ.h` + the new stub runtime
- The user-source `#define quantum …` line in fixtures — replaced by `#include <CQ.h>`

## Acceptance criteria

Phase 1 is done when **all** of the following hold:

1. `cqc <fixture>.c -o <fixture>` builds end-to-end against a local LLVM/Clang dev install, producing a runnable binary.
2. The worked-example program (`docs/example.md`'s Stage 1 source, written through CQ.h) builds and runs; its stdout matches a golden call log byte-for-byte.
3. v1's e2e fixtures, repointed to the new pipeline, all pass under the same golden-comparison protocol. Any fixture that exercised a pattern Phase 1 doesn't yet support (e.g., a v1 fixture using `amplitude(...)`) is documented as deferred, not silently dropped.
4. Layer 2 (rewriter unit) and Layer 3 (IR pass unit) test suites are green.
5. `docs/example.md` is updated to match the surface Phase 1 actually implements.

## Open items (decided in implementation)

These do not block PRD acceptance but are tracked as in-flight implementation decisions:

- Exact textual format of stub-call trace lines (will be pinned by the first golden fixture).
- Exact path layout for `ir-pass/`, `runtime/`, and `tests/e2e/` (the PRD commits to *some* such layout; specific paths are an impl choice).
- Concrete signature of `cq_template_add_i32` (single template call per `add`; argument shape — handles only? handles + width? — TBD).
- Specific `opt` pass invocation pipeline (`-O1` before our pass, or `mem2reg` + `sroa` only? Cheaper option may suffice for Phase 1).
- Mangling discipline for future-phase intrinsics already declared in CQ.h vs. minimal-now-extend-later (CQ.h is deliberately minimal in Phase 1; later phases extend).

## References

- [`ROADMAP.md`](../../ROADMAP.md) — Phase 1 phase definition
- [`docs/architecture.md`](../../docs/architecture.md) — §3 (three-level qint_t), §5 (rewriter responsibilities), §6 (intrinsic surface), §7 (IR pass responsibilities), §12 (open design questions)
- [`docs/example.md`](../../docs/example.md) — worked example (note: currently stale relative to architecture; Phase 1 deliverable updates this)
- [`docs/backend.md`](../../docs/backend.md) — runtime ABI sketch (Phase 1's stubs are trace-only against an unfrozen ABI; freeze is Phase 11)
- [`phases/v1/PRD.md`](../v1/PRD.md) — predecessor; Phase 1 supersedes the v1-era rewriter targets while inheriting its `quantum` recognition mechanism

## Task tracking

Implementation work is tracked in **beads** (`bd`) per project convention. This PRD is the design ground truth; the in-flight work breakdown is the issue tracker. No markdown TODO lists, no `TaskCreate` — see [`CLAUDE.md`](../../CLAUDE.md).
