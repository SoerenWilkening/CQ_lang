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
   deferred to Phase 10 freeze gate.

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
- FP compare: `fcmp` × 6 ordered predicates `{oeq, une, olt, ogt, ole, oge}`
  (the realized `-O1` no-fast-math surface — see the reconciliation note below;
  supersedes "× 14 predicates").
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
- **`fcmp`: 6 ordered predicates, not 14.** `clang -O1` (no fast-math) emits
  exactly `{oeq, une, olt, ogt, ole, oge}`; the yaml's `one` was a bug (clang
  emits `fcmp une` for `!=`, never `one`), fixed to `une` and closing
  `test_C_libtooling-7ws`. The 8 unordered / fast-math-only predicates (incl.
  `one`) stay out of scope until fast-math enters the floor (PRD §2.7, §5).
- **`frem` has no C-operator source.** Float `%` is illegal C; `frem` arrives
  only via `fmod()` (a Phase 6 libm substitution), so its lowering is pinned by
  a hand-written `.ll` fixture rather than a C-sourced e2e smoke (PRD §2.6).
- **`sub_hl` is unreachable from C; `sub` survives as `sub_lh`.** `-O1`
  canonicalizes `x - C` to `add x, -C`, so a handle-minus-literal never reaches
  the pass as `sub`; `sub` survives only as `C - x` → `sub_lh`. The arith smoke
  pins this (`x - 3` → `add_i32_hl(h, -3)`; `100 - x` → `sub_i32_lh(100, h)`).

---

## Phase 4 — RSSA swap-routed tainted control flow [4.0 clean-slate DONE · emitter in progress]

**Design:** [`docs/design/rssa-swap-control/SCOPING.md`](docs/design/rssa-swap-control/SCOPING.md)
+ [`OVERVIEW.md`](docs/design/rssa-swap-control/OVERVIEW.md); IR target fixtures
`swap_route_if_diamond.ll`, `swap_route_ifelse.ll`,
`swap_route_if_diamond_uncompute.ll`.

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

**Non-negotiable principles (design + author, 2026-06-08):**
- **Coherent-first; no measure-only mode.** Coherence is restored *unitarily* by
  region-local **reverse-play** — the adjoint of the forward stream, via
  `emit_inverse` — so results are correct under downstream interference (Grover
  etc.). Reverse-play is **mandatory in every increment**, never deferred.
- **No added measurements — ever.** The compiler never inserts a measurement the
  user did not write (hard project invariant). The only reclamation discipline is
  "free a rail only after reverse-play returns it to `|0⟩`" (§3b) — freeing an
  entangled rail would be a hidden measurement that collapses `q`.
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

- **4.1 — Swap-route emitter, rotation arms (method-A).** `if`-diamond then
  `if/else`, targeting `swap_route_if_diamond.ll` / `swap_route_ifelse.ll`. The
  answer (phase/superposition) stays on `q`; only the work rail is cleaned, by a
  controlled-adjoint of the body on the inactive branch (§3a-A). **No new runtime
  ABI** — reuses `cqrt_cswap`, `cqrt_alloc_<W>`, `cqrt_free`, `cqrt_rz/ry/x`, and
  `emit_inverse`. The br/diamond cswap **emission wiring** is net-new (today
  `cqrt_cswap` is emitted only on the removed MUX-EXCH path).

- **4.2 — Classical-permutation arms (method-B).** `add`/`mul`/`x`/`toffoli`
  bodies: run `R` → CNOT-copy the basis-valued result into a fresh register →
  reverse-play `R†` to restore `q0` and zero the rail (§3a-B), targeting
  `swap_route_if_diamond_uncompute.ll`. Adds the design's **only new ABI**: the
  per-width reversible copy `cqrt_copy_<W>` (one transversal-CNOT copy per width —
  confirm the width set + semantics first, §7.6). This re-opens the Phase-8/10
  freeze for that one family.

- **4.3 — Nested control.** A tainted `br` inside an arm runs the **same emitter
  recursively** on the enclosing arm's live rail; `c1 ∧ c2` falls out of the
  routing structure with **no conjunction ancilla**. Reverse-play composes over
  the region tree (mechanical stack unwind).

- **4.4 — `select` (trivial).** Reimplement the tainted-`select` merge as a
  controlled-XOR copy into a fresh register — no cswap routing, no flag bracket.
  The old P6 rejection (coherent-handle copy interfered downstream) may relax for
  classical operands, which XOR-copy reads non-destructively.

- **4.5 — tainted `switch`.** Re-add (the old `SwitchNormalization` was removed):
  lower an N-way tainted `switch` via per-case routing / `icmp eq`-flag select
  chain into the same emitter — no N-way `phi` dissolution, no new control region.

**Deferred to later increments (coherent — NOT measurement-restricted):**
- **Controlled `return` / `break`** (§4): per-site return registers + an
  **exit-priority cascade** (a fixed permutation — **no done-flag ancilla, no
  measurement, no overhead**). Lifts the permanent P2/P3 rejections for the
  **bounded + reconverging (D4)** subset only; non-reconverging exits stay
  rejected by physics (QCM injectivity). Coherent return *values* ride the same
  §3a reverse-play obligation.
