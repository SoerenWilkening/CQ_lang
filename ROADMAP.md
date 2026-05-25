# CQ Roadmap

Phase-by-phase trajectory toward a feature-complete CQ **frontend**, under the
pipeline architecture settled 2026-05-21 / 2026-05-22. Companion to:

- [`docs/architecture.md`](docs/architecture.md) — front-end pipeline,
  intrinsic surface, IR pass design (P1–P9)
- [`docs/backend.md`](docs/backend.md) — Stage 4 → binary half of the
  pipeline (handle ABI, template library, runtime ABI; B1–B6)
- [`docs/example.md`](docs/example.md) — worked example through Stage 4
- [`docs/quantum-classical-handling.md`](docs/quantum-classical-handling.md)
- [`docs/bennett-jl-comparison.md`](docs/bennett-jl-comparison.md)
- [`docs/llvm-fork-analysis.md`](docs/llvm-fork-analysis.md)
- [`docs/pipeline-sketch.md`](docs/pipeline-sketch.md)

This roadmap replaces the v1-era roadmap (preserved in git history). The v1-era
plan assumed source-to-source rewriting was the end product; under the new
pipeline, the rewriter emits transpiled C that Clang compiles to LLVM IR, which
the CQ IR pass lowers to runtime-call IR, which links into a binary that
(eventually) emits a circuit.

**Document posture.** This file is a guideline for future discussion. Each
phase carries enough detail to know what falls inside it and what's deferred;
PRDs and implementation plans are designed at the start of each phase, not in
advance.

---

## Design principles (cross-cutting)

1. **Frontend first; backend stays stubbed.** Phases 1–10 build out the
   rewriter, the IR pass, and the *declarations* of the runtime / template
   surface. Concrete `cqrt_*` runtime variants and concrete `cq_template_*`
   gate-sequence bodies are `printf`-name stubs throughout. Real backend
   implementation is a separate effort that begins after frontend freeze
   (Phase 10).

2. **Compile-time uncomputation, per-op.** Adjoints are emitted by the
   compiler at compile time, per quantum value's SSA live-range end. No runtime
   tracking, no Bennett-style wrap-the-whole-call (except internally at
   function-boundary specialization, see architecture.md §7.7).

3. **Type-dispatched semantics via taint propagation.** Whether an
   instruction is "quantum" is decided per-instruction in the IR pass by
   forward taint from `@cq_init` results and `q*_mid_t`-typed parameters.
   The same `add i32` is quantum or classical depending only on whether its
   operands are tainted — no function-level annotation, no per-operator
   variants in the rewriter.

4. **Forward + controlled templates per primitive; adjoints derived.**
   Each primitive opcode ships forward + controlled-forward stubs. Adjoint
   and controlled-adjoint are produced mechanically by `emit_inverse`
   (architecture.md §7.6 / backend.md §5.8) — at template-call granularity
   while bodies remain stubs; at gate-sequence granularity once bodies are
   real.

5. **C philosophy: no foot-gun protection.** The language does not stop the
   user from writing nonsense. Enforced errors are physics-imposed
   (no-cloning) or unavoidable (non-adjointable use-site when uncomputation
   is required).

6. **No-cloning is physics, not policy.** `quantum T a = b;` emits XOR-copy
   (CNOT-based), which entangles. Documented, not guard-railed.

7. **Measurement happens at cast.** `(int) q`, `(float) q`, etc. are the
   only ways to extract a classical value.

8. **CQ.h is the only user-facing header.** Lightweight; declares the
   `quantum` keyword and the `@cq_*` intrinsic surface (architecture.md §6).
   Backend headers from the v1 era (`qint.h`) are obsolete — compiled
   binaries link against `libcq_runtime` instead.

9. **No LLVM fork, no MLIR dialect.** The entire pipeline is implementable
   as a libtooling rewriter + an out-of-tree LLVM pass plugin against stock
   LLVM. Validated by the Phase 0 prototype. MLIR re-evaluation is
   explicitly deferred to Phase 10 against the four triggers in
   architecture.md §11.

