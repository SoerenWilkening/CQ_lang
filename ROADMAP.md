# CQ Roadmap

Phase-by-phase trajectory toward a feature-complete CQ **frontend** under
the taint-driven pipeline design. Companion to:

- [`docs/frontend.md`](docs/frontend.md) — user-facing intrinsic surface
  (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the
  Clang/`-O1` pipeline that prepares the IR
- [`docs/backend.md`](docs/backend.md) — IR pass and runtime ABI; the
  load-bearing half of the pipeline
- [`docs/quantum-classical-handling.md`](docs/quantum-classical-handling.md)
  — taint as the Q/C boundary, mixed-operand semantics
- [`docs/llvm-implementation.md`](docs/llvm-implementation.md) — stock
  LLVM C++ APIs every mechanism depends on
- [`docs/example.md`](docs/example.md) — end-to-end worked walkthrough
- [`docs/bennett-jl-comparison.md`](docs/bennett-jl-comparison.md)
- [`docs/rationale/proposal-taint-driven-pipeline.md`](docs/rationale/proposal-taint-driven-pipeline.md)
  — proposal that motivated the current design

This roadmap replaces the v1-era roadmap (preserved at
[`docs/archive/old-design/ROADMAP.md`](docs/archive/old-design/ROADMAP.md)).
The v1-era plan assumed a libtooling AST rewriter producing transpiled C
plus a `quantum` keyword + cast-as-measurement source surface; the new
design retires the rewriter and the keyword in favor of a header-only
intrinsic surface lowered entirely in the IR pass.

**Document posture.** This file is a guideline for future discussion.
Each phase carries enough detail to know what falls inside it and what's
deferred; PRDs and implementation plans are designed at the start of each
phase, not in advance.

---

## Design principles (cross-cutting)

1. **Taint is the only Q/C boundary.** A `quantum` keyword plays no role.
   An SSA value is quantum iff it is derived (transitively, via stock
   LLVM data flow) from a `@cq_theta_*` return. Every downstream
   distinction — allocation, opcode lowering, swap-route control,
   specialization, uncomputation — is driven by the same forward
   propagation (see [`docs/quantum-classical-handling.md`](docs/quantum-classical-handling.md)).

2. **Frontend is a header.** `CQ.h` declares three primitive families
   (`cq_theta`, `cq_phi`, `cq_measure`) plus one inversion bracket
   (`cq_invert_begin`/`_end`), each with per-type specializations and a
   `_Generic` dispatch macro. There is no rewriter, no AST pass, no
   custom parser — stock Clang compiles the source.

3. **Allocation is gate-triggered.** A `cqrt_alloc_<W>` is inserted only
   at the first `@cq_theta` whose operand is still classical. Variables
   declared but never rotated produce no qubits (see
   [`docs/backend.md`](docs/backend.md) §5).

4. **Compile-time uncomputation, per-op.** Adjoints emitted at each
   tainted handle's SSA last-use point, via `PostDominatorTree`. No
   runtime tracking; no Bennett-style wrap-the-whole-call except at the
   one boundary where it is load-bearing (call-graph specialization
   synthesis, §7).

5. **Function lifting without source modification.** A plain classical
   function with tainted arguments gets a specialization synthesized
   per-callsite by the IR pass. Two paths: curated symbol substitution
   for opaque externals (libm, intrinsics); clone-on-taint for visible
   bodies. The library author writes one body; quantum and classical
   callers share it.

6. **No source-level controlled-region brackets.** Tainted `br i1` /
   `select` / `switch` conditions identify the quantum-control region
   structurally via post-dominator analysis. The user writes plain C
   `if`; the pass recovers the **swap-route region** (Phase 4).

7. **Control by routing, not by controlling gates; adjoints derived.**
   Tainted control flow is lowered by routing data through `cqrt_cswap`
   (RSSA swap-route, Phase 4), so arm bodies run **verbatim and
   uncontrolled** — the pass needs **no `_controlled` variant per gate**.
   Coherence is restored by region-local **reverse-play** (the adjoint of
   the forward stream), produced mechanically by `emit_inverse`
   ([`docs/backend.md`](docs/backend.md) §10). The runtime ships **forward**
   templates; adjoints come from `emit_inverse`. (Controlled-forward
   variants are retained only for the optional §6a control-in-place
   peephole, not as the control mechanism — superseding the prior
   "forward + controlled-forward only" framing.)

8. **Width-only runtime ABI.** Signedness is implicit in the LLVM opcode
   (`add nsw` vs `add nuw`, `icmp slt` vs `icmp ult`); the frontend
   intrinsic surface carries signedness suffixes for source clarity; the
   IR pass strips signedness when emitting `cqrt_*` calls.

9. **No LLVM fork, no MLIR dialect.** Validated 2026-05-22 by working
   prototype against stock LLVM 19.1.7. MLIR re-evaluation explicitly
   deferred to Phase 11 freeze gate.

10. **C philosophy: no foot-gun protection.** The language does not stop
    the user from writing nonsense. Enforced errors are physics-imposed
    (no-cloning, measurement as the sole sink) or unavoidable
    (non-reversibilizable callee under the rejection set).

---

## Phase 0 — Inherited foundation [DONE]

The starting state of the new roadmap. Carried forward from the cleanup
that retired the rewriter and the old-design surfaces; documented here
as the substrate every subsequent phase builds on.

### What exists

- **IR pass** ([`ir-pass/`](ir-pass/), ~1000 LOC C++): `libCQPass.so`
  pass plugin exposing one pass (`cq-lowering`). Five width-parametric
  modules — `WidthDispatch`, `TaintPropagation`, `MidHandleRebind`,
  `OpcodeLowering`, `MeasureLowering` — plus a `Plugin.cpp`
  registration shim and a `CQLoweringPass.cpp` driver. Builds against
  stock LLVM 19 with no patches.
- **Prototype** ([`archive/prototype/`](archive/prototype/), 525 LOC C++): four passes
  validating no-fork architecture on stock LLVM 19.1.7 —
  `cq-lowering` (taint + lowering), `cq-uncompute`
  (`PostDominatorTree`-based last-use), `cq-specialize`
  (`CloneFunction` + `ValueToValueMapTy` retargeting), `cq-control`
  (region substitution via BB-tracking).
- **Runtime** ([`runtime/`](runtime/)): trace-only `libcq_runtime` with
  15 `cqrt_*` symbols (7 allocators + 7 measure + `cqrt_free`); 698
  declarations in `cq_templates.h` covering the 38-opcode surface ×
  applicable widths × `{HH, HL}` operand shapes, autogenerated from
  [`tools/opcode_table.yaml`](tools/opcode_table.yaml) via
  [`tools/gen_templates.py`](tools/gen_templates.py).
- **Headers** ([`include/`](include/)): user-facing `CQ.h` (currently
  carries the old-design `quantum` keyword macro); transpiled-C ABI
  `cq_mid.h` (currently carries the old-design `qint_mid_t` mid-struct
  family + `cq_init_*` / `cq_measure_*` intrinsics). **Both
  scheduled for replacement in Phase 1.**

### What is validated on stock LLVM 19.1.7

- Pass-plugin mechanism: `opt -load-pass-plugin libCQPass.so` loads and
  runs without crash; output passes `opt -verify`. New PassManager API,
  out-of-tree, no LLVM source modifications.
- Forward taint propagation: `Value::users()` + worklist data flow;
  monotone single-sweep over the SSA DAG.
- Post-dominator-driven uncomputation: `PostDominatorTree` via
  `FunctionAnalysisManagerModuleProxy`, `findNearestCommonDominator`
  over user blocks, correct on linear and multi-BB CFG without
  duplication; `ReturnInst` escape detection.
- Call-graph specialization: `CloneFunction` + `ValueToValueMapTy`,
  internal-linkage retargeting, `setCalledFunction` retarget at call
  sites.
- Controlled-form substitution: BB-tracking region detection with
  `_controlled` template substitution and control-handle prepending.
- Width fan-out: `WidthDispatch` covers all 5 integer widths
  (`i1`/`i8`/`i16`/`i32`/`i64`) + 2 fp widths (`f32`/`f64`).

### What needs adaptation under the new design

Mechanisms are validated; the IR these mechanisms run against changes:

| Old-design surface | New-design replacement | Module affected |
|---|---|---|
| `@cq_init_<sfx>` as taint source | `@cq_theta_<sfx>` as taint source | `TaintPropagation` |
| `qint_mid_t` struct wrappers in IR | Plain SSA scalars (no wrappers) | `MidHandleRebind` (becomes obsolete) |
| Declaration-triggered allocation | Gate-triggered (dispatch at `@cq_theta` on operand state) | `MeasureLowering` / new `AllocationLowering` |
| `@cq_when_begin` / `@cq_when_end` marker pairs | Structural detection from tainted `br i1` + `PostDominatorTree` | New `ControlledLowering` |
| `(int) q` cast-as-measurement | Explicit `@cq_measure_<sfx>` call | Frontend (Phase 1) — `MeasureLowering` already triggers on call symbol |

The cleanup work to land this transition (archive transpiler, restructure
docs, rewrite design docs, this ROADMAP itself) is tracked under the
umbrella issue
[`test_C_libtooling-jcd`](.beads/issues.jsonl). Code adaptation begins
at Phase 1.

---

## Phase 1 — New intrinsic surface in `CQ.h` [DONE]

**Goal.** Replace the old-design `CQ.h` (and obsolete `cq_mid.h`) with
the taint-driven intrinsic surface that
[`docs/frontend.md`](docs/frontend.md) specifies. Header-only deliverable;
no IR-pass code changes.

**Scope.**
- Declare 14 specializations × 3 primitive families (`cq_theta_<sfx>`,
  `cq_phi_<sfx>`, `cq_measure_<sfx>`) plus three `_Generic` dispatch
  macros (`cq_theta`, `cq_phi`, `cq_measure`).
- Declare `cq_invert_begin()` / `cq_invert_end()` as bracket markers
  (no-op signatures; the IR pass identifies them by name).
- Suffix convention per [`docs/frontend.md`](docs/frontend.md) §3.1:
  `_i1`, `_c`, `_si8`, `_ui8`, `_si16`, `_ui16`, `_si32`, `_ui32`,
  `_sl`, `_ul`, `_sll`, `_ull`, `_f32`, `_f64`.
- Retire `quantum` keyword macro, `qint_mid_t` family, `cq_init_*`
  family — the new design's surface is the only one.

**Components touched:**
- [`include/CQ.h`](include/CQ.h) — rewritten end-to-end.
- [`include/cq_mid.h`](include/cq_mid.h) — removed (no transpiled-C
  layer in the new design; the file becomes archive material).

**Done when:** a `#include <CQ.h>` followed by a `cq_theta(int_var,
0.5)` macro invocation compiles under stock Clang to a Stage 1 IR that
contains exactly one `@cq_theta_si32(i32, double)` call; symmetric
checks for `cq_phi` / `cq_measure`. Smoke fixture for each of the 14
specializations × 3 primitive families.

**Open items (defer to Phase 1 PRD):** whether to keep the existing
`include/cq_mid.h` filename as a deprecated alias that errors out at
compile time vs. delete outright. ABI stability of the suffix scheme
under platform-dependent `long` / `long long` widths.

---

## Phase 2 — IR pass: taint sources, gate-triggered allocation [DONE]

**Design:** see [`docs/prd/phase-02-taint-allocation/PRD.md`](docs/prd/phase-02-taint-allocation/PRD.md).

**Goal.** Re-point the existing `TaintPropagation` module from the
retired `@cq_init_*` source set to the new `@cq_theta_*` source set,
and introduce gate-triggered allocation at `@cq_theta` call sites.
First end-to-end vertical slice under the new design: a single source
file containing one `cq_theta` + one arithmetic op + one `cq_measure`
compiles, links against the trace runtime, runs, prints the expected
call sequence.

**Scope.**
- `TaintPropagation`: source set becomes `{ ret-value of any
  @cq_theta_<sfx> call }`; sink set becomes `{ @cq_measure_<sfx> call
  sites }`. `@cq_phi_<sfx>` propagates taint through its operand but is
  not a source. Algorithm and APIs unchanged — only the source-set
  predicate changes.
- New `AllocationLowering` module (or extension of existing
  `MeasureLowering`): for each `@cq_theta_<sfx>(operand, θ)` call,
  dispatch on `operand`'s taint state per [`docs/backend.md`](docs/backend.md)
  §5.1 — classical operand → insert `cqrt_alloc_<W>(operand)` then
  lower theta to `cqrt_ry_<W>(handle, θ)`; tainted operand → lower
  directly without re-allocation.
- `MidHandleRebind`: retired. The new IR contains no `qint_mid_t`
  structs; the module's `extractvalue`/`insertvalue` walking has no
  inputs and is removed.
- `MeasureLowering`: re-pointed from `@cq_measure_si32` (etc.) suffix
  family to the same suffix family but called on plain SSA scalars
  (no struct unwrapping). Width / signedness normalization
  ([`docs/backend.md`](docs/backend.md) §6.4) emits the width-only
  runtime symbol.
- Runtime: add `cqrt_ry_<W>` / `cqrt_rz_<W>` declarations (and `cqrt_x`,
  `cqrt_h`, `cqrt_cnot`, `cqrt_toffoli` placeholders per
  [`docs/backend.md`](docs/backend.md) §11.4); trace-only bodies.

**Done when:** a smoke fixture covering the Phase 2 surface
(`int x = 3; x = cq_theta(x, 0.5); int y = x + 1; int z = cq_measure(y);
return z;`) builds end-to-end, runs against the trace runtime, and
prints the expected `cqrt_alloc_i32(3)` → `cqrt_ry_i32(h0, 0.5)` →
`cq_template_add_i32_hl(h0, 1)` → `cqrt_measure_i32(...)` sequence.
Existing LIT fixtures repointed to the new source/sink set.

**Status (complete, 2026-05-31).** All done-criteria met. The canonical
smoke fixture [`slice_theta_add_measure`](tests/e2e/slice_theta_add_measure.c)
(`int x = 3; x = cq_theta(x, 0.5); int y = x + 1; int z = cq_measure(y);`)
builds end-to-end through the 4-stage pipeline (clang -O1 → opt cq-lowering →
link → run) and diffs clean against its golden, emitting exactly
`cqrt_alloc_i32(3)` → `cqrt_ry_i32(h0, 0.5)` → `cq_template_add_i32_hl(h0, 1)`
→ `cqrt_measure_i32(h1)` (e2e test `e2e-slice-theta-add-measure`, green).
`TaintPropagation` is repointed to the `@cq_theta_*` source / `@cq_measure_*`
sink set; gate-triggered allocation dispatches on operand taint (classical →
`cqrt_alloc_<W>` + `cqrt_ry_<W>`, tainted → no re-alloc); `MidHandleRebind` is
retired (no `qint_mid_t` in the new IR); `MeasureLowering` emits the width-only
runtime symbol. Superseded in practice by Phase 3, which generalizes the opcode
surface this slice's single `add_hl` first exercised.

---

## Phase 3 — IR pass: full opcode lowering [DONE]

**Design:** see [`docs/prd/phase-03-opcode-lowering/PRD.md`](docs/prd/phase-03-opcode-lowering/PRD.md)
and [`IMPLEMENTATION.md`](docs/prd/phase-03-opcode-lowering/IMPLEMENTATION.md).

**Goal.** Every quantum-touching arithmetic / bitwise / comparison /
unary / cast operation flows through the pipeline, identified by taint
propagation, lowered to its template-call. Width × signedness × operand
shape fan-out covered.

**Scope (the 38-opcode surface per
[`docs/backend.md`](docs/backend.md) §6.3):**
- Integer arith: `add`, `sub`, `mul`, `sdiv`, `udiv`, `srem`, `urem`.
- Integer bitwise: `and`, `or`, `xor`, `shl`, `lshr`, `ashr`.
- Integer compare: `icmp` × 10 predicates.
- FP arith: `fadd`, `fsub`, `fmul`, `fdiv`, `frem`, `fneg`.
- FP compare: `fcmp` × 14 predicates — the full ordered/unordered comparison
  family `{oeq, une, olt, ogt, ole, oge, one, ord, uno, ueq, ugt, uge, ult, ule}`
  (Phase 3 shipped the 6 `-O1` ordered preds; **8rvn (Phase 7.1 iw81.4 §4.4)**
  added the remaining 8 — see the reconciliation note below). The degenerate
  `true`/`false` stay out (no comparison).
- Int casts: `sext`, `zext`, `trunc` × applicable width pairs.
- FP casts: `fptrunc`, `fpext` × applicable width pairs.
- Mixed casts: `sitofp`, `uitofp`, `fptosi`, `fptoui` × int×fp pairs.

Operand shapes: `HH` (both tainted) → base symbol; `HL` (tainted +
constant literal) → `_hl` suffix; `LH` (literal + tainted, non-commutative
ops) → `_lh` suffix. The IR pass canonicalizes operand order for commutative
opcodes (BirthOrder for `HH`, literal→RHS for `HL`) and flips predicates for
literal-on-left compares; the non-commutative `_lh` form is realized this phase
(supersedes "deferred until a real call site demands it" — see PRD §2.6).

**Components touched:**
- `OpcodeLowering`: table-driven dispatch keyed by `(opcode, width,
  operand-shape)`. The current i32 + i64-and-fp partial coverage
  generalizes to the full table.
- `runtime/cq_templates.h`: regenerated from
  [`tools/opcode_table.yaml`](tools/opcode_table.yaml); CI verifies the
  hash. Bodies remain trace-only stubs.

**Done when:** programs using the full operator set across mixed quantum
/ classical operands produce expected template-call sequences; one LIT
fixture per (opcode, width, shape) combination green.

**Status (WP0–WP6 complete, 2026-05-31).** All done-criteria met: the four
instruction classes (`BinaryOperator`, `UnaryOperator`, `CmpInst`, `CastInst`)
lower to the expected `cq_template_*` calls under per-(opcode, width, shape) LIT
fixtures; `_lh` programs lower to `_lh`; data-position compares bridge through
`zext` to `cqrt_measure_i32` while `br`/`select`-feeding compares stay untouched
and `opt -verify` clean; unsupported tainted opcodes still emit the loud
`DiagnosticInfoUnsupported`. Two e2e trace smokes diff clean against goldens:
[`slice_qq_hl_arith`](tests/e2e/slice_qq_hl_arith.c) (HH `mul`, HL `add_hl`, LH
`sub_lh`/`shl_lh`) and
[`slice_compare_measure`](tests/e2e/slice_compare_measure.c) (`icmp`/`fcmp` →
`zext` → measure).

**Reconciliations vs [`docs/backend.md`](docs/backend.md) §6.3** (the planned
38-opcode surface, narrowed to what stage-1 `-O1` actually emits — PRD §2.9):
- **`fcmp`: now the full 14 predicates (8rvn).** Phase 3 shipped only the 6
  `clang -O1` (no fast-math) ordered preds `{oeq, une, olt, ogt, ole, oge}` — and
  fixed the yaml's `one`→`une` bug (clang emits `fcmp une` for `!=`, never `one`;
  closed `test_C_libtooling-7ws`). **8rvn (Phase 7.1 iw81.4 §4.4)** then restored
  the planned full family — the unordered twins `{ueq, ugt, uge, ult, ule}` and
  the order-test trio `{one, ord, uno}` — for pre-freeze opcode-surface
  completeness. They do NOT require fast-math: `__builtin_isunordered` emits
  `uno`, and negated relational compares fold straight to the unordered twins
  (`!(a>=b)`→`ult`, etc.). Only the degenerate `true`/`false` stay out (no
  comparison; an out-of-set predicate still loud-declines — the ziov4 hazard).
