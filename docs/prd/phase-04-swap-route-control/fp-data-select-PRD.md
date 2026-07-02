# PRD — Tainted fp-DATA `select` (un-staging §16.4)

> **Status:** proposed (2026-07-02). Extends Phase-4.4 (`SelectClassify` /
> `SelectMergeEmit`). Tracked under the fp-data priority ([[fp-data-priority-iw81-4]])
> and the 7.x-widenings tracker `8h7d`. **Copy mechanism: Option B** (real
> `cqrt_copy_f<W>_controlled` primitives) — owner decision 2026-07-02.
> **A Rule-13 core change** (the f64 angle/data silent-miscompile family).

## 1. Motivation

The `openlibm` source-injection census ([`INJECTION-CENSUS.md`](../../../tools/library_coverage/INJECTION-CENSUS.md))
showed off-the-shelf libm is blocked by branches + scratch memory, and that the
viable injection path is **branchless** implementations. Branchless range reduction
expresses its data-dependent choices as `select`, not `br` — and **integer `select`
lowers today while fp `select` declines**. Un-staging fp-DATA `select` is the single
change that lets branchless fp implementations lower to `cq_template_f*` routines.

## 2. Why it is safe to un-stage (the safety foundation)

`SelectClassify`'s gate ladder already fences the hazard, **type-agnostically and
before** the fp-data question:

- **GATE 3 (angle fence, `selReachesRotationArg1`)** runs *before* GATE 4
  (`SelectClassify.cpp:282`). Any fp value that reaches a rotation's arg-1 slot —
  through value-preserving carriers (`fpext`/`fptrunc`/`bitcast`/`freeze`/nested
  `select`/`phi`) — declines `rotation angle`. So **an fp `select` that reaches GATE 4
  is already proven not to be an angle.** This is the entire f64-angle miscompile
  family, handled upstream.
- **GATE 5 (coherence, `operandCarriesPhase` + `hasCoherentDownstreamUse`)** walks
  lineage/uses, not types. An fp operand whose lineage includes an `Rz` (`cq_phi`), or
  that feeds a downstream rotation, still declines. A `cq_theta`-derived fp value
  (real-amplitude basis superposition of fp bit-patterns) is the canonical accept, and
  the controlled-XOR (CNOT) copy of its **bit pattern** is a faithful *basis* copy
  (bits are bits; handles are `i32`, Rule 15).
- **GATE 6 (alias)** — type-agnostic.

The emitter (`SelectMergeEmit`) is already width-parametric (`abiWidthFromType` →
`allocFn`/`copyControlledFn`/`freeFn`); `cqrt_alloc_f{16,32,64,80}` + `cqrt_free`
already exist. The **only** missing runtime piece is the controlled fp copy.

## 3. Scope — NARROW to `select` only

This un-stages fp-DATA **for `select` alone**. The identical "fp under tainted control
= categorically an angle" belief is baked into other sites; they **keep declining fp**
until they too carry an angle-fence proof:

- `SwitchClassify` GATE 4, `ArmClassify` (br-diamond value arms), `IOSinkLowering`,
  `AbortParkEmit`, `QramLowering` — **unchanged**; fp still declines there.
- `widthHasReversibleCopy` (integer-only, 8 consumers) — **NOT touched.** The select
  path gets a separate fp-aware check.

Non-goals this increment: fp **value-arm** (br-diamond method-B) `select`-free merges;
fp `switch`; fp vectors; the uncontrolled `cqrt_copy_f<W>` (no consumer yet — adding it
would be dead ABI, which the codebase forbids).

## 4. Changes

### 4.1 Runtime — Option B frozen ABI (`runtime/cq_runtime.{h,c}`)
Add **`void cqrt_copy_f<W>_controlled(i32 ctrl, i32 src, i32 dst)`** for
`W ∈ {f16, f32, f64, f80}` (controlled only — the select merge's sole consumer;
uncontrolled/`_inv` deferred to the fp value-arm increment to avoid dead ABI).
Trace-only bodies identical in shape to `cqrt_copy_i<W>_controlled` — all three args
are `i32` handles; the fp width tags the symbol name only (Rule 15). Replace the
header's "NO cqrt_copy_f16 … an fp merge phi is categorically an angle" note with the
new rationale (angle-fenced by GATE 3, so fp-DATA is legitimate for `select`).
**Freeze:** these are new frozen symbols — see §7.

### 4.2 Symbol minter (`ir-pass/src/ControlledSymbols.cpp` — `copyControlledFn`)
Extend to mint `cqrt_copy_f<W>_controlled` for fp widths. Remove the fp→null fence for
the fp widths that now have a copy; keep null for f128 / unknown / i128 (no primitive).
The minter is mechanical — the **classifier** decides which paths accept fp, so minting
an available symbol is safe (Switch's own GATE 4 still blocks fp from reaching here via
`SwitchDataMuxEmit`).

