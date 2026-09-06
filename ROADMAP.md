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
   > ⚠ **PRINCIPLE 7's MECHANISM IS RETIRED, dated 2026-09-06** (bd
   > `test_C_libtooling-3qlq`, Increments 1 + 2, both landed on `main`). Tainted
   > control flow is **no longer** lowered by routing data through `cqrt_cswap`:
   > a PHASE arm is a KICKBACK onto the condition flag and a VALUE arm is a
   > CONTROLLED-COPY MERGE (`cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail),
   > with `cqrt_cswap` minted by the 7.2 `AbortParkEmit` alone and the emitter
   > replaying nothing — the chain is reversed by the ordinary Phase-5 whole-DAG
   > `_unc` spine. **What survives is the half of the principle that was load-
   > bearing**: arm bodies still run **verbatim and uncontrolled** (the pass still
   > needs no `_controlled` twin per gate — the one controlled gate it emits is a
   > basis COPY, not a controlled arm gate), and adjoints are still DERIVED, never
   > hand-authored. See Phase 4's status banner.

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

## Phase 4 — RSSA swap-routed tainted control flow [4.0–4.5 DONE; **the route is FULLY RETIRED** — phase arms 2026-09-05, value arms 2026-09-06, both LANDED on `main` 2026-09-06]

> ⚠ **STATUS, 2026-09-05; LANDED on `main` 2026-09-06 — READ THIS BEFORE THE
> INCREMENT LIST BELOW (bd
> `test_C_libtooling-3qlq`, "retire the swap route").** Everything in this Phase-4
> block about how a **phase arm** is lowered describes a generation that has been
> **retired**, and it is kept as history because its arguments are still quoted.
>
> **What changed and why.** `cqrt_rz_<W>` is **TENSORED** — an Rz on each of the W
> qubits — so a routed or controlled W-bit Rz puts phase `(−1)^popcount(target)` on
> the marked branch and, being diagonal per qubit, **can never mark `|0…0⟩` at
> all**. Every shipped Grover golden was therefore the identity on `q`. Nothing
> caught it and nothing could: a golden byte-diff proves every symbol resolves, not
> that the unitary is right (Rule 2), and there is no simulator. See
> `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §1.
>
> **Increments 0 and 1 are LANDED on `main` 2026-09-06 as ONE squash commit** (hash
> filled by the orchestrator: the squash of branch `3qlq-inc1-fix-c1`, whose tip is
> recorded in the landing commit message; `git log main -1` shows the hash) **after
> the re-clearance verdict `CLEAR-WITH-OWNER-QUESTIONS`** (record:
> `docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/clearance2.md`).
> ⚠ **HISTORY, DATED — kept because the arguments are still quoted.** Increment 1
> was first merged to branch `3qlq-inc1` (`be4e2ea`, 2026-09-05) and held OFF `main`:
> the independent Rule-13 clearance of 2026-09-05 returned **BLOCK** on
> finding **C-1** — a mixed loop (D4's per-bit condition on a loop-INVARIANT
> register PLUS a second loop-CARRIED register) leaked its `and` rails per
> activation, 3 mints / **0** `_unc` against 3/3 hand-unrolled and 3/3 on the
> pre-3qlq oracle, at `opt` exit 0, verify-clean and STRICT stage 2b `0
> violation(s)`; that record is
> `inc1-records/session-0a61aa31/clearance.md`. **2026-09-06: C-1 was FIXED on branch
> `3qlq-inc1-fix-c1`** — `LoopLowering`'s `Collapsed` branch now ALSO collects the
> loop-invariant root mints beside the carried roots (a separate set unioned only on
> success, with a `CarriedRoots` skip so the collapse's own rail is not judged), on
> clause (ii)'s UNCHANGED (I1) proof; witnessed by
> `e2e-phase-perbit-loop-mixed-twin-identical` (rolled == hand-unrolled, 37 = 37) and
> pinned in lit by `control_phase_kickback_mixed_invariant_carried_inloop.ll`.
> **⚠ THE INDEPENDENT LENS ON THAT FIX THEN FOUND TWO MORE CONFIRMED MISCOMPILES OF
> THE SAME CLASS IN ITS OWN NEIGHBOURHOOD, both fixed in a SECOND round on the same
> branch (2026-09-06, findings F-C1-1 / F-C1-2 — `RETIRE_SWAP_ROUTE_INC1_NOTES.md`
> §3.10):** one added line, `q = q + 7;` in the loop's PREHEADER, restored the leak
> verbatim on 542d588 AND on the round-1 fix (3 mints / **0** `_unc` against 3/3
> hand-unrolled; PRE-EXISTING and F-L5-1-era, since the same program with no carried
> register leaks identically) — fixed by asking the ONE owner of the in-place
> decision, `ArithLowering::classifyInPlaceReassignment`, and COMMITTING to its
> answer via `taint.InPlaceRailOps`; and the same mixed loop with an ONWARD
> (round-2) in-loop region leaked for two further reasons — the "already claimed"
> fact was a caller LOCAL while the collapse happens in the ROUND-1 call, and the
> round-2 delta was keyed on block MEMBERSHIP while a round-2 region flattens into
> the very `Pred` a round-1 region already used — fixed by `taint.ClaimedRailRoots`
> (written at both collapse sites) and by making `taint.InLoopFlattenedPreds` a
> per-block COUNT. Witnessed by `e2e-phase-perbit-loop-mixed-preadd-twin-identical`
> (38 = 38, was 32 vs 38) and `e2e-phase-onward-perbit-loop-mixed-twin-identical`
> (47 = 47, was 41 vs 47).
> **⚠⚠ AND THE LENS ON *THAT* ROUND FOUND THAT THE SECOND FIX HAD INTRODUCED A
> CONFIRMED SILENT MISCOMPILE OF ITS OWN, fixed in a THIRD, NARROWING-ONLY round on
> the same branch (2026-09-06, findings F-C1B-1 / F-C1C-1 / F-C1B-2 —
> `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.11):** the round-2 commit asks
> `classifyInPlaceReassignment` at ROUND 1 and `lowerOps` honours the marking without
> re-asking, so an immediate that becomes TAINTED at round 2 was emitted as
> `cqrt_addc_i32(%h4, %h_op)` — a quantum rail handle in the ABI's classical-immediate
> slot (the commuted spelling mutates the WRONG rail); and its `hasOneUse` stability
> conjunct is true of the SSA VALUE but false of the WIRE, because `lowerRotations`
> RAUWs a whole theta chain onto ONE handle. Fixed by a MONOTONE `isa<Constant>(Imm)`
> fence at the commit plus a LOUD re-verification of the same fence at `lowerOps`
> (`cq loop lowering: pre-loop in-place op no longer provable at lowering`), and by
> narrowing `taint.ClaimedRailRoots` to `(root, the CLAIMING loop's header)`. Over the
> whole 262-program reproducer corpus the round-2 binary and this one differ on **6
> programs in the F-C1B-1 / (1a) / F-C1C-1 scope, plus `w3` by design (the F-C1B-2
> revert)** — the round's own "6 and no others" was a bound taken over a corpus that
> did not yet contain its seventh mover, corrected by the round-3 lens (F-C1C-E); its
> independent re-run over **299** programs gives **286 unchanged / 13 moved**, one of
> them a harness artefact of its own probe and the other 12 all in the REFUSE
> direction, with **0 programs going decline → accept and no decline string changed**.
> `e2e-loop-twin-matrix` **Passed, 181.66 s** with no cell moved.
> **⚠⚠⚠ AND A FOURTH ROUND (2026-09-06, bd `7yd0` — notes §3.14) RETIRED THE
> `hasOneUse` STABILITY CONJUNCT ITSELF**, on a leak the Rule-13 round on
> **Increment 2** found in the ALREADY-LANDED `main` a3c1513 (`review_inc2_r2`
> **F-I2-1**; the same conjunct the re-clearance had filed as OQ-C2-1). A Phase-4
> MERGE OUT-RAIL structurally cannot satisfy `P->hasOneUse()` — the emitters WRITE
> `%out` before anything reads it — so the commit refused, the peel stopped at the
> `add`, clause (ii-b) never saw the root, and D4's per-bit loop leaked **4 mints /
> 0 `_unc` rolled (44 lines) against a hand-unrolled twin at 4/4 (52)**, 32 / 0 at
> K=32, from thirteen lines of plain C with no Inc-2 feature in them. The conjunct
> guarded NOTHING M-C's own G6/G7 pair does not (measured with programs: a prior void
> `cqrt_*` writer is settled by `priorUseIsSettled` arm (c), a later `cq_measure` is
> refused by G6, a still-unlowered tainted opcode by arm (e)), and the temporal net is
> round 3's (1b) tripwire — **deleting (1b) makes all nine F-C1C-1-class programs
> miscompile again, which is the measurement that makes the safety claim a fact**.
> Witnessed by `e2e-phase-perbit-loop-merge-preadd-twin-identical` (52 = 52), TWO lit
> accepts and twin-matrix sub-grid **F4** (2 cells, TRACE-DIVERGENCE on `main` →
> ACCEPT-IDENTICAL; 286 → **288**). ⚠ **The population is NOT "merge out-rails"**:
> the whole-corpus sweep (**485 programs, 477 unchanged / 8 moved, 0 class flips in
> either direction, 0 decline strings changed**) moved a program with no merge in it
> at all — `if (q>5) cq_phi(.4); q = q + 7;` then D4's loop, where `P`'s other use is
> the PRECEDING REGION's compare, already `_unc`'d and freed by the commit's program
> point (3/0 vs 3/3 on `main`, 3/3 = 3/3 byte-identical here). It is **every `P`
> whose other users are all SETTLED PRIOR CONSUMERS**, of which a merge's
> `cqrt_copy_*` writers and a region's discharged compare rail are two spellings. ⚠ It also CORRECTS OQ-C2-1's attribution: `m11d`
> is **not** bought back — its candidate is refused by the M-C fence itself, so its
> trace is byte-unchanged. **STATUS: **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash)**, after a rebase onto 258d974 that turned the
> round's one ANALYTIC row into a measured one — Inc 2's controlled-copy VALUE merge
> is a FOURTH producer of the same `%out` rail, and `q4b_preadd` there is 4/0 at 52
> lines vs its twin's 4/4 at 60 on `main` and **60 = 60 byte-identical** on the
> rebased binary (`control_phase_kickback_mixed_value_merge_preadd_inloop.ll`,
> `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`). That makes it
> **eight instances of one defect class over six adversarial rounds on one
> function** — two of them INTRODUCED BY A FIX and the eighth found AFTER LANDING by
> a round reviewing a different increment — **plus one PRE-EXISTING member of
> the same class found in passing by the round-3 lens** (F-C1C-B, bd
> `test_C_libtooling-eqpx`, notes §3.12: the same defect through the LOOP writers for
> the `xor` stem, reproducing on the pre-3qlq oracle 52d7764, so NOT this epic's and
> NOT a blocker for it). ⭐ **That last one is FIXED (2026-09-06, notes §3.16 / PRD §0
> E13)**: a DECLINE-ONLY consumer tripwire — `lowerOps` Phase 1 re-asks G2 alone
> (`inPlaceValueRailOperand`) under FINAL taint for every `taint.InPlaceRailOps`
> member W4 did not commit, declining `cq loop lowering: in-place rail op no longer
> provable at lowering`. The investigation first grew the class three ways: FOUR
> writers not three (`emitBreakForward` was unlisted and is a member), the `add` stem
> reachable (correct until then only by `-O1`'s exit-value rewrite), and the BARE
> `%out` reaching it one pipeline stage earlier than `repropagateControlMerges`. 16
> lit fixtures, 0 new goldens, 0 golden churn, no new frozen symbol. The round-1
> adversarial lens on that fix returned **`CLEAR-WITH-ITEMS`** (2026-09-06): no
> over-accept, no introduced miscompile, 0 over-declines over 20 boundary programs
> and 0 rail producers over all 841 `fix` accepts, with **15 MORE measured members**
> of the class — two of which change its description, since **at i8/i16 the defect
> was a BROKEN MODULE and a hard abort, never verify-clean**, and the commuted `add`
> IS plain-C reachable in its wrong-immediate face. Its three DOC/FIXTURE items are
> closed (`eqpx_reproducers_r1/`, notes §3.16). **One lens is not a clearance.**
> **STATUS: LANDED.** Three C-1 rounds ran on branch `3qlq-inc1-fix-c1` — round 1
> the CAPABILITY, round 2 two more members of the class plus a confirmed miscompile
> of its own, round 3 the NARROWING — the round-3 lens graded **CLEAR-WITH-ITEMS**
> (both DOC findings applied), and the **RE-CLEARANCE on that tree returned
> `CLEAR-WITH-OWNER-QUESTIONS`** (2026-09-06,
> `docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/clearance2.md`):
> the BLOCK is CLOSED and **Increments 0 + 1 LANDED on `main` 2026-09-06 as ONE
> squash commit** (hash filled by the orchestrator: the squash of
> `3qlq-inc1-fix-c1`, whose tip is recorded in the landing commit message; `git log
> main -1` shows the hash). What the verdict leaves open is four owner questions and
> one record item — all DISCLOSED leak / over-decline classes that PRE-DATE the
> branch and none of them a wrong unitary this tree introduced (PRD §0 **E10**).
> `cq_phi` is
> **register-free** —
> `void cq_phi(double θ)` = "multiply the CURRENT BRANCH's amplitude by `e^{iθ}`"
> — and under a tainted condition it lowers by **KICKBACK**: the ordinary compare
> mint, `cqrt_rz_i1(f, θ)` **UNCONTROLLED** on the flag, the ordinary `_unc` strip
> (which returns `f` to `|0⟩` on every branch), `cqrt_free(f)`; a `¬flag` arm keeps
> its `cqrt_x` bracket. **Uncontrolled or classically-controlled `cq_phi` is a
> GLOBAL phase and is DELETED** — a documented semantic, not a diagnostic (owner
> decision D2). This is the lowering at EVERY phase site: the flat diamond and
> `if/else`, the folded angle select, the compound condition tree, the depth-2
> NEST and the `switch`. `ir-pass/src/NestedRouteEmit.cpp` and
> `RotationLowering::emitRz` are **DELETED**.
>
> **VALUE arms do NOT route any more either — Increment 2 is LANDED on `main`
> 2026-09-06 as ONE squash commit** (the squash of branch `3qlq-inc2`, tip recorded
> in the landing commit message; `git log main -1`) **after the clearance verdict
> `CLEAR-WITH-OWNER-QUESTIONS`** (record
> `docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/inc2/clearance_inc2.md`).
> **THE SWAP ROUTE IS THEREFORE FULLY RETIRED: `cqrt_cswap` has exactly ONE minter,
> the 7.2 `AbortParkEmit`** — MEASURED, `grep -rn 'emitRoute(' ir-pass/src
> ir-pass/include` = the definition, the declaration and ONE call site
> (`AbortParkEmit.cpp:396`), and `grep -l 'cqrt_cswap' tests/e2e/*.expected.log`
> returns **1** golden (`slice_control_abort`) of 319.
> A **value arm** is now the **CONTROLLED-COPY MERGE** (PRD §7): `emitValueRegion`
> HOISTS the arm's pure chain into the pred so it runs unconditionally on the
> ORIGINAL register, builds a `select`, and hands the region to the Rule-13-cleared
> 4.4 `SelectMergeEmit` — flag mint → `|0⟩` out-rail → two X-bracketed
> `cqrt_copy_<W>_controlled` → the chain's `_unc` by the ordinary whole-DAG spine →
> compare `_unc` strip → ONE `cqrt_free`. No work rail, no route, no reverse-play in
> the emitter. The V3 `switch` half is the data-mux's own preload + XOR-delta shape
> over a non-constant base. **What it LEAVES:** the chain-final rail `R(p)` (and each
> switch delta `d_i`) is left **ALLOCATED and ENTANGLED** — a leak, never a dirty
> free (PRD §0 **E1**), and the reason follow-on bd `3qlq.5` (freeing the value-arm
> SOURCE) is **unsound by default**. Witness: BYTE IDENTITY with the manually
> pre-hoisted `select` twin on four `cmp` gates
> (`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`), i.e. against the
> PRE-Inc-2 compiler's own stream for the twin spelling, not against itself.
> ⚠ **So every value-arm sentence BELOW that describes a route is HISTORY, dated
> 2026-09-06.** It is kept, not deleted, because its arguments are still quoted.
> Round 2's one LEAK finding (F-I2-1) is **PRE-EXISTING on `main`**, is not Inc 2's,
> and is filed out of the epic as bd `test_C_libtooling-7yd0` (C-1 round 4; PRD §0
> **E11**) — which then REBASED onto this landing and **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash). On the rebased binary the
> Inc-2 spelling of that leak is gone: `q4b_preadd` rolled == unrolled BYTE-IDENTICAL
> at 60 lines, against 4 mints / 0 `_unc` at 52 on `main` 258d974.
>
> **Do not quote these as phase-arm invariants any more:** "zero controlled
> gates", "`Rz|0⟩ = |0⟩`, so the inactive work rail is clean and freed as a no-op
> reset", and "the nest and the switch keep the route". The first two are TRUE
> statements that are also *exactly* why a per-qubit Rz is not an oracle; the
> third is now false. The standing lesson is a RETIREMENT: a W-bit "rotation" ABI
> needs its multi-qubit semantics pinned BEFORE a control emitter is built on it.
>
> **Two adversarial rounds found three CONFIRMED silent miscompiles in Increment 1
> itself**, all `opt` exit 0, verify-clean and STRICT-stage-2b clean: the uncompute
> spine adjointing the kickback gate and cancelling the user's phase exactly; the
> D2 deletion running BEFORE the second round of control detection, so a branch
> phase under an onward tainted branch was deleted and its orphaned angle then
> lowered as quantum fp DATA; and a stale-header retired `@cq_phi_<sfx>` call that
> was neither lowered nor declined (Rule 1's "no third path"). `CLAUDE.md`'s
> CORRECTNESS-RISK section carries the record and the two standing lessons;
> `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1/§2 carry the reproducers. ⚠ **That count is
> the ROUND-1 three and is not the total**: round 2 added a fourth of the same
> family (the once-running rail-collapse stage whose premise the second round
> falsifies, PRD errata E9), and the CLEARANCE then added a fifth, **C-1** above —
> so **five confirmed silent miscompiles across three adversarial passes over ONE
> increment**, every one `opt` exit 0, verify-clean and STRICT-stage-2b clean, and
> **zero** of them found by the fixture suite. ⚠ **"FIVE" IS THE PRE-FIX-ROUND
> FIGURE and it moved again**: the two lenses on the three C-1 rounds added FOUR
> more confirmed members of the in-loop entangled-rail class — F-C1-1 and F-C1-2
> found in round 1's neighbourhood, and F-C1B-1 / F-C1C-1 **INTRODUCED BY round 2's
> own fix** — which is what makes the standing count *seven instances of one defect
> class over five adversarial rounds on one function, two of them introduced by a
> fix, plus one PRE-EXISTING member found in passing (bd `test_C_libtooling-eqpx`)*.
> PRD §0 **E10** is the five-line summary. Budget a further round on any
> successor increment; that is the number to quote when scoping one.

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

> ⚠ **HISTORY, dated 2026-09-06 — the GOAL paragraph and the table below describe
> the RETIRED generation** (bd `test_C_libtooling-3qlq`, Inc 1 + Inc 2, both landed
> on `main` that day). They are kept because their arguments are still quoted and
> because the 4.x sub-items below are written against them. **What actually ships:**
> a tainted `br`/`select`/`switch` whose arms are PHASES lowers by **KICKBACK**
> (mint the flag, `cqrt_rz_i1(f, θ)` UNCONTROLLED on it, strip, free — no gate on
> the data register at all), and one whose arms are VALUES lowers by the
> **CONTROLLED-COPY MERGE** (hoist the pure chain, mint the flag, two X-bracketed
> `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, `_unc` the chain, strip,
> free). **`cqrt_cswap` is minted by the 7.2 `AbortParkEmit` alone.** What SURVIVES
> from the paragraph above is the PRINCIPLE, not the primitive: split and join share
> one live condition, and the join must be the split's undo.

| construct | lowering (⚠ RETIRED 2026-09-06 — see the banner above) |
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
  > the route's four). ~~The **4.3 depth-2 nest and the 4.5 switch keep the route**, so
  > the recipe below is still literally what they emit.~~ ⚠ **THAT CLAUSE IS FALSE
  > SINCE 3qlq Inc 1 (2026-09-05, landed 2026-09-06) — corrected here 2026-09-06 by
  > the Inc-2 landing pass.** The nest and the switch do **not** keep the route:
  > `NestedRouteEmit.cpp` is DELETED, `SwitchRouteEmit`'s phase path mints a
  > kickback gate on the eq-flag, and **the recipe below is emitted NOWHERE**. Nor
  > is the Inc-2a controlled gate this banner announces still emitted — since Inc 1
  > `cqrt_rz_<W>_controlled` is DECLARED-BUT-UNEMITTED and every phase arm is the
  > kickback. Read the whole banner as the middle generation of three.
  > The two forms are the SAME
  > unitary — with `w = |0⟩`, `cswap(f,q,w)·Rz_w(θ)·cswap(f,q,w)` **equals**
  > `cRz(f,q,θ)` with no global-phase residue — which is why the route remains the
  > correctness ORACLE for the peephole. See
  > `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2A_NOTES.md` and
  > `control-in-place-PRD.md` §12.2.
- **4.2 — Classical-permutation / value arms (method-B) [DONE 2026-06-11,
  branch `swap-route-control`, WI-1..WI-7 — `docs/prd/phase-04-swap-route-control/PRD.md`
  Part II + `IMPLEMENTATION-4.2.md`].**
  > ⚠ **SUPERSEDED 2026-09-06 by bd `test_C_libtooling-3qlq` Increment 2, LANDED
  > on `main` that day — the ROUTE and the emitter's reverse-play are GONE; the
  > `cqrt_copy_<W>` ABI this item added is NOT** (it is joined by the 4.4
  > `_controlled` twins, which are now the merge primitive). A value arm is the
  > CONTROLLED-COPY MERGE: hoist the pure chain into the pred, mint the flag, two
  > X-bracketed `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, the chain's
  > `_unc` by the whole-DAG spine, strip, one free — no work rail, no `cqrt_cswap`,
  > no `R†` replay in the emitter, and the chain-final rail left ALLOCATED and
  > ENTANGLED (PRD §0 E1). The **§3c clobber reject below is UNCHANGED and still
  > active.** Read the rest of this item as the design and the arguments of the
  > retired generation; PRD `retire-swap-route-PRD.md` §7 is the current one.

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
  cswaps, `q` never freed, RAUW merge→`q`. ⚠ **(A) IS SUPERSEDED, dated
  2026-09-05/06** (3qlq Inc 1, landed): the phase path mints a **KICKBACK** gate on
  the eq-flag — `cqrt_rz_i1(f_i, θ_i)` UNCONTROLLED — with no rail, no route and no
  gate on the scrutinee at all; the eq-flag mint, the `icmp_inv` strip and the flag
  free are unchanged. The G0–G11 ladder and the §5 const-fold re-anchor are
  unchanged. **(B) homogeneous value**
  (`SwitchValueEmit`) — N-way method-B over the **shared routed base** `p` = the
  merge default-edge incoming (`p != q`, the C2 anchor; routing `q` would clobber
  the eq-flags): route-in → verbatim chain replay → route-back → **one**
  `cqrt_copy_<W>(p,out)` → LIFO reverse-play `R†` (body chain only — the §8.5
  cswap-arg0 seam: route cswaps are bracketed by `emitRoute`, never fed to
  `emitInverseChain`). ⚠ **(B) IS SUPERSEDED, dated 2026-09-06** (3qlq Inc 2,
  landed): the value `switch` is now shape **(C)'s own preload + XOR-delta** over a
  NON-constant base — `cqrt_copy_<W>(p, out)` preloaded once at the top, then per
  case a hoisted chain `R_i(p)`, a Q+Q `xor` delta `d_i = R_i(p) ^ p`, an eq-flag
  mint and one `cqrt_copy_<W>_controlled(f_i, d_i, out)`, with each chain
  uncomputed after. **No route, no reverse-play in the emitter, no conjunction
  flag, and the §8.5 cswap-arg0 seam has no subject here any more**; each `d_i` and
  each chain final is left ALLOCATED and ENTANGLED (PRD §0 E1). The base anchor
  `p != q` and every G0–G11 decline below are UNCHANGED. **(C) all-`ConstantInt` data-mux** (`SwitchDataMuxEmit`) —
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
  `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate (*declared, unemitted since 3qlq
  Inc 1 — `retire-swap-route-PRD.md` §5: the phase arm becomes the register-free
  kickback `cqrt_rz_i1(f, θ)` on the flag, because a TENSORED per-qubit Rz is not
  an oracle; PRD §1*). The 4.3 depth-2 nest and the 4.5
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
  **Inc 3 (2026-09-04) puts the `R_y` arm INSIDE the 8h7d.5 rolled loop**, so
  Grover written as `for (i…) { oracle; controlled-Ry on an ancilla; reflection; }`
  compiles ROLLED (IR size independent of the trip count — measured 74 lowered-IR
  lines at K=3 and at K=1000). Three pieces: R7's loop half became clauses (b)/(b′)
  (the rotated base's rail must cross the back edge through a header φ the round-2
  collapse will CLAIM, asked by calling `collapseRailPhisIn` step (1)'s own body);
  R6's position predicates became a PER-ACTIVATION certificate for in-loop regions
  only (the flat path keeps its two spellings byte-for-byte); and the emitter's
  RAUW target for the Ry stem became the HOISTED GATE rather than the base (M-β),
  which makes the gate a chain member so every `LoopLowering` predicate reads the
  truth with no exemption. **The same increment moved a FLAT fence** — `ArmClassify`'s
  final P1 clause was phase-arm-only and declined `if (q==5) r=Ry(r,.9); q=Ry(q,.3);`
  with no loop in it; it now admits `SawRotationArm`, without which the flagship
  customer does not compile rolled OR flat. Witness: byte-identity with the
  hand-unrolled twin on six e2e pairs, 0 of 1430 pre-existing lit fixtures and 0 of
  267 pre-existing e2e slices moved, 0 goldens moved. **`e2e-loop-twin-matrix` was RED
  on 15 of its 273 cells at hand-back** — two PRE-EXISTING rolled-vs-flat divergence
  classes that this axis is the first to expose, both reproduced on the pre-Inc-3
  oracle with an `Rz` arm, both outside Inc 3's scope to fix. **Its round-1 Rule-13
  review made the gate GREEN without blessing the divergence**, by moving those 15
  cells out of the expected table and into a PINNED-SIGNATURE quarantine
  (`tools/loop_twin_matrix.quarantine.txt`) that fails if a signature CHANGES and
  equally if a cell STOPS diverging — bd `test_C_libtooling-1m5p` (class A,
  `Uncomputation`/`FreePoint`, ROLLED deficient) and `test_C_libtooling-a3z7`
  (class B, `ArithLowering` M-C, FLAT deficient), both awaiting an owner
  disposition. ⚠ **"15 cells" and "273 cells" are 2026-09-04 figures — re-measure.**
  bd `test_C_libtooling-3qlq` Inc 1 made the register-free `cq_phi` the matrix's
  SHIPPED surface (`--phi-surface void`), which changes what the generator emits,
  so both tables were re-measured end to end: the expected table holds **245 rows**
  and the quarantine **29 cells in THREE classes — 6 A, 21 B, and 2 C** (the new
  class C is `m_xor_range_{none,rz}`, where `-O1` drops the mask's low bit on the
  FLAT side only, so the two spellings are different PROGRAMS: a generator
  question, not a compiler defect, filed under `test_C_libtooling-3qlq` and not
  blessed). 245 + 29 = the 274 cells the gate runs. **Re-measured 2026-09-06 after
  the C-1 fix round (branch `3qlq-inc1-fix-c1`): 255 expected rows + 29 quarantined
  = 284 cells** — the quarantine is untouched at 29 in the same three classes, and
  the +10 is **sub-grid F, the second-CARRIED-register axis**: the first cells in
  the instrument to put a loop-INVARIANT condition register and a loop-CARRIED
  register in one body, which is the only shape that can see the clearance's C-1.
  Every one of the 245 earlier rows is byte-unchanged (`comm -23` over the `^m_`
  rows, empty) and all 1104 pre-existing generated sources hash identically; 9 of
  the 10 new cells would have been hard failures on 542d588 (4 sampled by hand) and
  are `ACCEPT-IDENTICAL` on the fix. **And re-measured again after the SECOND C-1
  round on the same branch: 257 expected rows + 29 quarantined = 286 cells** — the
  +2 is **sub-grid F3**, a PREHEADER in-place `add` on the invariant register at the
  diffusing and non-diffusing per-bit regions, which is the position finding F-C1-1
  lived in and which `PREFIX` (body text) structurally could not reach. Both cells
  were TRACE-DIVERGENCE on 542d588 AND on the round-1 fix and are ACCEPT-IDENTICAL
  now, measured by hand on all three binaries; all **1136** pre-existing generated
  sources hash identically (twice — once after the `preloop` slot, once after the
  cells) and the quarantine file is byte-unchanged. **The THIRD C-1 round (narrowing
  only) added NO cell and moved NONE: 257 + 29 = 286, `e2e-loop-twin-matrix`
  Passed, 181.66 s.** **And the FOURTH round added sub-grid F4 — the PRODUCT of F3's
  preheader axis with a 4.4 SELECT-MERGE out-rail root (a `PREHEAD` slot on `_wrap`
  plus one new PREFIX key `addpresel`), 2 cells, 259 + 29 = 288 cells** — **RE-MEASURED
  2026-09-06 after the round-4 rebase onto the landed Inc 2: UNCHANGED at 259 + 29 =
  288, `ctest -R e2e-loop-twin-matrix` Passed, 292.00 s, NO cell moved** —: both were
  TRACE-DIVERGENCE on `main` a3c1513 and are ACCEPT-IDENTICAL now (one of them the
  table's first `ACCEPT-IDENTICAL-WARN` row, the same warning on both spellings and
  on both binaries); all **1144** pre-existing generated sources hash identically and
  the quarantine file is byte-unchanged. `e2e-loop-twin-matrix` **Passed, 229.18 s**.
  Only the 4.4 select merge is expressible here — the Phase-4 value-arm route needs a
  multi-op arm and the 6.5 classical-call arm a second TU. The `xor` spelling of the same
  axis is DROPPED with its measurement in the code: `xor` distributes over a bit
  test, so `-O1` rewrites the FLAT side's `((a^9)>>i)&1` onto the PRE-xor register
  and the two spellings stop being the same program — the `addpost` precedent, not a
  quarantine. The old register-surface
  tables are kept byte-unchanged as `*.register.txt` — frozen history, not a live
  mode, since the register surface is unreachable from the shipped `CQ.h`. The
  second boundary control (arm ON the condition register ⇒ identical) is now
  itself an INSTANCE of class A and bounds nothing, because a branch phase writes
  nothing; `q_noregion` alone bounds the class story. The same review added 14 fixtures and one e2e pair (the O(K)
  freeze-leak reproducer, which turns PRD §13.5's "K rails at run time" from
  analytic into measured), corrected five doc-false statements, and found **no
  confirmed miscompile and no confirmed over-accept**. Notes:
  `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC3_NOTES.md`.
  **Inc 4 (2026-09-05) makes controlled STATE PREP compile** — `int r = SEED;
  if (COND(q)) r = cq_theta(SEED, θ);`, a flat DIAMOND whose arm theta has a
  CLASSICAL `ConstantInt`/`ConstantFP` arg-0. The theta MINTS a rail rather than
  rotating one, so `lowerRotations` takes its `!Chained` arm —
  `cqrt_alloc_<W>(SEED)` at the HOISTED position — and then mints
  `cqrt_ry_<W>_controlled(f, h, θ)`; the rail is then FROZEN by Inc 1's structural
  freeze. R4/R6 are SKIPPED for this class (not fed an empty set: `railWireClosure`
  inserts before its taint gate and a `ConstantInt` is module-uniqued, so R6 would
  enumerate unrelated users across the function), and M-β is a CORRECTNESS
  requirement rather than a convenience (M-α would RAUW the merge to the SEED and
  make `r` classical — measured SILENT on the `ret` and tape consumers). TWO new
  fences, not the one §7 scoped: **F1** seed identity (`state prep seed does not
  match the merge incoming`) and **F2** the equality-fold ambiguity (`state prep
  seed is proven equal to the condition register`), polarity-free because
  `clang -O1` folds an equality edge on BOTH sides — `if (q==k) r=cq_theta(q,θ)`
  and `int r=q; if (q!=k) r=cq_theta(k,θ)` compile BYTE-IDENTICAL to a genuine
  prep whose seed is `k`, so accepting the shape would turn two loud declines into
  silence. Its price is a real over-decline when `seed == k` (workaround: one
  character). An if/else prep declines `if/else state prep allocates two rails`
  (owner ruling; from plain C it is an angle select refused at S3 — follow-on
  `drbq.13`). No new frozen symbol. **The increment's headline is an OVER-DECLINE
  the design could not predict**: `int s = r * 3;` after the region declines,
  because a state-prepped register's straight-through value is a compile-time
  constant, so `-O1` SINKS the op INTO the arm and R1 refuses the two-instruction
  arm — 48 of the 297 `--stateprep` twin-matrix cells, invisible to the chained
  twin, which is why no probe saw it (PRD §14.13, an owner question). Witnesses: a
  whole-corpus lowered-IR sweep vs the pre-Inc-4 oracle (**all differing files in
  the new family, ZERO pre-existing files changed**), the `--stateprep` twin matrix
  (297 cells, **0 MISMATCH**, pre-4 and post-4 tables both committed), and BYTE
  IDENTITY with the manual CHAINED twin under a two-rewrite REDUCTION that is a
  physical identity and not the transformation under test. Notes:
  `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC4_NOTES.md`.
  **⚠ THE FIRST ADVERSARIAL ROUND ON THAT INCREMENT FOUND A CONFIRMED SILENT
  MISCOMPILE IN F2 ITSELF, AND THAT IS THE FACT TO CARRY (2026-09-05, 7 lenses).**
  F2 shipped keyed on the compare's LITERAL, and its written proof enumerated TWO
  ways a seed can be a fold of the condition register. There is a THIRD: either
  edge can pin the condition operand to a SINGLETON **by RANGE**, to a value that
  is not `k`. `int t = q & 1; int r = 1; if (t) r = cq_theta(t, θ);` — an in-place
  Ry on the CONDITION register, plain `clang -O1` C — compiled into a fresh-rail
  prep and left `t` unrotated; nine distinct spellings were in that class and the
  pre-Inc-4 binary declined every one. The algebra was right and THE ENUMERATION
  WAS THE DEFECT — the bd `8h7d.5` F-1/F-3 lesson one epic later. F2 is now
  RANGE-BASED on BOTH edges (`computeConstantRange ∩ fromKnownBits ∩
  makeExactICmpRegion(pred, k)`, predicate and inverse, decline on a singleton
  equal to the seed), the `isEquality()` gate is dropped, and **one shipped accept
  fixture flipped to a decline because it was itself an over-accept** (at `i1`
  both edges of an `i1` equality pin). The RESIDUAL is named rather than hoped
  away: F2 can only ask about registers that still EXIST, and when instcombine
  deletes the rotated register and rewrites the compare onto an ancestor nothing
  in the surviving IR can recover it — measured on five programs, one of which has
  a `@slice` body byte-identical to the flagship slice's. Every alternative source
  in that class is a data mux CQ refuses whenever the register survives, so it is
  filed as PRD §14.11 Q3. The round also SPLIT two diagnostic strings (a TAINTED
  pred incoming is `state prep merged with a quantum register`, a MIXED if/else is
  `if/else state prep beside a chained or phase arm`), retracted the "F1's third
  clause is unreachable" record (it is reachable through an UNRECOGNIZED SUFFIX and
  load-bearing — without it the pass emits a region whose gate does not exist),
  added THREE unpinned accept classes, and hit the Inc-3 fixture-integrity finding
  AGAIN: a positive COUNT inside the `NOROUTE` prefix windowed every negative, so
  an injected `_controlled_inv` after the flag's free was caught by **0 of 20**
  accepts (now 28 of 28). Corpus 1531 → **1548**, family 59 → **76**.
  **⚠ AND THE SECOND ADVERSARIAL ROUND FOUND THAT THE FIRST ROUND'S FIX HAD MADE
  THE SAME MISTAKE ONE LEVEL OUT (2026-09-05, 2 lenses) — READ THAT, NOT THE
  FEATURE.** The range rewrite widened F2's **predicate** and kept F2's **set**:
  it asked its question of `H`, the tainted operand of the compare CQ is handed,
  and `clang -O1` does not leave the pinned register there. IPSCCP proves the
  theorem about a register **X**, substitutes it into the arm, and a LATER
  InstCombine rewrites the COMPARE downward onto an **ancestor** of X — so X ends
  up a **forward user** of `H`. **Six plain-C programs accepted with X ALIVE in
  the emitted circuit, MEASURED by the source, and never rotated**
  (`5+(q&1)`, `(q&1)^7`, `(q&1)-4`, `(q&1)|8`, `((unsigned)q)>>31`, `q>>31`); the
  pre-Inc-4 binary declined all six. That is the bd `8h7d.5` F-1/F-3 lesson a
  THIRD time — *when you widen a set, ask what OTHER set is computed over the same
  closure* — and the second time inside this epic's own fence work. F2 now asks
  its singleton question of a **bounded FORWARD CLOSURE** (depth 8 / 64 values,
  the bound itself declining) over `H`'s tainted same-type integer `op constant`
  users, evaluated with `ConstantRange::binaryOp`; casts and φ/`select` are
  deliberately not followed, each for a written reason. **The round-1 RESIDUAL
  paragraph was itself the defect**: it read *"instcombine deletes the register
  AND rewrites the compare onto an ancestor"*, and those are independent events —
  the rewrite always happens (now fenced), the deletion only sometimes does. What
  is left is the deleted-register half, which is bounded because a register is
  deleted only when nothing reads it, so the difference is a leaked ancilla no
  `cq_measure`/`ret`/tape write observes — an argument that does NOT extend to the
  six, where the register IS read. The round also recorded a second, hand-IR-only
  over-accept (`ConstantRange::fromKnownBits` is a hull, so `and q,4`'s true `{4}`
  pin is missed — harmless only because IPSCCP's lattice has the same weakness and
  performs no fold either), pinned `getSwappedPredicate` for the first time
  (deleting it had reddened NOTHING), and closed the one accept of 28 that could
  not see a standing `@cq_theta` call — the accept twin of the fixture whose whole
  counterfactual is a standing `@cq_theta_si32x`. Corpus 1548 → **1557**, family
  76 → **85** (29 accept / 56 decline).

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
> Phase-4 `cqrt_rz_<W>_controlled` — *declared, unemitted since 3qlq Inc 1, PRD
> `retire-swap-route-PRD.md` §5*), added by the control-in-place epic
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

> ⚠ **THE FREEZE LIST NOW HAS A SUBTRACTION SIDE (bd `test_C_libtooling-3qlq`
> Inc 1, 2026-09-05).** The register-free `cq_phi` adds **no** symbol — owner
> decision D3 is explicitly "no new runtime ABI; the emitted set SHRINKS" — and
> `tools/opcode_table.yaml` and `runtime/` were not touched. What it changes is
> which declared symbols are still MINTED, and that is a freeze-gate decision the
> owner owes, not a fait accompli:
> * **`cqrt_rz_<W>` for W > 1** — DECLARED, **UNEMITTED**. The only Rz this pass
>   emits is the kickback `cqrt_rz_i1(f, θ)` (measured over 1661 fixture outputs:
>   35 emit an Rz, **0** at any other width; and `0` non-`i1` `cqrt_rz` across all
>   304 committed goldens — **re-measured 2026-09-06 after the Inc-2 landing: still
>   `0`, now across 319 goldens**, `grep -h 'cqrt_rz_' tests/e2e/*.expected.log |
>   grep -v 'cqrt_rz_i1(' | wc -l`, and the Inc-2 clearance's own whole-corpus
>   census over 1687 fixtures found **0** non-`i1` Rz calls in any output;
>   **re-measured again 2026-09-06 after the round-4 rebase: still `0`, now across
>   323 goldens**).
> * **`cqrt_rz_<W>_controlled` and `cqrt_rz_<W>_controlled_inv`** — DECLARED,
>   **UNEMITTED, and with no minter left in the pass** (`RotationLowering::emitRz`
>   is deleted). They were a frozen-designate family for the drbq Inc-2a
>   control-in-place peephole; that peephole's Rz half is retired. `0` occurrences
>   in the goldens.
> * **`cqrt_cswap`** — still MINTED, but by the 7.2 `AbortParkEmit` **ALONE** since
>   Increment 2 (value arms by controlled-copy merge, PRD §7) LANDED on `main`
>   2026-09-06. MEASURED: `grep -rn 'emitRoute(' ir-pass/src ir-pass/include` = the
>   definition, the declaration and ONE call site (`AbortParkEmit.cpp:396`); `grep -l
>   'cqrt_cswap' tests/e2e/*.expected.log` = **1** of 319 goldens
>   (`slice_control_abort`) — **re-measured 2026-09-06 after the round-4 rebase: still
>   1, now of 323 goldens**. So the symbol stays in the frozen surface on the
>   abort-park's account, not the control path's. ⚠ HISTORY, dated: until that day
>   the VALUE-arm path in `SwapRouteEmit` was its second minter.
> * **`cqrt_ry_<W>_controlled` ×9** — UNAFFECTED and still minted. The Ry stem is
>   untouched by this epic, and the swap route cannot carry an `Ry` at all.
>
> Freeze-gate question for the owner: **delete the unemitted Rz symbols from the
> ABI, or freeze them declared-but-unemitted?** (PRD §12 Q1 assumes "at the
> freeze, not now", which is why they are still declared today.) Deleting them is
> the honest surface; keeping them is a reserve for a future controlled-Rz
> customer that would have to pin the multi-qubit semantics FIRST — the retirement
> lesson of this whole epic.

**Deliverables.**
- **CQ.h freeze.** Semver pinned; future additions versioned per the
  freeze policy. ⚠ The surface is **no longer 14 × 3**: since 3qlq Inc 1 it is
  14 × **2** register-carrying specializations (`cq_theta`, `cq_measure`) behind
  **2** `_Generic` macros, **plus the single register-free `void cq_phi(double)`**
  (no per-type family, no `_Generic`), plus the `cq_ry` statement macro and the
  `cq_invert_*` pair — `docs/frontend.md` §3.1 carries the counted list.
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