- **`frem` has no C-operator source.** Float `%` is illegal C; `frem` arrives
  only via `fmod()` (a Phase 6 libm substitution), so its lowering is pinned by
  a hand-written `.ll` fixture rather than a C-sourced e2e smoke (PRD §2.6).
- **`sub_hl` is unreachable from C; `sub` survives as `sub_lh`.** `-O1`
  canonicalizes `x - C` to `add x, -C`, so a handle-minus-literal never reaches
  the pass as `sub`; `sub` survives only as `C - x` → `sub_lh`. The arith smoke
  pins this (`x - 3` → `add_i32_hl(h, -3)`; `100 - x` → `sub_i32_lh(100, h)`).

---

## Phase 4 — RSSA swap-routed tainted control flow [4.0–4.5 DONE]

**Design:** [`docs/design/rssa-swap-control/SCOPING.md`](docs/design/rssa-swap-control/SCOPING.md)
+ [`OVERVIEW.md`](docs/design/rssa-swap-control/OVERVIEW.md);
[`docs/prd/phase-04-swap-route-control/PRD.md`](docs/prd/phase-04-swap-route-control/PRD.md)
(4.1 phase-arm increment); IR target fixtures `swap_route_if_diamond.ll`,
`swap_route_ifelse.ll`, `swap_route_if_diamond_uncompute.ll`.

**Supersedes the controlled-op approach.** The original Phase 4 lowered tainted
control by *flattening it into controlled ops* — mint a flag → substitute every
arm gate with a `_controlled` template → dissolve the `phi` per type → uncompute
the flag → linearize the CFG. That path shipped (core + 4.1 `switch`/escape + 4.2
mux + 4.3 `if`-completeness + 4.x MUX-EXCH) and was then **removed wholesale**
(commit `7cde677`) so the swap-route design is built without it shaping the
implementation. This block replaces the controlled-op Phase 4 in full; the
controlled-op history is recoverable from git (branch `rssa-swap-control`).

**Goal.** Lower tainted (quantum-dependent) `br` / `select` / `switch` by
**routing data, not by controlling gates**: `cqrt_cswap` the operand(s) into a
per-arm work rail, run the arm body **verbatim and uncontrolled** on the rail,
and `cqrt_cswap` the active result back — the tainted `phi` is the **adjoint of
the split**, sharing the same live condition (the quantum reading of Mogensen
RSSA). Classical (untainted) control flow is left exactly as `clang -O1` emits it.

| construct | lowering |
|-----------|----------|
| tainted `br c` | `cqrt_cswap` the operand(s) into a per-arm work rail |
| arm body | arm gates copied **verbatim, uncontrolled** onto the rail |
| tainted `phi` | `cqrt_cswap` the active result back (adjoint of the split) |

**Non-negotiable principles (design + author, revised 2026-06-09).** This
revision supersedes the 2026-06-08 "method-A / reverse-play-mandatory" framing
after a statevector-checked design dialogue; see
[`docs/design/rssa-swap-control/SCOPING.md`](docs/design/rssa-swap-control/SCOPING.md)
§3/§3a/§3c.

- **No added measurements — ever.** The compiler never inserts a measurement the
  user did not write (hard project invariant). Its one teeth: `cqrt_free` is
  emitted **only on a proven-`|0⟩` rail** — freeing a dirty/entangled rail is a
  hidden reset = measurement that collapses `q`. A rail not provably `|0⟩` is
  **left allocated** (a qubit "leak," accepted in the qubits-not-scarce regime,
  §0), never freed. This is precisely what the struck "v1" got wrong — it freed
  dirty rails; the fix is *don't free dirty*, not *free carefully*.
- **`Rz = diag(1, e^{iθ})`** (phase-gate convention; `Rz|0⟩ = |0⟩` exactly). A
  phase arm therefore leaves its inactive work rail at `|0⟩` **unconditionally** —
  clean and disentangled, freeable as a no-op reset.
- **Coherence for phase arms is a cheap flag-strip, not reverse-play.** The flag
  is `icmp(q0)`; an `Rz` arm preserves `q`'s computational-basis *value*, so the
  condition stays recomputable from the current `q`. Uncompute the flag with
  `icmp_inv(q)` — an **uncontrolled** data-template inverse (zero controlled
  gates) — leaving `q` with the answer, fully disentangled. The output is then
  correct under measurement, full undo, **and** downstream interference (Grover).
- **Method-A (controlled-adjoint rail cleanup) is dropped.** If you would emit a
  controlled gate to clean a rail, you could have controlled the op *in place*
  from the start (§6a) — so route + controlled-cleanup gains nothing. We never
  emit controlled cleanup; rotation arms route uncontrolled and are cleaned by the
  flag-strip above.