- **Control-in-place peephole** (§6a): for genuinely-in-place single-target
  unitaries (`R_z`/`R_y`/Pauli), control in place (no work rail) — a footprint
  optimization, not a correctness requirement.

**Soundness obligation (§3b).** `cqrt_free` (compiler-emitted only) is emitted on
a rail **only after** its reverse-play returns it to `|0⟩`, via the `FreePoint`
post-dominator discipline (never when the handle escapes or is the user's measured
output — there the caller owns it).

**Done when:** programs with tainted `if` / `if-else` / nested / `select` /
`switch` lower to the swap-route IR the `.ll` fixtures pin — coherent (reverse-play
emitted, rails freed clean), `opt -verify` clean — and the e2e trace smokes diff
clean against goldens captured from real linked output (the layer that proves
every emitted symbol resolves + signature-matches).

## Phase 5 — IR pass: per-op uncomputation

**Design:** see [`docs/prd/phase-05-uncomputation/PRD.md`](docs/prd/phase-05-uncomputation/PRD.md).

**Goal.** Productionize the prototype's `cq-uncompute` slice past the
`cqrt_free`-placeholder stage; emit the adjoint of each tainted **data**
handle's gate chain at the SSA last-use point. Phase 5 owns *source-derived
data* handles; *pass-invented control scratch* (flags, conjunction
`toffoli`, MUX-EXCH non-selected sources) is already uncomputed by Phase 4
(PRD §2.2).

**Reconciliation with swap-route Phase 4.** The controlled-op flag/conjunction
scratch that PRD §2.2 referenced no longer exists (that path was removed). Under
swap-route, Phase 5's machinery is *reused, not bypassed*: `emit_inverse` is the
engine for Phase 4's region-local **reverse-play** (rail cleanup), and the
`FreePoint` last-use / escape analysis computes the §3b "free a rail only after it
is `|0⟩`" point. The "data handle last-use uncompute" Phase 5 productionizes and
the "rail reverse-play" Phase 4 emits share the same `emit_inverse` + `FreePoint`
spine — Phase 5 stays largely as written; only the cross-reference to control
scratch is restated as the swap-route rail discipline.

**Scope.**
- Last-use computation: per the validated Phase 5 prototype mechanism —
  `Value::users()` → user-block set → `PostDominatorTree`-derived
  nearest common dominator → `getFirstInsertionPt()` of the resulting
  block.
- Adjoint emission: `emit_inverse` walks the lowered gate sequence
  backward, emits inverse templates per [`docs/backend.md`](docs/backend.md)
  §10.1. While template bodies remain stubs, `emit_inverse` walks at
  the *template-call* granularity (`cq_template_<op>_<W>_inv`); once
  bodies are real, the same `emit_inverse` walks at gate granularity.
- `cqrt_free(handle)` emitted after the adjoint sequence at the same
  insertion point.
- Escape detection: skip emission if `%h` is consumed by a `ReturnInst`
  (caller owns it), if enclosing function is `main`, or if `%h` is
  inside an explicit `cq_invert_*` region (Phase 7 supersedes).
- Diagnostics: source-location-preserved error at use-site when
  uncomputation is required of a non-adjointable result.
- **Acyclic-CFG assumption; loops deferred.** Phase 5 reverses on
  straight-line / diamond CFGs (no backedges); a tainted handle whose live
  range crosses a loop backedge is **diagnosed loudly**, not miscompiled.
  Loop uncomputation (loop-carried registers, per-iteration reversal)
  **extends** this mechanism when loops land — it does not replace it (see
  the loop section under "Beyond the freeze"; PRD §2.9).

**Components touched:**
- New `Uncomputation` module in `ir-pass/src/` (the prototype's
  `cq-uncompute` slice, lifted into the production pass-plugin module
  layout).
- `runtime/cq_templates.h`: `_inv` variants for every forward template
  (already declared per the autogenerator).

**Done when:** programs producing tainted handles with mid-function
non-`main` last-use points emit inverse-template-call sequences at the
correct post-dominator block; multi-BB CFG case green (Phase 5
prototype's `input_phase5_branch.ll` trajectory).

---

## Phase 6 — IR pass: call-graph specialization (function lifting)

**Goal.** Productionize the prototype's `cq-specialize` slice into a
full worklist-driven specialization synthesizer with both lifting paths
(curated symbol substitution + clone-on-taint) and the rejection-set
classifier.

**Reconciliation with swap-route Phase 4.** A **quantum-controlled call** no
longer needs a controlled specialization of the callee: swap-route routes the
argument into the callee's input iff the condition holds, calls the function
**unconditionally**, and routes the result back (`OVERVIEW.md`). So the
controlled-call branch of specialization is **dropped** — only the
tainted-**data**-argument clone-on-taint (Path 2) and curated substitution
(Path 1) remain in scope here. Bounded recursion is still the unrolled form.

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
reachable function vs. opt-in only); concrete mangling scheme;
`-fcq-measurement-bridge` opt-in for measurement-at-rejected-boundary.

---

## Phase 7 — IR pass: manual inversion + adjoint generation