---

## Phase 0 — Architecture validation and v1 [DONE]

The starting state of the new roadmap.

**Architecture settled** (2026-05-21 / 2026-05-22):
- Pipeline design fixed: AST rewriter → Clang → CQ IR pass → libcq_runtime
- Intrinsic surface fixed: six families, per-width init / measure variants
  (architecture.md §6)
- Handle-based runtime ABI fixed (backend.md §B1 / §6)
- Three-level `q*_mid_t` model fixed (architecture.md §3 / backend.md §4)
- MLIR rejected for Phases 1–10 (architecture.md §11)
- LLVM fork rejected (docs/llvm-fork-analysis.md)

**v1 rewriter** (basic `quantum int`, single `+`, transpiled-C output):
- Operational; fixtures 04–08 green
- Surface form: manual `#define quantum`, `init_qint` / `add` stub backend
- Lives under `transpiler/` + `phases/v1/`; PRD frozen at
  `phases/v1/PRD.md`

**Prototype passes** (`prototype/`, 525 LOC C++ against stock LLVM 19.1.7):
- `cq-lowering` — taint propagation, mid-struct → handle rebinding,
  template-call lowering for the worked example (i32 add only)
- `cq-uncompute` — PostDominatorTree-based last-use analysis (linear and
  branched CFG); `cqrt_free` insertion at the post-dominating merge block
- `cq-specialize` — `CloneFunction` + `ValueToValueMapTy` + mangled-name
  retargeting at call sites
- `cq-control` — `cq_when_begin`/`cq_when_end` region detection;
  substitution of `cq_template_*` calls inside regions with `_ctrl`
  variants (linear single-BB regions)

The prototype validates every architecturally novel LLVM-API mechanism the
architecture / backend documents call for. It is **not** the production
implementation of any phase — production versions of these passes are
reached incrementally through Phases 1–7. Its role going forward is as the
starting point of the IR-pass code for Phase 1.

---

## Phase 1 — First end-to-end vertical slice [DONE]

**Landed 2026-05-24.** The worked-example program compiles end-to-end
through the new pipeline and runs, producing the golden call-trace log
under `tests/e2e/`. Specifically:

- **Rewriter** (`transpiler/`): emits the new intrinsic surface
  (`qint_mid_t`, `cq_init_si32`, `cq_measure_si32`); collapsed v1's
  per-operand `Form` enum to `Uninit` / `ClassicalInit` / `QuantumAdd`;
  new `CastRewrite` module for measurement-as-cast. (Mid-level
  intrinsics carried width-only `_i32` suffix at Phase 1 land; Phase 2
  M3 repointed them to the signedness-bearing `_si32` suffix.)
- **IR pass** (`ir-pass/libCQPass.so`): productionized `cq-lowering`
  slice of the prototype — forward taint propagation, mid-struct →
  handle rebinding, lowering of `cq_init_si32` / tainted `add i32` /
  `cq_measure_si32`. Q+Q vs Q+C add dispatch via `cq_template_add_i32_hl`
  (mixed-operand) keeps classical literals as bare integers through the
  ABI — classical operands are never promoted to handles.
- **Headers** (`include/`): user-facing `CQ.h` (just the `quantum`
  macro); transpiled-C ABI in `cq_mid.h` (`qint_mid_t` +
  `cq_init_si32` + `cq_measure_si32`).
- **Stub runtime** (`runtime/libcq_runtime.a` + `libcq_templates.a`):
  trace-only `cqrt_alloc_i32`, `cqrt_measure_i32`, `cqrt_free`,
  `cq_template_add_i32`, `cq_template_add_i32_hl`. (Phase 2 M3
  collapsed Phase 1's classical-alloc symbol + the planned fresh-ancilla
  zero-arg variant into the single value-taking `cqrt_alloc_i32`.)
- **`cqc` driver** (`tools/cqc`): orchestrates the four pipeline stages
  (rewriter → `clang -O1 -emit-llvm` → `opt -passes=cq-lowering` →
  link). `--emit-ll` exposes text LLVM IR intermediates; honors
  `LLVM_PREFIX` for Homebrew layouts.