- **Reverse-play is the on-demand coherence mechanism, not an eager step.** The
  full-region adjoint (via `emit_inverse`) restores `q0` and zeros every ancilla
  exactly, for *any* arm; it is emitted when the user inverts the region
  (`cq_invert`, Phase 8) or an oracle uncomputes — **not** by the forward
  lowering. (Supersedes the 2026-06-08 "reverse-play mandatory in every
  increment.")
- **The one rejection — clobbering the control's own data.** Reject (loud
  `DiagnosticInfoUnsupported`) iff an arm performs a **value-changing write to a
  quantum variable the branch condition transitively reads**. Model-independent
  (control-in-place hits the same bind) and information-theoretically unfixable
  for non-injective maps. *Not* rejected: phase (`Rz`) ops on a condition
  variable; value ops on non-condition variables; reads of condition variables.
  Vacuous for pure-phase 4.1; active once value arms (4.2) land.
- **`select` is trivial and separate.** A `select` has no arm operations, so it is
  a pure merge — a controlled-XOR copy (`out ^= c ? a : b`), **not** cswap routing.
- **Maintainability win.** Arm bodies pass through unchanged (no `_controlled`
  variant per gate); `phi` is one uniform CSWAP (not three per-type reductions);
  nested control is the **same emitter applied recursively** — no flag-conjunction
  Toffoli, no ordered flag uncompute (the old bug class is deleted, not migrated).

**Increments (staged by arm-body class, not by measurement regime):**

- **4.0 — Clean slate [DONE, `7cde677`].** The controlled-op control path
  (`ControlDetection` / `ControlFlag` / `ControlledLowering` /
  `ControlledSubstitution` / `FlagConjunction` / `CFGLinearization` /
  `MergeDissolution` / `SwitchNormalization`) is removed. A transitional
  `detectControlRegions` stub (`ControlStub.cpp`) diagnoses any tainted
  `br`/`select`/`switch` loudly ("… under quantum control") and returns an empty
  plan, so no tainted control flow silently passes through as classical control
  over quantum state. Retained: Phases 1–3 lowering, `EmitInverse`, the Phase-5
  data-uncompute spine (`ChainWalk`/`FreePoint`/`Uncomputation`),
  `ControlledSymbols`, and `ControlPlan.h` (struct only — `RotationLowering`
  reads `plan->InShadow`). Reusable runtime primitives (`cqrt_cswap`,
  `cqrt_toffoli`, `cqrt_alloc_<W>`, `cqrt_free`) kept. Full suite green.