### 4.3 New predicate (`ir-pass/src/OpcodeSupport.{h,cpp}`)
Add **`bool abiWidthHasControlledFpCopy(StringRef)`** (or extend a select-local check)
returning true for `{f16,f32,f64,f80}`. Used **only** in SelectClassify GATE 4 and (for
the null-check) SelectMergeEmit. `widthHasReversibleCopy` stays `intBits ∈ [1,64]`,
untouched — its other 8 consumers must not change.

### 4.4 Classifier (`SelectClassify.cpp` GATE 4, lines 285–298)
Relax the fp decline: accept a **scalar** fp result (`isFloatingPointTy`, **not**
`isFPOrFPVectorTy` — fp vectors still decline) that has a controlled fp copy. Preserve
the gate ORDER (GATE 3 before GATE 4 — the load-bearing invariant). Continue to decline:
fp vector, f128, pointer/aggregate, and integer i128 (via the existing check). GATE 5/6
unchanged (they already handle fp lineage).

### 4.5 Emitter (`SelectMergeEmit.cpp`)
No structural change — the six-step controlled-XOR merge is width-parametric. Verify
`copyControlledFn(Abi)` / `allocFn(Abi)` / `freeFn()` resolve for fp Abi (alloc/free
already do). The rail alloc `Constant::getNullValue(RailTy)` yields `double 0.0` etc.

## 5. Decline matrix (red-green — every one ships a negative fixture)

Must STILL decline (character-for-character diagnostic mirror):
1. fp value → rotation arg-1 (angle), incl. through `fpext`/`bitcast`/`freeze`/nested
   select — GATE 3 `rotation angle`.
2. fp operand carrying an `Rz` (`cq_phi` lineage) — GATE 5 `control flow`.
3. fp operand feeding a downstream rotation (arg-0 wire) — GATE 5 `control flow`.
4. fp **vector** select (`<2 x double>`) — GATE 4 `control flow`.
5. `fp128` / unknown width — GATE 4 `control flow` (no copy primitive).
6. aliasing fp operands (two `cq_phi` of one base) — GATE 6 `control flow`.
7. Q+Q select condition — GATE 2b `control flow`.
8. fp-data select reached via **switch / br-diamond / IOSink / abort / qram** — those
   paths STILL decline (scope guard; separate fixtures asserting no scope leak).

Positive: `(q > 0.5) ? <theta-derived fp> : x` → lowers to
`cqrt_alloc_f64 / cqrt_copy_f64_controlled ×2 (¬flag cqrt_x-bracketed) / icmp_inv strip /
cqrt_free`, with the §16.3 bracket-order (X encloses only the second copy) pinned by an
ordered FileCheck; angle fence intact.

## 6. Rule-13 clearance plan (a green suite does NOT clear this)

Independent adversarial review (analytic/trace reasoning; no simulation — owner
2026-06-10) on:
- **Angle-fence completeness** — every fp→arg-1 path (all carriers, fan-out: fp used as
  data AND angle at once must decline the whole select, never split).
- **Coherence for fp** — theta-basis accept vs `cq_phi`-phase decline; confirm the
  bit-pattern CNOT copy is basis-faithful for a `theta`-derived fp superposition and
  cannot dephase.
- **Scope containment** — fp does not leak into Switch/Arm/IOSink/AbortPark/Qram via the
  extended `copyControlledFn`.
- **f80 edge** — 80-bit rail alloc/copy/free trace-consistency.
Adversarial probe family per Rule 10 (not just the positive suite).

## 7. Freeze impact (owner-approved via Option B)

Adds `cqrt_copy_f<W>_controlled` (4 symbols) to the **frozen** runtime ABI. This
**revises the ROADMAP invariant** that "the control/loop work (7.2–7.4) adds no frozen
symbols" — fp-DATA select does add frozen symbols. Update `ROADMAP.md` / `CLAUDE.md`
accordingly. Option A (bitcast→`cqrt_copy_i<W>`, zero frozen symbols, no f80) was the
alternative; owner chose B for a clean fp rail and f80 coverage.

## 8. Done-criteria (Rule 12 / 16)

- `ir-pass/test` lit fixtures: the positive ordered-CHECK + the §5 negative matrix
  (each `RUN: not … | FileCheck` mirroring the diagnostic).
- ≥1 e2e golden smoke (a branchless fp `select` slice through the full pipeline).
- Runtime archive rebuilds; trace golden-diff clean for the new symbols.
- Rule-13 clearance recorded (§6) before commit.