- **Tests**: four e2e fixtures (`worked_example`, `mixed_operand`,
  `multi_decl`, `full_example`) under `tests/e2e/`, all green; v1's
  rewriter fixtures (01–07) repointed to the Phase 1 emission and
  still green; rewriter unit tests (GTest) and IR-pass LIT/FileCheck
  tests green.

The Phase 1 contract follows below; preserved as written for the
historical record. PRD + implementation plan: `phases/phase1/PRD.md`,
`phases/phase1/PLAN.md`.

---

**Goal.** A CQ source file of the worked-example shape (docs/example.md)
compiles end-to-end and runs, producing a log of runtime calls via stub
`libcq_runtime`. This is "v1 ported onto the new architecture" — the
minimum viable end-to-end pipeline.

**Scope.** Only the v1-equivalent feature subset, but flowing through the
full new pipeline rather than stopping at transpiled C.

**Components touched:**
- **Rewriter** (extends v1): emit the new `@cq_*` intrinsic surface for
  the v1 feature subset:
  - `quantum int x = N;` → `qint_mid_t x = cq_init_si32(N);`
  - `quantum int z = a + b;` → `qint_mid_t z; z.val = a.val + b.val;`
  - `(int) q` → `cq_measure_si32(q)`
  - Replaces v1's `init_qint` / `add` stub calls with the new intrinsics