- **4.1 — Swap-route emitter, phase arms (`Rz`) [DONE, branch `swap-route-control`,
  WI-1…WI-5].** `if`-diamond then `if/else`, matching the **coherent**
  `swap_route_if_diamond.ll` / `swap_route_ifelse.ll` design specs. Mint the flag
  (the `icmp` `_hl` data template), `cqrt_cswap` the operand into a `|0⟩` work rail,
  run the arm `Rz`s **verbatim and uncontrolled** on the rail, `cqrt_cswap` back.
  Because `Rz|0⟩ = |0⟩`, the rail returns to `|0⟩` and is freed clean; the flag is
  stripped with `icmp_inv(q)` and freed — `q` is left with the answer, disentangled
  and interference-safe, with **zero controlled gates**. **No new runtime ABI** —
  reuses `cqrt_cswap`, `cqrt_alloc_<W>`, `cqrt_free`, `cqrt_rz`, `cqrt_x` (the ¬flag
  bracket), and the `icmp` `_hl`/`_hl_inv` templates. The br/diamond cswap
  **emission wiring** is net-new (today `cqrt_cswap` appears only inside
  `EmitInverse`). The clobber-the-condition **reject predicate** ships here with its
  decline fixture, though vacuous for phase arms. The tainted `br`/`phi` are erased
  and the diamond flattened into a single straight-line block (provenance kept in
  value names). **Cleared (Rule 13)** against the statevector oracle
  (`prototype_semantics.py` Demo A: swap-route ≡ controlled-op measurement stats to
  3.3e-16; Demo B fixes the phase-arm-only coherence boundary) plus the §8 probe
  matrix — no-spurious-free (`CHECK-COUNT` two frees/diamond, three/if-else),
  polarity (FALSE-successor gate arm), transitive §3c reject, dephasing guard
  (`CHECK-NOT` `_controlled`/`cqrt_copy` on a phase arm) — and a linked e2e golden
  (`tests/e2e/slice_control_phase_diamond.c`, the only layer that proves every
  emitted symbol resolves + signature-matches). Modules: `ControlDetect`,
  `ArmClassify`, `SwapRouteEmit`, `RegionFlatten` (replacing `ControlStub`).


  > ⚠ **SUPERSEDED FOR THE *FLAT* PATH BY §6a CONTROL-IN-PLACE** (bd
  > `test_C_libtooling-drbq` Inc 2a, 2026-09-02). Every FLAT phase region — diamond,
  > if/else, hcrg sequential, the 8h7d.5 rolled in-loop region, `ShareCondFlag`,
  > multi-Rz spines, Rz on the condition register, the 4.5 eq-folded diamond — now
  > lowers to ONE `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate: **no work rail, no
  > `cqrt_cswap`, no rail free**, and therefore **not** "zero controlled gates". The
  > flag mint, the `cqrt_x` bracket, the `icmp_inv` strip and the flag free are
  > byte-identical and in the same order (a NEGATED arm carries **two** `cqrt_x`, not
  > the route's four). The **4.3 depth-2 nest and the 4.5 switch keep the route**, so
  > the recipe below is still literally what they emit. The two forms are the SAME
  > unitary — with `w = |0⟩`, `cswap(f,q,w)·Rz_w(θ)·cswap(f,q,w)` **equals**
  > `cRz(f,q,θ)` with no global-phase residue — which is why the route remains the
  > correctness ORACLE for the peephole. See
  > `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2A_NOTES.md` and
  > `control-in-place-PRD.md` §12.2.
- **4.2 — Classical-permutation / value arms (method-B) [DONE 2026-06-11,
  branch `swap-route-control`, WI-1..WI-7 — `docs/prd/phase-04-swap-route-control/PRD.md`
  Part II + `IMPLEMENTATION-4.2.md`].**
  `add`/`mul`/`x`/`toffoli`-class bodies (linear chains of supported tainted
  integer opcodes): run `R` → CNOT-copy the basis-valued result into a fresh
  register → reverse-play `R†` to restore `q0` and zero the rail (§3a-B),
  targeting `swap_route_if_diamond_uncompute.ll`. Adds the design's **only new
  ABI**: the per-width reversible copy `cqrt_copy_<W>` — **§7.6 resolved (PRD
  §8.1): the 5 integer widths only for the UNCONTROLLED copy** (no consumer for
  an fp one exists — dead ABI is forbidden), hand-written `cqrt_*` core ABI
  (the `cqrt_cswap` precedent), keep-sources-live transversal-CNOT involution,
  no `_inv` twin. This re-opens the Phase-9/11 freeze for that 5-symbol family
  — later grown to 5+5+4 with 4.4's `_controlled` twins and the fp-DATA select
  un-staging's `cqrt_copy_f{16,32,64,80}_controlled`
  (`docs/prd/phase-04-swap-route-control/fp-data-select-PRD.md`, issue kjd1:
  the "an FP merge φ is an angle, never data" rule is retired **for the
  tainted-`select` merge only**, where the three-legged angle fence proves the
  value is data; every other fp-under-control path still declines). The **clobber-the-condition
  reject becomes active here**: a value arm that rewrites a quantum variable the
  branch condition reads is declined loudly (it cannot be both kept and
  disentangled — §3c), while a value arm on any other register lowers normally.
  The §8 method-B demo obligation was **struck by owner decision 2026-06-10**
  (no statevector simulations at this stage); the B-keep boundary is documented
  analytically in PRD §8.2 and was **cleared by the WI-7 independent
  adversarial review** (Rule 13 — 4 analytic lenses + skeptic adjudication;
  **4/4 cleared, 0 confirmed defects, 0 silent-miscompiles**; IMPLEMENTATION-4.2
  §8.10). Lands: `cqrt_copy_<W>` core ABI (db47cb4), value-arm detection +
  Defect-2 fix (cf6c54c), value diamond — first real `emitInverseChain`
  (a1bb41c), value if/else (92f28af), e2e golden (7139b7a).

- **4.3 — Nested control, depth-2 homogeneous-phase nest [DONE 2026-06-15,
  branch `swap-route-control`, WI-0..WI-5 — `docs/prd/phase-04-swap-route-control/IMPLEMENTATION-4.3.md`
  + PRD Part III §§11–14].** The blanket `nested control flow` decline is lifted
  for the **one proven shape**: a one-content-arm diamond whose `Mid` arm ends in
  another tainted-condition one-content-arm diamond, reconverging at a single
  3-incoming merge `phi`, every arm a pure `Rz`/`cq_phi` chain. The **same emitter
  applied recursively** (`NestedRouteEmit`): outer flag mint → route the base onto
  `rail1` → replay the intervening `cq_phi` on `rail1` → mint the inner flag **FROM
  `rail1`** (`lowerCompareToFlagRail`) → route `rail1` onto `rail2`, replay the
  inner `cq_phi`, route back → LIFO teardown inside the outer bracket (free
  `rail2`; strip `%f2` vs `rail1` — **after** the inner route-back, **before** the
  outer route-back; free `%f2`) → outer route-back → free `rail1`, strip `%f1` vs
  `q`, free `%f1`. `c1 ∧ c2` falls out of the routing structure with **no
  conjunction ancilla** (the inner level routes `rail1`, which holds `q`'s
  amplitude only on the `f1=1` path) — **zero** `_controlled`/`cqrt_toffoli`/
  `cqrt_copy`, exactly **four** `cqrt_free`, **no new ABI** (reuses 4.1's symbol
  set entirely). Detection (`RegionTreeDetect`, 7 criteria by SSA identity before
  mutation) proves the shape or declines loudly; the binding accept signal is
  **mint-from-rail** (criterion 5 — the inner condition's whole quantum lineage in
  `rail1`'s diagonal-alias closure, and the compare's tainted operand a DIRECT
  closure member, the strengthened check that caught a value-derived-inner-cond
  silent miscompile). Everything off-pattern declines (depth-3 / both-arm / if-else
  nest / multi-register / value-arm-in-tree / two-phi / distinct-base / loop /
  nested `select`·`switch`). `flattenRegionTree` tears the pair down with the
  **single shared-merge erase** + the load-bearing compares-before-gates /
  reverse-lineage erase order. **Cleared (Rule 13)** by two independent adversarial
  reviews — the WI-3 5-lens emitter-physics clearance (caught a real verify-clean
  over-accept, fixed) and the WI-5 5-lens shipped-build re-confirmation (0
  confirmed defects, 4 loud-safe/pre-existing NITs;
  `docs/design/rssa-swap-control/WI3_NESTED_TRACE.md`) — plus the §5g ordered
  FileCheck (inner-strip-before-outer-route-back, the only layer that catches a
  temporal misorder) and a linked e2e golden
  (`tests/e2e/slice_control_nested_phase.c`). Modules: `RegionTreeDetect`,
  `ArmHomogeneity`, `NestedRouteEmit`, `flattenRegionTree`; reused helpers
  de-anonymized into `ControlShape.h`/`ArmAnalysis.h` (WI-0).

- **4.4 — tainted `select` (controlled-XOR copy merge) [DONE 2026-06-16,
  branch `swap-route-control`, WI-1..WI-5 —
  `docs/prd/phase-04-swap-route-control/IMPLEMENTATION-4.4.md` + PRD Part IV
  §§15–18].** The blanket `select` decline is lifted for a tainted-condition
  **integer-data** `select` (the `-O1`-folded ternary, one SSA instruction — the
  simplest Phase-4 shape). The merge is a controlled-XOR copy into a fresh `|0⟩`
  register — **no `cqrt_cswap` routing** (a `select` has no arm ops), **no
  `RegionFlatten`, no reverse-play**: mint the flag from the icmp → `alloc` the
  `|0⟩` out rail → `cqrt_copy_<Wd>_controlled` the TRUE operand on the flag →
  **one self-inverse `cqrt_x` bracket** + `cqrt_copy_<Wd>_controlled` the FALSE
  operand (materialized via `cqrt_alloc` if classical) on ¬flag → `icmp_inv`
  strip → the **single** `cqrt_free` (the flag) → RAUW `%sel→%out`. New ABI:
  `cqrt_copy_<W>_controlled` (shipped as the 5 integer widths with fp-data
  staged, §16.4; the staging was **lifted 2026-07-02** by the fp-DATA select
  un-staging — `fp-data-select-PRD.md`, issue kjd1 — adding the 4 fp twins
  `cqrt_copy_f{16,32,64,80}_controlled`, minted only by the select-local
  `copyControlledFpFn`; the shared `copyControlledFn` integer fence is
  untouched — it is the 6.5 classical-call arm's live fp classifier. The kjd1
  Rule-13 clearance — `FP_SELECT_CLEARANCE.md` — also hardened the select
  classifier for BOTH type families: the gate-2c stale-condition wire guard,
  wire-anchored gate-5 walks, and curated-call crossing, closing three
  pre-existing 4.4-era holes that the fp accept made newly reachable). `%out` /
  operands / scratch are **left allocated** (freeing an operand entangled with
  `%out` via the copy is a hidden measurement — Rule 6/8); §3c is structurally
  vacuous (a select writes nothing). Detection (`SelectClassify`, a 6-gate
  prove-or-decline ladder by SSA identity before mutation) proves the shape or
  declines loudly; the two load-bearing guards are the **USE-not-type angle gate**
  (`selReachesRotationArg1` — a `select` result transitively reaching a rotation
  arg-1 declines `rotation angle`; **no downstream backstop**, so it must fire at
  detection) and the **conservative coherent-operand gate** (`operandCarriesPhase`
  backward + `hasCoherentDownstreamUse` forward — a `cq_phi`/Rz-lineage or
  downstream-rotation operand declines `control flow`, the basis CNOT-copy would
  dephase it). Everything off-pattern declines (fp vector / `fp128`, integer
  vector / `i128`, aliasing, Q+Q condition, non-`CmpInst` condition; scalar
  fp-DATA — originally in this list — accepts since the 2026-07-02 kjd1
  un-staging above); classical-**condition** tainted-data
  selects stay on the separate `declineClassicalMuxes` path. Modules:
  `SelectClassify`, `SelectMergeEmit` (+ thin `ControlDetect`/`SwapRouteEmit`
  dispatch, `ControlledSymbols::copyControlledFn`); `ChainWalk` **unchanged** (the
  controlled copy counts as a real consumer, leaving entangled rails allocated —
  the WI-3-amendment-correct state). **Cleared (Rule 13)** by two independent
  adversarial reviews — the WI-3 4-lens emitter-physics clearance (caught a real
  verify-clean dephasing over-accept — the forward-only coherent proxy missed an
  `Rz`-lineage operand; fixed by adding `operandCarriesPhase`) and the WI-5 5-lens
  shipped-build clearance (each lens independently second-reviewed; the binding
  coherent-operand lens got a dedicated 20+-probe skeptic; **0 confirmed defects,
  0 silent miscompiles**; IMPLEMENTATION-4.4 §8.11 +
  `docs/design/rssa-swap-control/WI5_SELECT_CLEARANCE.md`) — plus the §5a
  ordered+count FileCheck (`ORD`+`XCT`, the only lit layer catching a bracket
  misorder/stray-x) and a linked e2e golden (`tests/e2e/slice_control_select.c`).
  **The shipped default is the conservative form** (classical/basis-integer
  operands accept; coherent + fp-data decline); the clearance gates each future
  widening. **Next: 4.5 `switch`.**

- **4.5 — tainted `switch` (N-way eq-flag routing + const-fold re-anchor) [DONE
  2026-06-17, branch `swap-route-control`, WI-1..WI-7 —
  `docs/prd/phase-04-swap-route-control/IMPLEMENTATION-4.5.md` + PRD Part V
  §§19–22].** The blanket `switch` decline (the old `SwitchNormalization` was
  removed) is lifted for a tainted-scrutinee `switch` in **four** ACCEPT shapes,
  driven by a `classifySwitchRegion` G0–G11 prove-or-decline ladder (pure SSA
  analysis by value identity, before any mutation) + per-class G6 proofs
  (`SwitchArmProve`): **(A) homogeneous phase** (`SwitchRouteEmit`) — per content
  case mint an `icmp eq`-flag → `|0⟩` rail → `cqrt_cswap` route the scrutinee in →
  replay the folded gate's **arg-1 angle only** (`cqrt_rz`) → route back → free
  rail → `icmp_inv` strip + free flag; **zero** controlled gates beyond the route
  cswaps, `q` never freed, RAUW merge→`q`. **(B) homogeneous value**
  (`SwitchValueEmit`) — N-way method-B over the **shared routed base** `p` = the
  merge default-edge incoming (`p != q`, the C2 anchor; routing `q` would clobber
  the eq-flags): route-in → verbatim chain replay → route-back → **one**
  `cqrt_copy_<W>(p,out)` → LIFO reverse-play `R†` (body chain only — the §8.5
  cswap-arg0 seam: route cswaps are bracketed by `emitRoute`, never fed to
  `emitInverseChain`). **(C) all-`ConstantInt` data-mux** (`SwitchDataMuxEmit`) —
  the N-way 4.4 `select` merge: preload `%out = cqrt_alloc(v_d)` + per content
  case `cqrt_alloc(v_i⊕v_d)` XOR-delta + `cqrt_copy_<W>_controlled`; no route, no
  ¬-bracket. **(D) equality-folded `br` diamond** (`EqFoldArm::tryEqFoldArm`,
  D1–D7) — `clang -O1` folds `if(q==k){…}` to `cq_phi(i32 k, θ)`; an **additive,
  detection-only** clause re-anchors `Routed` to the icmp's tainted handle and
  reuses `emitRegion` verbatim. **The load-bearing, verify-clean-invisible blocker
  is the §5 const-fold re-anchor:** the folded `cq_phi(c_i,θ)` (arg-0 = the case
  literal, not `q`) must be re-anchored by physics (replay arg-1 only) **and**
  scrubbed+erased (incl. `taint.PhiCalls` removal) **during emit, before
  `RotationLowering`** — else the merge degenerates into a verify-clean wrong
  data-mux with **no downstream backstop**. Everything off-pattern declines loudly
  (the §20.7/§22 matrix): multi-phi (C1), grouped-case (C4), non-empty-default
  (C5), distinct-handle MUX-EXCH (C8/G8), mixed arm classes, fp-data/vector/`i128`
  (G4), nested (G11), `§3c` clobber (G7), tainted angle (G3), jump-table fold
  (pre-detection escape), impure arm / unowned-scrutinee-use (G10). **No new
  `What` string, no new ABI symbol, no YAML edit** (`gen_templates.py --check`
  clean — every need reused: `emitEqFlag`, `emitRoute`, `emitInverseChain`,
  `copyControlledFn`, `flattenSwitchRegion`). **Cleared (Rule 13)** by **16
  independent adversarial reviewers** (the 11 §8 lenses + the two residual
  coherence boundaries — value-arm method-B N-way; data-mux N-ary
  coherent-operand — + 3 over-accept hunters), each extracting the real lowered IR
  and actively constructing miscompile attempts: **0 confirmed defects, 0 silent
  miscompiles** (IMPLEMENTATION-4.5 §8.11 +
  `docs/design/rssa-swap-control/WI7_SWITCH_CLEARANCE.md`); plus SSA-captured
  ordered + `XCT` FileCheck (the lit layer catching same-multiset reorders / a
  stray `cqrt_x`) and ≥1 linked e2e golden per class
  (`tests/e2e/slice_control_switch_{phase,value,datamux,eqfold}.c`). **Next: Phase
  5 productionization** (the uncompute spine is already reused by the swap-route
  emitter).

**Deferred to later increments (coherent — NOT measurement-restricted):**
- **Controlled `return` / `break`** (§4): per-site return registers + an
  **exit-priority cascade** (a fixed permutation — **no done-flag ancilla, no
  measurement, no overhead**). Lifts the permanent P2/P3 rejections for the
  **bounded + reconverging (D4)** subset only; non-reconverging exits stay
  rejected by physics (QCM injectivity). Coherent return *values* ride the same
  §3a reverse-play obligation. **(Now scheduled: Phase 7.2 `return`, 7.4 `break`.)**
- **Control-in-place peephole** (§6a): for genuinely-in-place single-target
  unitaries (`R_z`/`R_y`/Pauli), control in place (no work rail) — a footprint
  optimization, not a correctness requirement. **DONE for the FLAT `emitRegion`
  path** (bd `test_C_libtooling-drbq`, 2026-09-02): Inc 1 shipped the `R_y` arm,
  where in-place is the MECHANISM and not an optimization at all (`Ry(θ)|0⟩ ≠ |0⟩`,
  so the route hands the inactive rail back dirty — PRD §2); Inc 2a made the `R_z`
  peephole default-on for every flat phase spine (diamond, if/else, hcrg
  sequential, the 8h7d.5 rolled loop, `ShareCondFlag`, multi-Rz spines, Rz on the
  condition register), replacing the route quintuple with one
  `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate. The 4.3 depth-2 nest and the 4.5
  switch KEEP the route. The two forms are the same unitary, and the 26 moved
  goldens' diff is exactly the collapse and nothing else
  (`tools/golden_multiset_audit.py`). The two stems get DIFFERENT uncompute
  treatment and that split is load-bearing, not cosmetic: `cqrt_ry_<W>_controlled`
  is a DAG link, never adjointed, frozen; `cqrt_rz_<W>_controlled` is transparent
  — not a link, never adjointed, not frozen — because a diagonal gate moves no
  basis label (PRD §12.1). Notes:
  `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2A_NOTES.md`.
  **Inc 2b (2026-09-03) makes the plain C `if/else` with a rotation on ONE
  register in each arm compile, for BOTH stems** — `clang -O1` never hands that
  shape to the pass as a diamond at all (SimplifyCFG merges the two arms into ONE
  call whose ANGLE is a tainted-condition `select`), so it is lowered BY
  DIFFERENCE: an unconditional `R(h, B)`, the ordinary flag mint, ONE
  `cqrt_{ry,rz}_<W>_controlled(f, h, A−B)`, the ordinary strip, one free. Exact in
  REAL arithmetic by angle additivity on one axis; in IEEE double the emitted
  true-arm angle is `B + fl(A−B)`, `|δ| ≤ ½ ulp(A−B)`, so **BOTH ARMS MUST BE
  CONSTANTS** (`ConstantFP`) and their evaluated residual is fenced at a
  placeholder 2^-40 rad. A **RUN-TIME arm DECLINES**: the compiler would
  synthesize an `fsub` the source never wrote, carrying (i) a rounding error
  UNBOUNDED in absolute radians (measured 0.858 rad from plain C on `π`/`1e16` —
  `Ry(π)` realized as `Ry(4.0)`) AND (ii) a **non-finite `fl(A−B)` from two FINITE
  arms** (measured `cqrt_ry_i32_controlled(f, h, inf)` from `±8.99e307`). Neither
  half is fenceable at compile time, the pre-2b binary declined every reproducer
  loudly, and the manual by-difference twin of that shape declines on BOTH
  binaries — so the class was reachable only through 2b. That is the Rule-13
  **clearance** review's blocker F-11 and the owner's option (2); options (1)
  (accept run-time arms, one line) and (3) (the two-controlled form, which
  performs no subtraction at all) remain a THREE-WAY item on the owner's desk
  (round-1 Rule-13 review found the constant half, round 2 the run-time one, the
  clearance review ruled it — notes §9/§10/§11).
  NO new frozen symbol, no CFG surgery, no `cqrt_x`. Scoped to one consumer per
  select; in-loop OR ON ANY CFG CYCLE (including one the rotated register's RAIL
  sits in), N consumers, a shared compare, a Q+Q condition, a `float`-armed
  select, an undef/poison arm, any `Constant` arm that is not a `ConstantFP` (a
  link-time constant this compiler cannot evaluate — round-2 Rule-13 review), any
  RUN-TIME arm (clearance review), a non-finite arm, and controlled state prep all
  decline loudly. **What the cycle
  question does NOT reach** (round-2 review): the rotated register's rail FORWARD
  of the consumer, and the CONDITION register's rail — both accept and both are
  byte-identical to the manual twin on the pre-2b oracle, so the disposition
  belongs to Inc-1's structural freeze rather than to 2b. Notes:
  `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2B_NOTES.md`.