**Goal.** `cq_invert_begin` / `cq_invert_end` brackets lowered to the
adjoint of the bracketed sequence; reuses §5's `emit_inverse`. Closes
the user-facing inversion surface.

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

## Phase 8 — Runtime template library completion

**Goal.** Lock the runtime ABI (declarations + trace-only bodies) for
the full 38-opcode × applicable widths × `{HH, HL, inv}` cross-product,
plus the swap-route control primitives. Bodies remain stubs through the
Phase 10 freeze; only the declared symbol set + the trace format need to
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

**Done when:** every symbol the IR pass emits in Phases 2–7 resolves
against the runtime; the trace runtime can replay any Phase 2–7 test
fixture without missing-symbol errors. Symbol-version preamble in
place; ABI surface frozen for Phase 10 gate.

---

## Phase 9 — Integration test harness

**Goal.** End-to-end CQ programs covering the full Phases 1–7 feature
surface, each producing the expected trace-runtime call log. The
harness becomes the regression suite for both the Phase 10 freeze and
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
  - Manual inversion (Phase 7) inside and outside tainted-branch
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
for Phase 10.

---

## Phase 10 — Frontend + ABI freeze + handoff to backend implementation

**Goal.** Lock the frontend surface and the runtime ABI; explicit gate
before any post-freeze work (real gate-sequence template bodies,
simulator runtime, quantum-while semantics, dynamic circuits).

**Deliverables.**
- **CQ.h freeze.** Semver pinned; future additions versioned per the
  freeze policy. The 14 × 3 = 42 specializations plus the 3 `_Generic`
  macros plus the `cq_invert_*` pair are the v1.0 frontend surface.
- **`libcq_runtime` + `libcq_templates` ABI freeze.** Symbol versioning
  per [`docs/backend.md`](docs/backend.md) §11.6; `cqrt_abi_version()`
  query function; documented deprecation policy. The 15 `cqrt_*`
  runtime symbols + the autogenerated template surface are the v1.0
  backend ABI.
- **Diagnostic-fidelity audit.** Which `-O1` passes the `!dbg` metadata
  survives; baseline acceptable for the diagnostic story established in
  Phases 5 / 6 / 7.
- **MLIR re-evaluation gate.** Explicit decision against re-trigger
  conditions: did any IR-pass mechanism in Phases 2–7 demand an
  intra-dialect transformation the new PassManager cannot express
  cleanly? If yes, post-freeze scope expands to evaluate MLIR adoption
  for a future v2; if no, the intrinsic + stock-LLVM approach is locked
  for v1.
- **Phase 9 regression harness green.** The integration suite is the
  freeze gate's pass/fail signal.

**Done when:** all deliverables ship, the regression harness is green,
and the frontend / backend / quantum-classical-handling /
llvm-implementation documents carry a "v1.0 frozen" marker. Backend
implementation (real gate-sequence template bodies, simulator runtime,
optimization passes) is sequenced under a post-freeze roadmap revision.

---

## Beyond the freeze (out of scope for this roadmap)

Sketched here only as pointers; phasing for these is the subject of the
post-Phase-10 roadmap revision.

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
- **Quantum-conditioned `while` loops.** Surface + semantics (amplitude
  amplification, transform-to-bounded-for, bounded-iteration, etc.)
  designed at PRD time. Punted past the freeze to keep v1.0 narrow.
  **Carries a Phase 5 obligation:** this phase must **extend** Phase 5's
  per-op uncomputation (the `emit_inverse` + last-use machinery) to loop
  semantics — loop-carried tainted registers and per-iteration
  compute/uncompute. Phase 5 assumes an acyclic CFG and diagnoses
  backedge-crossing tainted live ranges; lifting that guard into correct
  loop uncomputation is part of this phase, not a rewrite of Phase 5 (see
  [`docs/prd/phase-05-uncomputation/PRD.md`](docs/prd/phase-05-uncomputation/PRD.md)
  §2.9).
- **Dynamic circuits.** Measurement-derived loop bounds; mid-circuit
  measurement feedback. Out of scope until post-backend.
- **Cross-language input.** `rustc --emit=llvm-bc`, `flang -emit-llvm`,
  etc. participate in `clone-on-taint` once their bitcode is in the LTO
  link. The frontend-language surface for these is post-freeze polish.
- **Memory model.** `load`/`store`/`getelementptr` lowering; QRAM
  templates; pointer aliasing for quantum data. Each stock LLVM
  memory opcode needs its template the same way arith opcodes do; the
  design choices (Shadow / MUX / QROM selection) are non-trivial
  enough to warrant their own phase post-freeze.

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
- Phase 7 (manual inversion) is small and depends on Phase 5's
  `emit_inverse` helper.
- Phase 8 (runtime templates) is mostly autogenerated and can land
  alongside Phases 3–7 incrementally; the freeze in Phase 10 is the
  hard deadline.
- Phase 9 (integration harness) accumulates fixtures alongside Phases
  2–7 and concludes at the Phase 10 freeze.
- Phase 10 (freeze) is a gate; nothing else lands before it. Post-Phase-10
  work is designed under a future roadmap revision.