- **IR pass** (productionizes prototype's `cq-lowering` slice for i32):
  taint, mid→handle rebinding, lowering of `@cq_init_si32` / tainted
  `add i32` / `@cq_measure_si32` to `cqrt_*` calls
- **CQ.h** (replaces user `#define quantum`): declares `quantum` keyword
  + the four intrinsics this phase needs (`cq_init_si32`, `cq_measure_si32`,
  the `qint_mid_t` struct type — others added in Phase 2)
- **Stub `libcq_runtime`** (new): printf-name impls of
  `cqrt_alloc_i32`, `cqrt_free`, `cqrt_measure_i32`
- **Stub template library** (new): printf-name impls of
  `cq_template_add_i32` (Q+Q) and `cq_template_add_i32_hl` (Q+C
  mixed-operand; IR pass dispatches on taint-set membership)
- **Build flow** (new): `.c` → rewriter → `clang -emit-llvm` → `opt`
  (CQ pass plugin) → `clang` link against stub runtime → binary →
  `./binary` prints call log

**Done when:** the worked-example program (docs/example.md) builds and
runs end-to-end, output matches the expected call-sequence log, and v1's
fixture suite continues to pass.

**Open items (defer to Phase 1 PRD):** how the rewriter integrates with
the existing v1 codebase (extend in place vs. parallel directory).
Diagnostic location preservation (`!dbg`) baseline.

---

## Phase 2 — Type system breadth + entry-point `CQ.h`

**Goal.** Every integer + floating-point width is first-class. CQ.h
consolidates as the single user-facing header.

**Scope.**
- Integer widths: `quantum char`, `quantum short`, `quantum int`,
  `quantum long`, `quantum long long`, signed + unsigned
- `quantum _Bool` / `quantum bool` (single-qubit, structurally 1-bit
  unsigned)
- `quantum float`, `quantum double` (first-class per backend.md §3.3 —
  *not* stubs; only the per-opcode gate templates are deferred)
- Measurement-at-cast for all widths (`cq_measure_<W>` family per
  architecture.md §6.2)
- Assignment via XOR-copy (CNOT-based)
- CQ.h: full intrinsic-surface declarations (six families per
  architecture.md §6)

**Components touched:**
- Rewriter: width-keyword recognition; per-width `@cq_init_*` /
  `@cq_measure_*` emission
- IR pass: width-parametrized taint propagation, mid→handle rebinding,
  init/measure lowering (i1 / i8 / i16 / i32 / i64 / f32 / f64)
- Stub runtime: `cqrt_alloc_<W>` / `cqrt_alloc_classical_<W>` /
  `cqrt_measure_<W>` per width
- Stub templates: `cq_template_add_<W>` per width

**Out of scope:** float-template Bennett-wrap internals (backend
implementation); `_Float16` / `long double` (deferred per backend.md §3.3);
`_Complex` (falls out from float — Clang lowers it to scalar pairs at IR,
no new intrinsic surface).

**Done when:** all width / type combinations of the Phase 1 worked-example
shape compile and run end-to-end with correct stub-call logs.

---

## Phase 3 — Full operation set

**Goal.** Every quantum-touching arithmetic / bitwise / comparison / unary /
cast operation flows through the pipeline and is identified by taint
propagation; each lowers to its template-call stub.

**Scope (operators; full C surface):**
- Arithmetic: `+`, `-`, `*`, `/`, `%`, plus compound forms
- Bitwise: `<<`, `>>`, `|`, `&`, `^`, plus compound forms
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=` — produce a flag handle;
  Phase 4 if-condition lowering depends on these
- Unary: `-` (negate), `~` (bitwise NOT), `!` (logical NOT), `++` / `--`
- Structural: XOR-copy (CNOT), swap

**Components touched:**
- Rewriter: emits stock C arithmetic on `.val` fields — no per-operator
  code path. The Phase 3 rewriter scope is small precisely because taint
  propagation handles QQ / QC / mixed uniformly.
- IR pass: taint extended over the full ~38 LLVM data opcodes (int +
  fp arith, bitwise, compare, cast); template-call substitution per
  tainted opcode
- Stub templates: `cq_template_<op>_<W>` per (opcode, width); **forward
  + controlled-forward variants** (Phase 4 needs the controlled ones).
  Inverse stubs (`cq_template_<op>_<W>_inv`) declared here for Phase 5
  consumption.

**Sub-items kept from old roadmap:**
- **3.3 Classical-mask views (`q & C`).** Zero-cost bit-view semantics
  for `q & C` where `C` is classical. View on rvalue use; materialize on
  binding to a fresh qint (CNOT-copy of aliased bits). IR-pass-level
  responsibility; bind-site detection via SSA use position.
- **3.4 Mixed-width type promotion.** Free under the new architecture —
  Clang lowers C standard widening to `sext` / `zext` / `trunc`, taint
  propagates through them, templates for those opcodes handle the rest.

**Done when:** programs using the full operator set across mixed quantum /
classical operands produce expected template-call sequences.

---

## Phase 4 — Quantum control flow: `if`

**Goal.** Type-dispatched `if`: classical condition → unchanged C;
quantum condition → controlled-region semantics on all body ops.

**Scope.**
- Rewriter: `IfStmt` with quantum-typed condition →
  `cq_when_begin(_cond); ...; cq_when_end()`. Mixed conditions
  (any quantum subexpression → whole condition is quantum). Nested ifs:
  rewriter emits nested regions; IR pass accumulates controls.
- IR pass (productionizes prototype's `cq-control`): region detection
  extended to multi-BB and nested regions; each `cq_template_*` call
  within a region substituted with its `_ctrl` variant, control handle
  prepended.

**Constraint:** every operation reachable inside an `if` body must have a
controlled-form stub (Phase 3 deliverable).

**Done when:** programs with quantum if-statements (including nested,
including mixed-condition) produce expected controlled-template-call
sequences.

**Open items (defer to Phase 4 PRD):** Sturm-style distinct `when`
keyword vs type-dispatched `if` (architecture.md §12 q1). Resolution
depends on Phase 7 function-lifting interaction.

---

## Phase 5 — Auto uncomputation

**Goal.** Per-op compile-time adjoint emission at SSA live-range ends of
tainted handles. The transpiler's diagnostic story begins here.

**Scope.**
- IR pass (productionizes prototype's `cq-uncompute` past the
  `cqrt_free`-placeholder stage): for each tainted handle, find last use
  via SSA def-use graph (or `@llvm.lifetime.end` for stack slots that
  survive flattening); emit the inverse template-call sequence at the
  post-dominating merge block; emit `cqrt_free` after.
- Exceptions (no uncomp emitted):
  - enclosing function is `main` (no caller to clean up before)
  - handle escapes via return-by-value (callee preserves it)
  - handle is explicitly handed off via a `cq_invert_*` region
- Diagnostics: source-location-preserved error at use-site when
  uncomputation is required of a non-adjointable result. v1's
  silent-fail-on-unsupported posture ends here.

**Note on `emit_inverse` granularity.** While templates are stubs (through
Phase 10), `emit_inverse` walks the *template-call sequence* and emits
inverse template-calls (`cq_template_<op>_<W>_inv`, declared in Phase 3).
Once templates are real (post-Phase-10), the same `emit_inverse` walks the
*gate sequence* inside templates. The IR-pass-level mechanism is
identical at both granularities.

**Done when:** programs with non-`main` scopes (inner blocks, soon-to-come
function calls) produce expected inverse-template-call sequences at scope
exits.

**Open items (defer to Phase 5 PRD):** behavior on non-reversibilizable
use (hard error vs. implicit measurement bridge — architecture.md §12 q3
/ backend.md §10 q1). Diagnostic-location fidelity baseline against the
IR pipeline (architecture.md §12 q8).

---

## Phase 6 — For-loops (classical bounds)

**Goal.** Quantum data in the loop body; classical loop variable and
bounds.

Mostly "free" from the new architecture:
- **Compile-time constant bound:** Clang may unroll, or leave intact — both
  fine; runtime accumulates per iteration either way.
- **Non-const classical bound:** Clang lowers to an IR loop; IR pass
  leaves it intact; runtime accumulates per iteration → flat circuit at
  program startup.
- **Runtime-dynamic bound (measurement-derived):** dynamic circuits; out
  of scope here.

Largely a validation phase: tests covering loop shapes; no new IR-pass
mechanism beyond confirmation that taint / uncomputation analyses
compose correctly with loop structure.

**Done when:** loop fixtures with all three bound styles produce expected
call sequences.

---

## Phase 7 — User-defined quantum functions + inversion

**Goal.** Function definition, call, structural adjoint derivation,
manual `invert(...)` surface.

**Scope (function semantics).**
- Quantum / classical parameters and return values
- By-value qint passing: caller-side CNOT-copy onto fresh callee qubits
- By-reference qint passing: alias passing (callee operates on caller's
  qubits directly)
- Return-by-value qint: caller-side materialization (same model as
  Phase 3.3 view materialization)
- Calls inside a controlled body: emit controlled forms of callee's
  body ops; missing controlled form → compile error at call site

**Components touched:**
- Rewriter: call sites with `qint_mid_t`-typed args → mangled
  `__cq_q_<f>_<argmask>(...)` call; `invert(F)(args)` →
  `__cq_invert_<F>(args)` mangled call (surface form chosen at PRD time
  per architecture.md §12 q2)
- IR pass (productionizes prototype's `cq-specialize` past
  signature-preserving stage): worklist-driven specialization discovery;
  full reversibilizability classifier (architecture.md §7.3); synthesis
  of `__cq_q_<f>_<mask>` bodies via per-op template substitution +
  Bennett wrap at function boundary (forward + CNOT-copy of return +
  reverse); caching by `(function, argmask)`; `__cq_invert_<f>`
  synthesis via `emit_inverse` on the forward
- Stub `libm.bc`: declarations only initially — classifier rejects, user
  sees diagnostic; first basic-math entries (e.g., `pow` integer-power
  specializations) added incrementally

**Done when:** programs with user-defined quantum-arg functions
(including recursive specialization, including explicit `invert(...)`)
produce expected mangled-call → specialization → template-call
sequences. Reversibilizability classifier rejections produce
source-location diagnostics.

**Open items (defer to Phase 7 PRD):** failure mode on
non-reversibilizable callee (architecture.md §12 q3). Auto-specialization
scope: every reachable function, or opt-in only (§12 q4). Concrete
mangling scheme (§12 q6).

---

## Phase 8 — Memory: arrays and pointers

**Goal.** Quantum arrays, classical and quantum indexing, pointer
semantics for quantum data.

**Scope.**
- Classical-indexed quantum arrays: straightforward per-element handle
  addressing
- Quantum-indexed access (`arr[q]`): QRAM call. QRAM body is a stub
  template; semantics designed here.
- Pointer semantics for quantum data: aliasing rules, lifetime,
  address-of behavior — designed coherently with Phase 3.3's view
  aliasing (the first instance of qubit-level aliasing in the language)
- Array-of-quantum vs quantum-of-array: scope clarified at PRD time

**Components touched:**
- Rewriter: array decl + indexing AST handling for quantum types;
  pointer-to-quantum
- IR pass: LLVM alias analysis; Bennett-style memory strategies (Shadow
  / MUX / QROM) selectable per allocation site
- Stub: `cqrt_qram_*` family; `cqrt_alloc_array_<W>`

**Done when:** array programs with both classical and quantum indexing
patterns produce expected (stubbed) memory-template-call sequences.

---

## Phase 9 — Remaining C language surface

**Goal.** Mechanical AST handling for the rest of C; no new quantum
semantics introduced.

- `struct` (including with quantum-typed members)
- `union`, `typedef`, `enum`
- Storage classes, qualifiers
- `_Complex` / `_Imaginary`: surface only; Clang lowers `_Complex T`
  to `{T, T}` at IR, so it falls out from Phase 2's float support
- Other C99 / C11 features as they surface

Most "just works" from Clang; rewriter needs only new AST-pattern
recognition for quantum-typed members inside aggregates.

**Done when:** the rewriter handles the full C99/C11 surface for any
program where quantum types appear, and the existing IR-pass machinery
needs no new mechanism to absorb the additional AST shapes.

---

## Phase 10 — Quantum-conditioned while loops

**Goal.** Frontend handling for `while` with a quantum-typed condition.
Design pinned down at PRD time — kept as its own phase because the
semantic choice (amplitude amplification, transform-to-bounded-for,
measure-and-classical-branch, or something else) is a real design problem
with cross-cutting implications, not a mechanical add-on.

**Scope (frontend only).**
- Rewriter: `WhileStmt` with quantum-typed condition → region brackets
  (likely `cq_while_begin` / `cq_while_end` by analogy with `cq_when_*`,
  but exact surface decided at PRD)
- IR pass: detect / lower the new region per the chosen semantic model
- Stub: a placeholder runtime entry-point (naming + signature TBD at PRD)

**Out of scope.**
- Real amplitude-amplification template body, or whatever the chosen
  semantics requires at the gate level (backend implementation; see
  "Beyond the frontend")
- Runtime-dynamic bounds derived from measurement (dynamic circuits;
  post-backend)

**Open items (the substance of Phase 10's PRD):**
- *Surface*: expose raw `while(q_cond)` to the user, or require an
  explicit `amplify(...)` / `oracle(...)` form?
- *Semantics*: amplitude amplification vs. transform-to-bounded-for
  vs. bounded-iteration vs. measure-and-classical-branch
- *Cross-implications with Phase 7*: amplitude-amplification
  implementations typically take an oracle as a function argument —
  whether q-while bodies need to wrap as functions affects both surface
  and IR-pass shape

**Why separate from the freeze (Phase 11).** Either of two outcomes is
plausible: q-while ships at frontend freeze on the strength of the
chosen design, *or* q-while is judged too speculative to lock and is
deferred past freeze with an explicit "not yet supported" diagnostic.
Carving it as a distinct phase keeps that decision visible.

**Done when:** the chosen surface + semantics is implemented in the
rewriter + IR pass with stub-runtime hooks, and programs exercising
quantum-while produce the expected (stubbed) call sequences. The
verdict on whether to include q-while in the freeze is also reached
here.

---

## Phase 11 — Frontend freeze + handoff to backend implementation

**Goal.** Lock in the frontend surface and ABI; explicit gate before
backend implementation begins.

**Deliverables.**
- **CQ.h intrinsic-surface freeze.** Semver pinned; future additions
  versioned per the freeze policy.
- **`libcq_runtime` ABI freeze.** Symbol versioning per backend.md §6.7;
  `cqrt_abi_version()` query function; documented deprecation policy.
- **Diagnostic-fidelity audit.** Which optimization passes the `!dbg`
  metadata survives; baseline acceptable for the diagnostic story
  established in Phases 5 / 7 (architecture.md §12 q8).
- **MLIR re-evaluation gate.** Explicit decision against the four
  trigger conditions in architecture.md §11. If at least one fires,
  post-freeze scope expands to MLIR adoption; otherwise the intrinsic
  approach is locked.
- **Validation harness.** End-to-end CQ programs covering the full
  Phases 1–10 feature surface (or Phases 1–9 if Phase 10 is deferred
  past freeze per its own verdict), each producing the expected
  stub-runtime call log. The harness becomes the regression suite for
  backend implementation.

**Done when:** all deliverables ship, the regression harness is
green, and the architecture / backend / CQ.h / libcq_runtime documents
carry a "v1.0 frozen" marker.

---

## Beyond the frontend (out of scope for this roadmap)

Sketched here only as pointers; phasing for these is the subject of the
post-Phase-10 roadmap revision.

- **Backend implementation.** Real `cq_template_<op>_<W>` gate-sequence
  bodies for the 38-opcode reversible template library (backend.md §7).
  Real `libcq_runtime` variants: OpenQASM emitter, in-memory circuit
  object, eager statevector simulator, density-matrix simulator, hardware
  transport (backend.md §6.6). Float templates with internal
  Bennett-wrap for rounding-induced information loss (backend.md §3.3 /
  §7).
- **Quantum-while backend.** The gate-level realization of whatever
  Phase 10 settled on as the q-while semantics — likely an amplitude-
  amplification template (with Grover-style iteration count derived from
  the chosen surface), or the lowering for transform-to-bounded-for.
  Cleanly separable from the frontend half precisely because Phase 10
  freezes the surface + the runtime hook.
- **Optimization passes** (old roadmap §11). Gate cancellation,
  adjacent-gate fusion, ancilla reuse across non-overlapping lifetimes,
  T-count / depth targeting. Some pieces feasible at template-call
  granularity under stubs (e.g., adjacent inverse cancellation:
  `cq_template_X` immediately followed by `cq_template_X_inv` collapses);
  the full set requires real backend.
- **Cross-language input.** `clang -emit-llvm`'d Rust, Fortran, etc.
  participate in auto-specialization (architecture.md §P9). LTO
  discipline, canonical `libm.bc` distribution.
- **Dynamic circuits.** Measurement-derived loop bounds; mid-circuit
  measurement feedback. Out of scope until post-backend.

---

## Sequencing notes

- Phases 1 → 5 are tightly coupled and form the "make CQ look like real C
  with quantum types" core. Type system (2) extends Phase 1's i32-only
  slice; operation breadth (3) needs all widths; quantum `if` (4) needs
  Phase 3's controlled-template stubs; uncomputation (5) needs Phase 3's
  inverse-template stubs.
- Phases 4 and 5 can be developed in parallel after Phase 3 lands.
- Phase 6 (for-loops) is largely free of new IR-pass mechanism and can
  slot in any time after Phase 1.
- Phase 7 (user-defined functions + inversion) is the second major
  IR-pass workstream after uncomputation; consumes the Phase 0 prototype
  `cq-specialize` slice.
- Phase 8 (memory) introduces QRAM as a new stub surface but is
  independent of Phases 4 / 5 / 7 and can be parallelized.
- Phase 9 (remaining C) is mostly mechanical and parallelizable.
- Phase 10 (quantum-while) is the last design-heavy phase before the
  freeze; its outcome (ship at freeze vs. defer past freeze) is itself
  one of Phase 10's deliverables.
- Phase 11 is a freeze + gate; nothing else lands before it.
  Post-Phase-11 work is designed under a future roadmap revision.