**Soundness obligation (§3b).** `cqrt_free` (compiler-emitted only) is emitted on
a rail **only after** its reverse-play returns it to `|0⟩`, via the `FreePoint`
post-dominator discipline (never when the handle escapes or is the user's measured
output — there the caller owns it).

**Done when:** programs with tainted `if` / `if-else` / nested / `select` /
`switch` lower to the swap-route IR the `.ll` fixtures pin — coherent (phase arms:
flag stripped via `icmp_inv`, rails `|0⟩`-clean and freed; reverse-play available
for full-region undo), `opt -verify` clean; a clobber-the-condition arm declines
loudly — and the e2e trace smokes diff clean against goldens captured from real
linked output (the layer that proves every emitted symbol resolves +
signature-matches).

## Phase 5 — IR pass: whole-DAG uncomputation [DONE]

**Design.** Plan of record:
[`docs/prd/phase-05-uncomputation/PRD.md`](docs/prd/phase-05-uncomputation/PRD.md)
(§2.1–§2.13) +
[`docs/prd/phase-05-uncomputation/IMPLEMENTATION_PLAN.md`](docs/prd/phase-05-uncomputation/IMPLEMENTATION_PLAN.md)
(7 WIs, design decisions DD-1..DD-5). Design-of-record:
[`docs/backend.md`](docs/backend.md) §9–10. The original old-gen PRD (written
against the controlled-form Phase 4) is archived at
[`docs/archive/old-design/phases/phase05-uncomputation/PRD.md`](docs/archive/old-design/phases/phase05-uncomputation/PRD.md);
its control-coupled mechanics are dead post-`7cde677`. The old-gen Phase 5 bd
issues were erased 2026-06-08 (divergent-arm soundness lesson kept in
`bd remember`).

**Done (branch `swap-route-control`, 7 WIs).** The conservative shipped slice
(uncontrolled, single-register, single-block linear chains over the
fresh-minting `_inv` ABI) was productionized to **whole-DAG LIFO reversal** of
dead source-derived tainted **data** handles over a new **void in-place `_unc`**
ABI. Two pillars:

1. **Void in-place `_unc` ABI** (WI-2/WI-3) replaces fresh-minting `_inv`:
   `void cq_template_<op>_<W>…_unc(out, src…)` **zeroes the rail by recomputing
   `f` from the still-live sources** (Bennett), instead of returning a fresh
   handle. Threading the old `_inv` would free a dirty / entangled rail — a
   hidden measurement (Rule 6/8). `_inv` is still **generated** (DD-2) but no
   longer emitted. DD-3 pins the slot convention (`out` arg 0, then forward
   operands in order) — the Q+Q operand-swap miscompile guard.
2. **Whole-DAG, not per-terminal** (WI-4): one reverse-topological pass adjoints
   each gate **exactly once** (`Seen` dedup), handling fan-out and Q+Q (two
   tainted parents) — the shapes the conservative slice bailed on. SSA dominance
   makes reverse-program-order a valid reverse-topo order. Each rail freed after
   its last reverse-use. No `cqrt_cswap` (PRD §2.11).

Plus **WI-5** (abolish silent skips — every unprovable shape declines
**loudly**; the un-invertible / divergent-arm / post-measure / loop-backedge /
unrecognized-user / measured-lineage families), **WI-1** (excised the dead
controlled-op scaffolding), and **WI-6/WI-7** (e2e link-completeness goldens —
the `_hl`/Q+Q/`_lh`/cast/`fneg` `_unc` shapes are all permanently link-proven).

**Reconciliation with swap-route Phase 4.** The control scratch the old PRD §2.2
referenced no longer exists. Phase 5's machinery is *reused, not bypassed*:
`emit_inverse` (now emitting void `_unc`) is the engine for Phase 4's region-local
**reverse-play** (value-arm method-B rail cleanup), and Phase-4-owned control
rails are subtracted from the data-uncompute target set up front (DD-4 —
`ControlOwnedRails`), so a flag / work / merge out-rail is never walked by this
spine.

**Modules:** `ir-pass/src/{ChainWalk,DagTraversal,FreePoint,EmitInverse,
Uncomputation}.cpp` (the per-op slice lifted and split for the whole-DAG driver);
`tools/opcode_table.yaml` → `tools/gen_templates.py` (split out `abi_codegen.py`)
→ `runtime/cq_templates.{h,c}` (the generated `_unc` family).

**Acyclic-CFG assumption; loops deferred.** Phase 5 reverses on straight-line /
diamond CFGs (no backedges); a tainted handle whose live range crosses a loop
backedge is **diagnosed loudly**, not miscompiled. Loop uncomputation
(loop-carried registers, per-iteration reversal) **extends** this mechanism when
loops land — it does not replace it (see "Beyond the freeze"; PRD §2.9).

**Done criteria met:** the ir-pass LIT suite (positive `CHECK` + negative
`RUN: not` decline probes, including the WI-7 compare-decline pair
`lowering_uncompute_compare_{icmp,fcmp}.ll`) + the 2 e2e link-proof goldens
(`slice_uncompute_dead_dag` = `_hl`/Q+Q, `slice_uncompute_dead_shapes` =
`_lh`/cast/`fneg`) green; the core whole-DAG reversal + void-`_unc` ABI cleared
by independent adversarial Rule-13 review (WI-3/WI-4/WI-7 — the WI-7 review
caught and the fix closed a verify-clean compare-uncompute over-accept).

---

## Phase 6 — IR pass: call-graph specialization (function lifting) [6.0–6.5 DONE]

**Goal.** Productionize the prototype's `cq-specialize` slice into a
full worklist-driven specialization synthesizer with both lifting paths
(curated symbol substitution + clone-on-taint) and the rejection-set
classifier.

**Increment status** (branch `phase-6.5-classical-call`, predecessors on
`phase-6.3-transitive`/`phase-6-specialize`/`main`): **6.0** (compare `_unc` grid
— compares are reversibilizable), **6.1** (clone-on-taint core:
`SpecializeDetect`/`Reject`/`Clone`/`Seed` + `BennettWrap` + the `(callee,mask)`
cache + the `:418` carve-out), **6.2** (signature masks / cache / multiplicity),
**6.3** (transitive worklist: a clone's inner tainted-arg call is specialized
depth-first and reversed in the outer wrap via a synthesized void uncompute
**twin** `@__cq_q_<inner>_<mask>_unc`; recursion / call-graph cycles + varargs
loudly rejected; incl. the latent stale-classical-attr fix — clones inheriting
`memory(none)`/i32 return attrs would let the backend delete the side-effecting
void twin call / crash `opt -verify`), **6.4** (rejection-set hardening — full
decline matrix + over-accept probe family), and **6.5** (classical call under
quantum CONTROL — a pure all-classical-args call inside a tainted-condition
DIAMOND arm runs classically, its i32 result route-merged into the controlled
register via the 4.4 controlled-XOR copy mechanics over a flattened diamond;
clone-ORTHOGONAL — `classifyClassicalCallArm` + `emitClassicalCallArmRegion`,
NO clone, the call HOISTED into the pred since it is pure) are **ALL DONE**
(each Rule-13 cleared). **Phase 6 is COMPLETE.** Path 1 (curated libm
substitution) stays deferred (owner); the quantum-DATA-under-quantum-control
clone×route composition stays OUT (deferred Phase 4×6).

**Reconciliation with swap-route Phase 4.** A **quantum-controlled call** no
longer needs a controlled specialization of the callee: swap-route routes the
argument into the callee's input iff the condition holds, calls the function
**unconditionally**, and routes the result back (`OVERVIEW.md`). So the
controlled-call branch of specialization is **dropped** — only the
tainted-**data**-argument clone-on-taint (Path 2) and curated substitution
(Path 1) remain in scope here. Bounded recursion becomes a **loop** at `-O1`
(Phase 7.3, lowered **rolled in place**), not a specializer call cycle.

**Scope.**
- Path 1 — curated symbol substitution: maintained table mapping
  classical externals (`@sin`, `@cos`, `@llvm.sqrt.f64`, `@fabs`, etc.)
  to quantum templates (`@cq_template_sin_f64`, etc.). At a tainted
  callsite, rewrite the called function; body never inspected.
- Path 2 — clone-on-taint: at a tainted callsite where the callee's
  body is visible, compute the taint signature (bit-mask per parameter
  position), look up `(callee, signature)` in the specialization cache;
  cache miss → `CloneFunction` + `ValueToValueMapTy`, mangle as
  `__cq_q_<callee>_<signature>`, internal linkage; recurse the lowering
  pipeline on the clone. `setCalledFunction` retargets.
- Worklist algorithm per [`docs/backend.md`](docs/backend.md) §7.3.
- Rejection-set classifier ([`docs/backend.md`](docs/backend.md) §7.4):
  inline asm, syscall, `volatile`, atomics, EH, `setjmp`/`longjmp`,
  unresolvable indirect call, unbounded recursion, vector/SIMD,
  transcendentals without soft impl. Each rejection emits a
  source-location diagnostic via `!dbg`.
- Bennett wrap-around at the synthesized clone's signature: forward +
  CNOT-copy of return + reverse, so the clone fits the handle-ABI
  signature without leaking ancillas to the caller. The one
  load-bearing use of whole-call Bennett in the design.

**Components touched:**
- New `Specialization` module in `ir-pass/src/` (the prototype's
  `cq-specialize` slice, lifted and expanded).
- New `tools/cq_curated_table.yaml` (or similar) for Path 1.
- `cqc` driver: pass `-flto` to clang, pre-link via `llvm-link` before
  `opt`, so the cloning path has the bodies it needs
  ([`docs/frontend.md`](docs/frontend.md) §8 multi-file flow).

**Done when:** programs with tainted-argument calls into user-defined
functions (including recursive specialization, including libm
substitutions) produce expected mangled-call → specialization →
template-call sequences. Rejection diagnostics fire with correct
source locations on the standard rejection set.

**Open items (defer to Phase 6 PRD):** auto-specialization scope (every
reachable function vs. opt-in only); concrete mangling scheme. (The
`-fcq-measurement-bridge` "measurement-at-rejected-boundary" opt-in once floated here is
**rejected permanently** — owner 2026-06-19: a transparent auto-measure silently
collapses the user's state, Rule 5. A tainted I/O sink is instead lowered **coherently**
via the §7.6 reversible output tape.)

---

## Phase 7 — Pre-freeze expressiveness completion [7.1–7.6 core DONE]

> **"DONE" = the scoped CORE increments shipped + Rule-13-cleared.** It does **not**
> mean the accepted-C subset is maximal: everything outside each sub-phase's shipped
> accept-shape **declines loudly** (Prime Directive), so the open follow-ons are
> *additive coverage / deferred separate capabilities*, **not** correctness debt. The
> post-core **break/loop** widenings (multi-break, nested-loop break, `continue`, mixed
> break+return, static-K unroll, value-arm widening) were re-parented out of the
> now-closed 7.3 (`799w`) / 7.4 (`y05j`) core epics into the open **7.x-widenings
> tracker `8h7d`** (2026-06-30). The 7.2–7.4 control work itself adds no frozen
> symbols, but `8h7d` is **no longer wholly freeze-orthogonal**: the fp-DATA
> select un-staging under it (kjd1, DONE 2026-07-02) added the
> `cqrt_copy_f{16,32,64,80}_controlled` family, designated frozen at the
> Phase-11 gate (`fp-data-select-PRD.md` §7). A SECOND frozen-designate family
> joined on 2026-09-02: **`cqrt_ry_<W>_controlled`** (9 widths, mirroring the
> Phase-4 `cqrt_rz_<W>_controlled`), added by the control-in-place epic
> `test_C_libtooling-drbq`
> (`docs/prd/phase-04-swap-route-control/control-in-place-PRD.md` §5). It is NOT
> a footprint optimization: the swap route CANNOT carry an `Ry` at all
> (`Ry(θ)|0⟩ ≠ |0⟩` leaves the inactive work rail dirty and entangled with the
> flag, Rules 6/8), so control-in-place is the MECHANISM for a tainted-control
> rotation arm. Adjoint = the SAME symbol with a negated angle (the existing
> rotation convention); the older `_controlled_inv` reserve is untouched.

**Posture.** This phase widens the **accepted-C subset** the IR pass lowers; it is
almost entirely pass-logic, **not** new user surface. `CQ.h` does not change — loops
are plain C `for`/`while`, controlled early-exit is plain C `return`/`break`, QRAM is
plain C `a[i]` with a tainted index, and I/O is plain C `printf`. Of the six
increments, **only 7.1's wide-integer widths + curated `llvm.*` intrinsic table,
7.5's QRAM templates, and 7.6's I/O output-tape symbols (`cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`)) add new
*frozen* runtime ABI**; the rest (control flow) reuses the existing `cqrt_*` /
`cq_template_*` surface. (The post-core `8h7d` widening kjd1 — fp-DATA select,
2026-07-02 — later added one more frozen-designate family:
`cqrt_copy_f{16,32,64,80}_controlled`, `fp-data-select-PRD.md` §7; and the
control-in-place epic `drbq` — 2026-09-02 — added a second,
`cqrt_ry_<W>_controlled` ×9, `control-in-place-PRD.md` §5.) (The
math-demo epic `3c6m` grows the **generated** `cq_template_*` surface — 3c6m.4
added the long-double f80 fp-width rows + fpext/fptrunc grid, and 3c6m.5
(2026-07-03) added the cross-domain int↔f80 casts (`cq_template_{sitofp,uitofp,
fptosi,fptoui}_*_f80`, 2261→2315 symbols) — but adds **no new hand-written
`cqrt_*` family**: casts are arity-1 `i32`-handle-in/out, so f80's `long double`
c_type never materializes, and the surface is gated by the `opcode_table.yaml`
SHA + the `gen_templates_test` count, not a new ABI family. i128↔fp and f128
stay fenced/deferred.) That is the load-bearing reason the freeze (now Phase 11)
moves back: the ABI is gated on the QRAM memory model, the integer-width +
intrinsic-surface decisions, and the I/O tape ABI, **not** on the control-flow
work — which could in principle evolve even post-freeze. This phase
consolidates the items Phase 4 explicitly deferred (controlled `return`/`break`, plus
the `abort`/`exit` non-reconverging exit) and the loop / memory / opcode / I/O work the
prior roadmap parked under "Beyond the freeze." Each increment carries its PRD at its
start (Rule 16); the breakdown below fixes scope and sequence only.

**Why manual inversion (now Phase 8) lands *after* this phase.** `emit_inverse`
(`EmitInverse.cpp`) is a **closed per-call adjoint dispatch table with a loud-decline
default**, not an extensible framework. Loops, controlled-return, and QRAM each must
register their **own** adjoint rule into that spine **regardless of Phase 8** —
because the live Phase-5 whole-DAG uncompute driver needs the same rule to reverse
them at scope exit. `cq_invert` (Phase 8) is a thin consumer that *composes* over
whatever the spine already inverts, so it lands against the **settled** accept set:
smaller, lower-risk, and it avoids prematurely fixing the `_inv`-vs-`_unc` threading
decision against an incomplete surface. The dependency runs **feature → spine**, not
inversion → feature.

**Increments.**

- **7.1 — Opcode-surface completion [DONE 2026-06-20].** Close the cheap, currently-declined-but-
  reversible gaps (the genuinely-un-executable-under-quantum-control set is tiny —
  irreversibility enters through source-chosen *operations*, never an arithmetic
  opcode):
  - **Q+Q data-position compare** (`q1 < q2` *as data*): the `_qq` templates already
    exist; thread the Phase-4 control-path `HandleWidth` side-table (captured by SSA
    identity at `RotationLowering.cpp:164`, **before** rotation lowering RAUWs operands
    to `i32` handles) into the data-path `rewriteCompare` (today the width is handed only
    to the control path, so the data path's Q+Q branch loud-declines rather than guess
    `i32` — `CompareLowering.cpp`). **Scope detail (don't miss it):** `HandleWidth` is
    populated for *theta* handles only, so a **derived** operand (`q1+q2 < q3`, whose
    operand is an arith/cast-template result) has **no entry** — `ArithLowering` /
    `CastLowering` must also record their output width into `HandleWidth` when they mint
    a handle (each knows it from its own result type; pure bookkeeping, still no ABI).
    The compare's `i1` result is why this side-table is needed at all (unlike arith,
    which recovers its width from its own result type). Highest value, lowest risk,
    **no new ABI**. Hazard: a stale/wrong-operand width → wrong `_<W>_qq` symbol
    (verify-clean); mirror the proven control-path discipline exactly.
  - **`freeze`** on a tainted value: basis-level identity (taint passthrough),
    **decline-fixture-first** (Rule 12); must **not** become a path to launder an
    escaped value back into the taint domain.
  - **N-ary classical-condition merge**: generalize the existing one-register merge-φ
    lift (`declineClassicalMuxes`).
  - **Wide / intermediate integer widths** (`__int128`, `_BitInt(N)`, `_Float16`) —
    **IN for v1** (owner decision 2026-06-19). Extends the YAML widths-map +
    `WidthDispatch`. **Record at implementation:** a non-power-of-2 `_BitInt(N)`
    rounded up to the next ABI width changes overflow/wraparound semantics (`add nsw`
    on `i24` vs `i32`) — the lowering must mask the high bits — **and** it widens the
    **frozen** template surface, so it must land before the Phase-11 freeze, never
    after.
  - **Curated reversible `llvm.*` idiom intrinsics** (finding 2026-06-19, evidence-
    backed; see `bd memories llvm-idiom-intrinsics-reversible`). `clang -O1`
    **synthesizes** `@llvm.*` intrinsic calls for ordinary integer C idioms, and a
    tainted one currently hits `declineTaintEscapes` `kMsgUnknownCallee` (the
    `TaintPropagation.cpp` comment already cites the `llvm.smin` case) — yet they are
    **pure total functions, hence reversibilizable**, not decline-forever.
    **Confirmed at `-O1`** (re-derivable from `a<b?a:b` / `abs()` / `__builtin_*`):
    `@llvm.smin`/`smax`/`umin`, `@llvm.abs`, `@llvm.ctpop`, `@llvm.ctlz`/`cttz`,
    `@llvm.bswap`, `@llvm.uadd.sat`. Two classes — **bijections** (`bswap`,
    `bitreverse`, `fshl`/`fshr` rotate) lower in-place, 7.1-cheap; **non-injective but
    pure** (`smin`/`smax`/`umin`/`umax`, `abs`, `ctpop`, `ctlz`/`cttz`, `*.sat`,
    `*.with.overflow`) reuse **exactly** the compare/`_unc` Bennett recompute-from-
    live-sources model Phase 5 already ships. A **curated reversible-intrinsic YAML
    table** (sibling of `tools/opcode_table.yaml`); it **adds frozen template symbols**,
    so — like the wide-int widths — it must land **pre-freeze**. (fp transcendentals
    `@llvm.sqrt`/`sin`/… are SEPARATE = Phase-6 Path-1 curated libm substitution, not
    this; `*.with.overflow` additionally drags in `extractvalue` aggregate routing.)

- **7.2 — Controlled function-`return`** (reconverging early-exit) **[DONE 2026-06-23, epic `65wb`; 4 increments + owner decision `65wb.5`]**. Lift the permanent
  reject for a tainted-condition `if` whose one arm exits early via `return`, **for
  the bounded + reconverging (D4) subset only** — QCM injectivity + synchronization; a
  non-reconverging exit stays physics-rejected **forever**. Mechanism: per-site return
  register + a fixed **exit-priority cascade** (`SCOPING.md §4`) — no done-flag
  ancilla, no measurement, **no new ABI** (reuses `cqrt_cswap` / `cqrt_copy_<W>` /
  `emit_inverse`). This is a **core control change** (`ControlDetect` / `SwapRouteEmit`
  / `FreePoint` / `EmitInverse` — the modules where every silent miscompile has lived)
  with three documented-**unsolved** hazards the PRD must clear under Rule 13: (i)
  **tail-garbage reverse-play** (real gates run uncontrolled on parked-to-`|0⟩` rails,
  leaving branch-correlated garbage on the live register), (ii) **coherent return
  *values*** (the design's statevector sketch validated only basis bodies), (iii)
  **FreePoint's whole-function `ret`-as-Escaped** assumption vs. multiple parked exit
  registers. Ships with a dedicated decline diagnostic + fixture replacing today's
  generic "control flow under quantum control" catch-all.
  - **Non-reconverging exit — `abort`/`exit`/noreturn sinks** (owner discussion
    2026-06-19; `bd memories abort-exit-park-cascade`) join this same **park
    cascade** as its *no-value-select* member. `-O1` shape is a tainted-condition `br`
    into an arm of `tail call void @abort()` + `unreachable` (no merge `phi` → never
    reconverges). Mechanism: mint the abort flag, `cqrt_cswap` the live registers into a
    graveyard under it (pre-abort state **preserved + inspectable**), let downstream run
    **uncontrolled**, record the flag → **truncate the output tape** (7.6) at the abort
    point at inspection. The crucial asymmetry vs. controlled-`return`: abort
    **terminates**, so there is **no coherent downstream** → the branch-correlated
    tail-garbage (hazard (i)) is never observed and never dephases — **harmless**, and
    cheaper than gating every downstream op (which is reserved for the *non-terminating*
    conditional-output case, 7.6 Tier 0). Because abort never selects a value back, it
    **sidesteps** hazards (ii)/(iii) that controlled-`return` must clear.

- **7.3 — Bounded loops** (rolled-in-place; **core DONE** 2026-06-25, epic `799w` CLOSED
  — Inc 1 `799w.1` + Inc 2 `799w.2`, each Rule-13-cleared; deferred static-K unroll
  fallback `799w.3` re-parented to the 7.x-widenings tracker `8h7d`;
  **PRD** `docs/prd/phase-07-expressiveness/PRD-7.3.md`).
  **Model superseded 2026-06-24** (owner decision `bd memories owner-dynamic-circuits-in-model`):
  loops lower **rolled in place** — the loop CFG is **preserved** and the body's tainted
  ops lower to the same `cqrt_*`/`cq_template_*` stream the straight-line form produces;
  a **classical (untainted) trip/exit condition** is the gate, and the trip count need
  **not** be a compile-time constant (dynamic/runtime-classical bounds lower identically).
  **Static-K unroll is demoted to a deferred optional fallback** (`bd 799w.3`) for the
  cross-iteration-dirty-rail case only; `-O1` never unrolls a `cq_*` body, so 7.3 lowers
  the rolled shape directly. The accept set is the **sound-rolled invariant** — Case A
  (in-place persistent accumulator: collapse the loop-carried header phi to its single
  rail) **and** Case B (iteration-local born-and-dies temporaries, the per-iteration
  in-body uncompute). **Discharges the Phase-5 obligation:** extend `emit_inverse` +
  last-use uncomputation to **per-iteration in-body** recovery, lifting Phase 5's loud
  loop-backedge reject for exactly the proven iteration-local shape. **No new ABI.**
  Quantum/measurement-bounded (tainted-condition) loops **decline** (different model);
  cross-iteration dirty rails **decline** (→ deferred unroll). Hazard: a per-iteration
  free placed at a once-per-function point runs K times (use-after-free + double-free) —
  the in-body free point must be **proven** once-per-iteration, not inferred.

- **7.4 — Controlled `break`** (value-arm, rolled-in-place) — **core DONE** (`y05j`
  CLOSED, 2026-06-26). A classically-bounded data-mutating loop with a single tainted
  value-arm `break` lowers **rolled**: the rail collapses to one in-place handle, the
  loop terminator is stripped to the **classical bound** (the loop runs its full trip
  count — the break is virtual, no measurement), and the break is realized by an
  **index-gated copy-not-move capture + whole-loop reverse-play** (forward body ×n,
  capture into `R` under `fire = brk ∧ (idx==0)`, exit consolidation + `cqrt_copy`
  copy-out into `out`, a backward companion loop replaying the per-iteration adjoint
  `C†` to return `R`/`idx`/rail to |0>/q0, then `cqrt_free`). NOT the 7.2 cascade
  (the framing correction, `bd memories 7.4-break-design-crux`): a rolled loop
  re-executes its break site K times, so the sound lowering is Bennett
  compute→copy→uncompute over the whole loop, **O(1)** carried ancilla, **dynamic-K**.
  No new frozen ABI (reuses `cqrt_alloc`/`cqrt_copy[_controlled]`/`cqrt_toffoli`/the
  `emitInverseChain` spine, extended with the dtzb `cqrt_xorc`/`cqrt_addc` adjoints).
  Cleared by **three** adversarial Rule-13 rounds (7 over-accept holes found+fixed as
  the E1–E11 decline preconditions; the canonical capture+reverse-play verified
  correct by reversible-semantics sim-replay). Phase-arm break, multiple-site,
  nested-loop break, `continue`, and the genuinely quantum-bounded `while` decline
  loudly (the §2.10 partition). Bounded + reconverging only. The decline-safe
  multiple-site / nested-loop / `continue` / mixed break+return widenings are tracked
  under the 7.x-widenings epic `8h7d`.

- **7.5 — QRAM, full Shadow model** (owner decision 2026-06-19). Lower `load` /
  `store` / `getelementptr` over a tainted index/address via the **Shadow** memory
  strategy (Bennett's reversible-memory family). New taint rules (memory ops currently
  hit `declineTaintEscapes`) **and new frozen runtime ABI** — this is the
  **freeze-gating** increment. The uncompute spine must **own** the write rails: a
  freed entangled write rail is a hidden measurement (Rules 6/8). **Shadow is the v1
  strategy**; MUX-EXCH / QROM / Feistel and pointer aliasing stay deferred as post-freeze
  optimizations. **The whole memory model is validated against the sibling `Bennett.jl`**
  (advisor T. Osborne's classical→reversible compiler; `bd memories
  pointer-boundary-linearity-bennett`), which lowers `alloca`/`load`/`store`/`gep` with
  dynamic (quantum) indices via **five per-allocation strategies — Shadow, MUX-EXCH,
  QROM, Feistel, Persistent-DS** — and so supplies CQ's **concrete post-7.5 roadmap**
  (Shadow now; the rest as named post-freeze cost-tiers). The load-bearing precondition,
  shared with Bennett, is that **every allocation has a known shape (width × count) at
  compile time**: dynamic-index access into managed, known-shape memory is reversible
  (Bennett-OK), but arbitrary aliasing / no-provenance pointers (`inttoptr`/`ptrtoint`),
  heap escape, and runtime-unshaped containers stay rejected — **not as a CQ shortcut but
  because reversibility ⟺ linearity ⟺ no-cloning** (triangulated: Bennett's pebble game,
  the Axelsen–Glück linear reversible heap, and `Bennett.jl`'s own reject set all draw
  this exact line). Reversible **linked lists / dynamic structures** are reachable, but
  only as *managed, shaped, opt-in* structures (Bennett's Persistent-DS), never raw
  pointers. CQ ingests **C** (which emits `inttoptr`/aliasing readily, unlike Bennett's
  memory-safe Julia), so it trips the loud memory-reject far more often — make those
  diagnostics **precise** (Bennett's "signpost naming the offending pattern" is the
  model).

  - **7.5 status (epic `7z9k`, 3 increments):** **Inc 1 DONE 2026-06-23** —
    const-global tainted-index READ (QROM-shaped): frozen `cqrt_qram_alloc_<W>` +
    `cqrt_qram_load_<W>` (+ `_unc`), `W ∈ {i1,i8,i16,i32,i64}`. **Inc 2 DONE 2026-06-23**
    — alloca-backed tainted-index STORE/LOAD (Shadow-shaped): frozen
    `cqrt_qram_store_<W>` (+ `_unc`, void in-place on the array handle; the backend
    owns the per-store tape, the IR pass owns only the reversal ORDER); the array
    handle is a TAINTED in-place-mutated register the whole-DAG spine reverses (a dead
    scratch array's stores reverse in strict LIFO; an escaped/observed array reverses
    nothing) and is NEVER freed (§2.9); off-pattern shapes (mixed same-array access,
    pointer escape, mid-sequence observation, dynamic-N, fp/i128 cell) decline loudly.
    Both increments INDEPENDENT-Rule-13-CLEARED. **Inc 3 DONE 2026-06-24** — the
    fuller single-origin provenance walk (`matchQramAccess`/`walkPtrOrigin`/
    `isDirectOriginPtr`: flat element geps + gep chains + pointer phi/select proved
    to a single statically-shaped origin with a zero offset; multi-origin declines)
    + the complete pattern-naming over-accept decline matrix (multi-origin,
    inttoptr/ptrtoint, addrspacecast, dynamic-N, heap, aliasing fan-out, in-loop,
    non-zero initializer, fp/i128 cell), each a mirrored negative fixture; plus the
    two Inc-2 over-decline follow-ups (the §2.8(iii) mid-seq guard now recognizes
    `cqrt_tape_write_` output sinks → clean `kMsgQramMidSeq`; the straight-line
    dead-load-then-store `arr[p]=arr[q]` accept, fixing a latent Inc-2 stale-operand
    crash). INDEPENDENT-Rule-13-CLEARED (~40 adversarial probes; the review FOUND
    and the fix CLOSED a non-zero-`memset` silent-miscompile over-accept — PRD §6
    risk #5 — now `kMsgQramInit`). **Phase 7.5 epic `7z9k` COMPLETE.** See
    `docs/prd/phase-07-expressiveness/PRD-7.5.md` + `INC-7.5.3-DESIGN.md`.

- **7.6 — Reversible I/O (output tape) [DONE 2026-06-21]** (owner discussion 2026-06-19; `bd memories
  reversible-output-tape-io`). Lower a tainted I/O sink — `printf`/`puts`/`putchar` —
  **coherently, never by measurement**: replace each tainted `i32` scalar arg with an
  XOR-copy (`cqrt_copy_<W>`) into a **fresh `|0⟩` output rail**, **one rail per emitted
  value** (an append-only **tape**, never a single XOR-accumulator — that loses the
  transcript). The format string + literal text stay **classical** (replayed at
  inspection); **integer scalars only** (`%f`/`%s`/pointer args are OUT — fp-data is the
  angle hazard). Output rails are **Escaped** — never uncomputed, never freed (the
  Bennett output-tape = kept output qubits). The win: a `printf` no longer forces a
  measurement **at** the print site; it is **deferred** to tape inspection, so `q` stays
  coherent. Composes with control (`if(q) printf` = one **controlled** `cqrt_copy`,
  Tier 0) and supplies the truncation hook 7.2's `abort`/`exit` reads. Fixed tape size
  from the static site count (dynamic growth only for unbounded loops, post-freeze);
  `-O1` evidence: `printf("%d", x)` → `@printf(ptr @.str, i32 %x)` — the tainted scalar
  is a **positional** `i32` arg, so varargs is no obstacle (intercept by name+position,
  **no clone**). **Adds a small frozen ABI** — `cqrt_tape_alloc` + `cqrt_tape_write_<W>` (+
  `_controlled`) — so the backend owns physical allocation / output-qubit count /
  inspection / truncation; the IR pass declares intent + ordering only and keeps the
  rail (the Escaped / `OutputRails` marker). 7.6 is therefore **pre-freeze**
  (PRD-7.6, owner decision 2026-06-21, revising the earlier "likely no new ABI").
  This is the **coherent replacement for the permanently-rejected
  `-fcq-measurement-bridge`** (owner: *never* — a transparent auto-measure silently
  collapses the user's state, Rule 5).

**Done when:** programs using Q+Q data compares, wide integers, the `llvm.*` idiom
intrinsics, controlled early-`return`, `abort`/`exit`, bounded `for`/`while`, `break`,
tainted `printf`/`puts`/`putchar` output, and tainted-index array access lower to the
expected `cqrt_*` / `cq_template_*` sequences — `opt -verify` clean, golden e2e trace
diffs clean — while every off-pattern shape (a **value-carrying** non-reconverging exit,
unbounded loop, aliasing / no-provenance pointers, runtime-unshaped memory, unprovable
trip count, fp/string/pointer I/O args) declines loudly with a source-located
diagnostic; each core-lowering increment is cleared by independent adversarial Rule-13
review (a green suite alone does not clear it).

---

## Phase 8 — IR pass: manual inversion + adjoint generation

**Goal.** `cq_invert_begin` / `cq_invert_end` brackets lowered to the
adjoint of the bracketed sequence; reuses §5's `emit_inverse`. Closes
the user-facing inversion surface. Sequenced **after** Phase 7 so it composes
over the **full** invertible surface (the controlled-return, bounded-loop, and
QRAM adjoint rules Phase 7 registers into `emit_inverse`) in one pass — see
Phase 7's dependency note. `cq_invert` is a thin consumer of the shared adjoint
spine, not a new control mechanism; its one real subtlety is the
forward-threaded `_inv` operation vs. the void rail-zeroing `_unc` step (the
`CurHandle` hook in `EmitInverse.h` is the seam reserved for it), which is
resolved once against the settled accept set rather than re-litigated as each
feature widens the inversion domain.

**Scope.**
- Bracket identification: `@cq_invert_begin` / `@cq_invert_end` marker
  call sites at module level (preserved through `-O1` because the
  declarations are side-effecting).
- Collect the gate sequence between the markers (post-lowering: every
  `cqrt_*` and `cq_template_*` call inside the bracket, plus any
  `_controlled` variants if the bracket sits inside a tainted-branch
  shadow).
- Apply `emit_inverse` from §5 to the collected sequence.
- Replace the forward calls with the adjoint sequence; erase the
  marker calls.
- Forward + controlled-forward template commitment: the runtime
  declares only forward and controlled-forward; the inverse comes from
  `emit_inverse`, halving the per-primitive surface.

**Components touched:**
- New `ManualInversion` module in `ir-pass/src/`.
- The Phase 5 `Uncomputation` module's `emit_inverse` helper, shared
  across both call sites.

**Done when:** programs containing `cq_invert_begin()` / `cq_invert_end()`
brackets produce the reversed-and-adjointed call sequence as their
lowering, and the brackets themselves disappear from the IR. Brackets
nested inside a tainted-branch **swap-route region** invert correctly —
the bracketed body is routed onto the arm's live rail like any arm body,
so its inversion composes with the region's reverse-play.

---

## Phase 9 — Runtime template library completion

**Goal.** Lock the runtime ABI (declarations + trace-only bodies) for
the full 38-opcode × applicable widths × `{HH, HL, inv}` cross-product,
plus the swap-route control primitives, **the Phase-7.1 wide-integer widths
(`__int128` / `_BitInt` / `_Float16`) + curated `llvm.*` idiom-intrinsic table, and
the Phase-7.5 QRAM Shadow memory templates, and the Phase-7.6 I/O output-tape
symbols (`cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`))** (the four new frozen ABI families). Bodies remain stubs through the
Phase 11 freeze; only the declared symbol set + the trace format need to
be stable.

**Reconciliation with swap-route Phase 4 (principle 7).** Control no longer rides
a `_controlled` template per gate, so the **`_controlled` cross-product is not the
control mechanism** and is *not* the load-bearing half of the freeze. The control
ABI to freeze is instead the routing set — `cqrt_cswap`, `cqrt_alloc_<W>`,
`cqrt_free` (all present) — plus the **one new primitive** the classical-arm
increment adds: the per-width reversible copy `cqrt_copy_<W>` (Phase 4.2; confirm
the width set first). The `_controlled` family is **retained** (it costs nothing
to keep declared) only as the reserve for the optional §6a control-in-place
peephole; it may be frozen-but-unused rather than deleted. `emit_inverse` still
supplies every adjoint, so `inv` stays derived, not shipped.

**Scope.**
- `tools/opcode_table.yaml` covers the full surface; `gen_templates.py`
  emits `runtime/cq_templates.h` with the SHA hash preamble; CI rebuilds
  and verifies. (The autogen exists today; the cross-product needs
  exhaustive coverage.)
- Trace bodies in `runtime/cq_templates.c`: each declared symbol gets a
  trace-only body printing the symbol name + arguments + returned
  handle, in the format the existing `test_trace.c` already exercises.
- Runtime variant skeleton: `libcq_runtime_count.so` (per-symbol counter
  table), `libcq_runtime_sim.so` (statevector hook, declared but
  unimplemented) per [`docs/backend.md`](docs/backend.md) §11.5.
  Implementation deferred; the API surface is the freeze gate.
- Symbol-versioning preamble + `cqrt_abi_version()` query function per
  [`docs/backend.md`](docs/backend.md) §11.6.
- Distribution-shape decision per [`docs/backend.md`](docs/backend.md)
  §12.4: `.bc` (LTO) + `.a` (native) shipped; pass-internal IRBuilder
  remains an option.

**Done when:** every symbol the IR pass emits in Phases 2–8 resolves
against the runtime; the trace runtime can replay any Phase 2–8 test
fixture without missing-symbol errors. Symbol-version preamble in
place; ABI surface frozen for Phase 11 gate.

---

## Phase 10 — Integration test harness

**Goal.** End-to-end CQ programs covering the full Phases 1–8 feature
surface, each producing the expected trace-runtime call log. The
harness becomes the regression suite for both the Phase 11 freeze and
any post-freeze backend-implementation work.

**Scope.**
- E2E fixtures organized by feature:
  - Gate-triggered allocation (chained rotation; single-rotation;
    never-rotated-classical).
  - Mixed Q+C arithmetic across the 38-opcode surface (Phase 3
    coverage spot-checks).
  - Tainted-branch control flow (Phase 4): single branch, nested,
    mixed-condition.
  - Function lifting (Phase 6): curated symbol substitution path
    (libm); clone-on-taint path (user-defined); recursive
    specialization; rejection diagnostics.
  - Expressiveness completion (Phase 7): Q+C compares incl. Q+Q data
    position, wide integers (`__int128`/`_BitInt`), `llvm.*` idiom
    intrinsics (min/max/abs/popcount/bswap/…); controlled early-`return`,
    `abort`/`exit`, `break`; bounded `for`/`while`; tainted `printf`/`puts`
    output tape; tainted-index QRAM `load`/`store`; the matching off-pattern
    decline fixtures (value-carrying non-reconverging exit, unbounded loop,
    aliasing / no-provenance pointers, fp/string I/O args).
  - Manual inversion (Phase 8) inside and outside tainted-branch
    shadows.
- Diagnostic fixtures: each rejection-set entry from
  [`docs/backend.md`](docs/backend.md) §7.4 has a fixture asserting the
  expected error message + source-location precision.
- CI wiring: every fixture runs under the trace runtime; output
  diffed against an `.expected.log` checked into the repository.

**Components touched:**
- New `tests/e2e/` directory (replaces the archived old-design e2e
  fixtures at `docs/archive/old-design/`).
- CI config: a green run of the e2e harness gates merge.

**Done when:** the harness covers every user-visible behavior the
frontend / backend docs specify, and a green run is the precondition
for Phase 11.

---

## Phase 11 — Frontend + ABI freeze + handoff to backend implementation

**Goal.** Lock the frontend surface and the runtime ABI; explicit gate
before any post-freeze work (real gate-sequence template bodies,
simulator runtime, unbounded quantum-while semantics, dynamic circuits).
Now deferred behind the Phase-7 expressiveness work; the freeze is gated
specifically on the QRAM Shadow memory ABI (Phase 7.5), the wide-integer width
decision (Phase 7.1), the curated `llvm.*` idiom-intrinsic table (Phase 7.1), the
I/O output-tape ABI (`cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`), Phase 7.6), and the
fp-DATA select controlled-copy family (`cqrt_copy_f{16,32,64,80}_controlled`,
the `8h7d` widening kjd1 — `fp-data-select-PRD.md` §7), and the control-in-place
rotation family (`cqrt_ry_<W>_controlled` ×9, epic `drbq` —
`control-in-place-PRD.md` §5) — the pre-freeze items
that add new frozen symbols (the 7.2/7.4 control work reuses existing `cqrt_*` /
`cq_template_*`).

**Deliverables.**
- **CQ.h freeze.** Semver pinned; future additions versioned per the
  freeze policy. The 14 × 3 = 42 specializations plus the 3 `_Generic`
  macros plus the `cq_invert_*` pair are the v1.0 frontend surface.
- **`libcq_runtime` + `libcq_templates` ABI freeze.** Symbol versioning
  per [`docs/backend.md`](docs/backend.md) §11.6; `cqrt_abi_version()`
  query function; documented deprecation policy. The core `cqrt_*`
  runtime symbols (allocators + measure + `cqrt_free` + the Phase-4
  routing/copy primitives `cqrt_cswap`/`cqrt_copy_<W>` + the Phase-7.5
  QRAM memory symbols + the Phase-7.6 I/O output-tape symbols
  `cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`)) + the autogenerated template surface (incl. the
  Phase-7.1 wide-integer widths + curated `llvm.*` idiom-intrinsic table) are
  the v1.0 backend ABI.
- **Diagnostic-fidelity audit.** Which `-O1` passes the `!dbg` metadata
  survives; baseline acceptable for the diagnostic story established in
  Phases 5–8.
- **MLIR re-evaluation gate.** Explicit decision against re-trigger
  conditions: did any IR-pass mechanism in Phases 2–8 demand an
  intra-dialect transformation the new PassManager cannot express
  cleanly? If yes, post-freeze scope expands to evaluate MLIR adoption
  for a future v2; if no, the intrinsic + stock-LLVM approach is locked
  for v1.
- **Phase 10 regression harness green.** The integration suite is the
  freeze gate's pass/fail signal.

**Done when:** all deliverables ship, the regression harness is green,
and the frontend / backend / quantum-classical-handling /
llvm-implementation documents carry a "v1.0 frozen" marker. Backend
implementation (real gate-sequence template bodies, simulator runtime,
optimization passes) is sequenced under a post-freeze roadmap revision.

---

## Beyond the freeze (out of scope for this roadmap)

Sketched here only as pointers; phasing for these is the subject of the
post-Phase-11 roadmap revision.

- **Real template bodies.** Reversible-circuit implementations for the
  38-opcode surface ([`docs/backend.md`](docs/backend.md) §12.3):
  ripple-carry / Cuccaro / Draper adders; Karatsuba multiplier; etc.
  Per-opcode variant selection (compiler flag, cost model, runtime
  hint) becomes load-bearing here.
- **Simulator runtime.** `libcq_runtime_sim.so` with statevector or
  density-matrix backend; OpenQASM emitter; hardware transport.
- **Optimization passes.** Gate cancellation, adjacent-gate fusion,
  ancilla reuse, T-count / depth targeting. Some pieces feasible at
  template-call granularity under stubs (adjacent inverse cancellation
  `cq_template_X_inv ∘ cq_template_X`); the full set needs real
  template bodies.
- **Unbounded / quantum-conditioned `while` loops.** Data-dependent or
  amplitude-amplification iteration whose **trip/exit condition is tainted**
  (quantum/measurement-derived). **Classically-bounded** loops moved **into Phase
  7.3** — lowered **rolled in place** (not unrolled; superseded 2026-06-24,
  `bd owner-dynamic-circuits-in-model`), which discharges the Phase-5
  uncompute-extension obligation (extend the `emit_inverse` + last-use machinery to
  **per-iteration in-body** recovery, lifting Phase 5's backedge reject) for the
  sound-rolled shape. What remains here is the genuinely **quantum-bounded** case
  (amplitude amplification, transform-to-bounded-for, measurement-derived
  bounds) — a tainted-condition loop branch, which 7.3 loud-declines — punted past
  the freeze to keep v1.0 narrow (see
  [`docs/archive/old-design/phases/phase05-uncomputation/PRD.md`](docs/archive/old-design/phases/phase05-uncomputation/PRD.md)
  §2.9).
- **Dynamic circuits.** Measurement-derived loop bounds; mid-circuit
  measurement feedback. Out of scope until post-backend.
- **Cross-language input.** `rustc --emit=llvm-bc`, `flang -emit-llvm`,
  etc. participate in `clone-on-taint` once their bitcode is in the LTO
  link. The frontend-language surface for these is post-freeze polish.
- **Memory model beyond Shadow.** The **Shadow** strategy for
  `load`/`store`/`getelementptr` over a tainted index moved **into Phase 7.5**
  (the v1 QRAM strategy). What remains post-freeze is the **alternative
  strategies** the sibling `Bennett.jl` already ships — **MUX-EXCH** (small dynamic
  arrays), **QROM** (const tables), **Feistel** (bijective key-hash), and
  **Persistent-DS** (runtime-unbounded but known-shape mutable memory; the path to
  reversible **linked lists / dynamic structures**) — cost-modelled per access, as
  optimizations over the frozen Shadow ABI. Two things are **not** deferrals but
  permanent rejections: memory whose **shape is unknown at compile time**
  (runtime-sized / `Dict`-like) and **arbitrary aliasing / no-provenance pointers**
  (`inttoptr`/`ptrtoint`, heap escape) stay rejected **forever** — reversibility ⟺
  linearity ⟺ no-cloning, the exact line `Bennett.jl` draws (`bd memories
  pointer-boundary-linearity-bennett`).

---

## Sequencing notes

- Phase 1 (header) is independent and can ship in isolation.
- Phase 2 (taint sources + gate-triggered allocation) is the first IR
  pass work and the precondition for everything else in the pass.
- Phases 3 (opcode breadth) and 4 (swap-route control) can be developed
  in parallel after Phase 2; both consume the same `TaintPropagation`
  output without interacting. Phase 4 additionally reuses Phase 5's
  `emit_inverse` + `FreePoint` spine for its coherent reverse-play, so in
  practice the early Phase-5 spine lands alongside Phase 4.1.
- Phase 5 (uncomputation) needs Phase 3's template surface ready for
  `_inv` emission but is otherwise parallel with Phase 4.
- Phase 6 (function lifting) is the largest IR-pass workstream and
  benefits from having Phases 3–5 done so it can reuse their lowering
  pipeline inside cloned bodies.
- Phase 7 (pre-freeze expressiveness completion) is the live workstream
  after Phase 6. Internal order: **7.1 opcodes + `llvm.*` intrinsics** ✓ DONE
  (independent, parallelizable, lowest risk) → **7.6 I/O output tape** ✓ DONE
  (independent, low-risk; supplies the abort tape-truncation hook) →
  **7.2 controlled-return + `abort`/`exit`** ✓ DONE (proved the exit-cascade +
  uncompute coupling on a backedge-free substrate; the `abort` half reads
  7.6's tape) → **7.3 bounded loops** ✓ DONE (forces the Phase-5 uncompute
  extension) → **7.4 break** ✓ DONE (needs 7.2 + 7.3; value-arm capture +
  whole-loop reverse-play) → **7.5 QRAM Shadow** ✓ DONE
  (heaviest; new ABI; gates the freeze). Phase 7 **core** complete (7.1–7.6 core DONE
  — scoped increments shipped + Rule-13-cleared; post-core break/loop widenings tracked
  under the decline-safe, freeze-orthogonal 7.x-widenings epic `8h7d`).
- Phase 8 (manual inversion) is small and lands **after** Phase 7 so it
  composes over the full invertible surface in one pass; it depends on
  Phase 5's `emit_inverse` plus the per-construct adjoint rules Phase 7
  registers (the dependency runs feature → spine, not inversion → feature).
- Phase 9 (runtime templates) is mostly autogenerated and can land
  alongside Phases 3–8 incrementally; it must absorb the 7.1 wide-integer
  widths and 7.5 QRAM symbols before the freeze.
- Phase 10 (integration harness) accumulates fixtures alongside Phases
  2–8 and concludes at the Phase 11 freeze.
- Phase 11 (freeze) is a gate, now deferred behind the Phase-7 capability
  work; nothing else lands before it, and it is gated specifically on the
  QRAM memory ABI and the wide-integer width decision. Post-Phase-11 work
  is designed under a future roadmap revision.
