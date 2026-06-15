# Phase 4.4 IMPLEMENTATION — RSSA swap-routed tainted `select` (controlled-XOR copy merge)

Module layout, signatures, and the **test-driven** work-item sequence for the
4.4 increment defined by [`PRD.md`](PRD.md) **Part IV (§§15–18)**. Companion to
the PRD (which fixes *scope* and *binding decisions* — the controlled-XOR copy
merge, the use-not-type discriminator, the conservative coherent-operand
default); this file fixes *how the code is built*. Sibling of the closed 4.1
([`IMPLEMENTATION.md`](IMPLEMENTATION.md)), 4.2
([`IMPLEMENTATION-4.2.md`](IMPLEMENTATION-4.2.md)), and 4.3
([`IMPLEMENTATION-4.3.md`](IMPLEMENTATION-4.3.md)) plans and follows their
structure §-for-§.

**Every cited symbol/line was verified against the live tree (branch
`swap-route-control`, 2026-06-15) by an 8-area extraction pass.** Most PRD
citations CONFIRMED; the corrections folded in below (each over-decline-safe or a
factual fix, no shape change):
- **`cq_runtime.h:235-237`** holds the no-FP-copy invariant but its real wording
  is *"The 5 INTEGER widths only — an FP merge phi under tainted control is
  categorically an angle, never data (the f64 miscompile family), so no f32/f64
  twins exist."* — **not** the PRD's "dead ABI" paraphrase (that phrasing lives
  in `docs/backend.md:955` / PRD.md:417,1695). Cite the real wording.
- **`ChainWalk` line refs drift** (Rule 11): `isTerminalHandle` is `84-108`,
  `forwardConsumerCount` is `73-80` (**not** 131-159 — those are the fan-out +
  measure guard loops *inside* `recoverForwardChain`, 110-189); the `>1` fan-out
  bail at `:137` is correct. There is **no positive allow-list** — ChainWalk uses
  a NEGATIVE filter (`isInPlaceGateOn` 46-54 ∧ `isMeasureSink` 64-67).
- **The §16.5 no-free behaviour is already the DEFAULT** — a controlled-copy
  CallInst user of its `src` makes `isTerminalHandle(src)` return `false` with
  **zero** code change (the loop hits `return false` at `ChainWalk.cpp:105`). The
  §16.5 edit is a **single-site** addition to `forwardConsumerCount` only; never
  touch `isTerminalHandle`.
- **The controlled-copy `src` is `arg1`, not `arg0`** (the flag is prepended at
  `arg0` per the control-flag-as-arg-0 invariant, `ControlledSymbols.h:7-10`), so
  the ChainWalk recognizer gates on `getArgOperand(1)==H`, matching
  `dataInputHandle`'s "`Start=arg1 if _controlled`" convention (`ChainWalk.cpp:27`).
- **No WI-0 header promotion is needed** — every helper 4.4 reuses
  (`diagonalAliasHit`/`condProvenance`/`comparePredLowerable` in `ArmAnalysis.h`;
  `abiWidthFromType` in `OpcodeSupport.h`; `findNonDiagonalWireGate` in
  `WireWalk.h`) was **already de-anonymized by 4.3's WI-0**. The only TU-local
  predicates 4.4 re-derives are the tiny `isPhiCall`/`isThetaCall`
  name-prefix checks (deliberately not exported — they collide across TUs).

**Authoritative contracts** this plan is built against (FileCheck specs, all
**pinned from real `clang -O1` output** per PRD §16.9 / Rule 9/11): the new lit
contracts `control_swap_select_qc.ll` (§5a, accept — one quantum + one classical
operand), `control_swap_select_qq.ll` (§5b, accept — two quantum operands), and
the decline siblings (§5c), plus the **re-pinned** `control_swap_defer_select_angle.ll`
and the **graduated** `control_swap_defer_select.ll`, plus ≥1 C-sourced e2e
golden. **Symbol order IS the contract** (CHECK-pinned), with the hard
postconditions `CHECK-NOT: cqrt_cswap`, `CHECK-NOT: phi i32`,
**`CHECK-COUNT-1: @cqrt_free`** (the flag only), and — the 4.4-specific addition —
a **narrowed** `CHECK-NOT: cqrt_{rz,ry}{{.*}}_controlled` (the bare
`CHECK-NOT: _controlled` of Parts I–III **cannot** be reused: it would collide
with the intended `cqrt_copy_<W>_controlled`) and a **targeted ordered FileCheck**
pinning the ¬flag bracket scope (`copy(f,a,out)` → `cqrt_x(f)` → `copy(f,b,out)` →
`cqrt_x(f)`; §5a, §6, §8 — the 4.3 §12.3 ordered-CHECK precedent).

Fixture authoring rule (bd `swap-route-detect-known-limits`): `opt`'s `DS_Error`
handler exits on the **FIRST** diagnostic — author every swap-route fixture with
**one tainted region per file**.

**Modularity budget (≤300 LOC per new TU).** 4.4 lands its logic in **two new
≤300-LOC TUs** (`SelectClassify`, `SelectMergeEmit`) and keeps edits to the
already-bloated `SwapRouteEmit.cpp` (698 LOC) / `ControlDetect.cpp` thin. Per
PRD §16.1 a `select` is the **simplest** Phase-4 shape (single SSA instruction,
no CFG diamond, no rail, no route, no `RegionFlatten`, no reverse-play), so the
emission TU is small and the doc weight shifts to **detection** (the new
transitive arg-1 angle gate) and the **decline matrix**.

---

## WI-3 amendments (adversarial-review findings, 2026-06-16)

Two corrections folded into the implementation during the WI-3 Rule-13 clearance
(a 4-lens independent adversarial review). Both override the prose below; the prose
is retained for context but **these amendments are authoritative**:

1. **§16.5 ChainWalk exemption — REJECTED, NOT added (was a latent silent
   miscompile).** §16.5 / §6 hazard 5 / §10 / §8.5 / the WI-3 table row prescribed
   OR-ing `!isControlledCopyOut(CI,H)` into `ChainWalk::forwardConsumerCount` so a
   controlled-copy reading an upstream handle would not count toward its fan-out.
   **This is wrong and was not implemented.** The controlled copy
   `cqrt_copy_<W>_controlled(f, q, out)` IS a real fan-out consumer of `q` — `q`'s
   basis label is copied into `%out`, entangling `q`'s rail with `%out`, so `q`
   MUST stay live. With the exemption, `forwardConsumerCount(q)` drops below 2, the
   fan-out bail does NOT fire, and the uncompute spine reverse-plays `q`'s chain and
   FREES its rail — a free of a rail entangled with `%out` = a hidden measurement
   collapsing `%out` (Rule 6/8), verify-clean. The DEFAULT (counting the copy)
   correctly leaves `q`'s chain ALLOCATED (a qubits-not-scarce leak, Rule 6 —
   safe). `ChainWalk.cpp` is UNCHANGED at HEAD. Guard:
   `control_swap_select_fanout_alloc.ll`. Memory: `[[select-merge-no-chainwalk-exemption]]`.

2. **Gate 5 (§16.7 / §0 gate 5) needs a BACKWARD phase-carrier half — the
   forward-only proxy was an over-accept (a dephasing silent miscompile).**
   `hasCoherentDownstreamUse` inspects only an operand's downstream USES, never its
   PRODUCER, so an operand that IS a `cq_phi` (Rz/relative-phase) result — a
   non-basis, complex-phase superposition — was ACCEPTED and basis-CNOT-copied into
   `%out`, dephasing it (Rule 7, the 0.585→0.500 family; a downstream basis change
   then yields the wrong distribution, `opt -verify` clean). Fix:
   `SelectClassify::operandCarriesPhase` — decline `control flow` if either tainted
   operand's backward lineage contains a `cq_phi`. This is the precise
   tighten-not-widen line: a pure `cq_theta` (Ry) operand is a REAL-amplitude basis
   superposition (the canonical `(q>5)?q:x` accept survives — the walk stops at
   theta). Guard: `control_swap_reject_select_phase_operand.ll`. Memory:
   `[[select-merge-phase-operand-dephasing]]`. (Also: a NIT — a Q+Q condition
   `icmp %q,%y` now declines `control flow` at gate 2b rather than reaching the
   data-path `no template` brand: `control_swap_reject_select_qqcond.ll`.)

---

## 0. Accept criterion (the one definition everything keys on)

> **4.4 lowers a tainted-condition `select` iff ALL hold; otherwise it declines
> loudly and lowers nothing (Prime Directive):**
>
> 1. **(tainted condition)** `taint.Tainted.count(Sel->getCondition())` — the
>    same entry predicate as today's blanket decline (`ControlDetect.cpp:228`). A
>    **classical**-condition select is NOT seen here — it is
>    `declineClassicalMuxes`'s domain (§16.8) and stays declined untouched.
> 2. **(lowerable compare condition)** `Sel->getCondition()` is a `CmpInst` with
>    `comparePredLowerable(cmp) == true` (`ArmAnalysis.h:133`). A non-`CmpInst`
>    tainted `i1` or an out-of-scope `fcmp` predicate → decline (mirrors
>    `classifyArms` :610/:621).
> 3. **(NOT an angle — the §16.2 BLOCKER gate, NEW transitive forward walk)** no
>    transitive user of `%sel` through value-preserving carriers
>    (`fpext`/`fptrunc`/`bitcast`/nested `select`/`phi`) reaches a
>    `@cq_phi_*`/`@cq_theta_*` at **arg index 1**. ANY such reach → decline the
>    **whole** select (the fan-out rule — never split). **This runs FIRST among
>    the type gates** (FP-use fence before width, exactly as
>    `ArmClassify.cpp:820` precedes `:834`).
> 4. **(ABI-width integer result — §16.9 width gate)** after gate 3,
>    `Sel->getType()->isIntegerTy() && !abiWidthFromType(Sel->getType()).empty()`
>    — the non-vector scalar integer ABI widths `{i1,i8,i16,i32,i64}`. Vector /
>    `i128` / pointer / aggregate (empty `StringRef`) and **fp-data** (`f32`/`f64`,
>    staged out this increment — §16.4) → decline. **Necessary-not-sufficient,
>    runs only AFTER the FP-use fence** (the f64 trap: f64 has a valid width yet
>    is an angle).
> 5. **(conservative coherent-operand default — §16.7)** each tainted value
>    operand is **basis-valued, not coherent**: the v1 decidable proxy is *no
>    tainted value operand has a downstream quantum use beyond the select* (no
>    operand whose lineage also feeds a separate rotation `@cq_phi_*`/`@cq_theta_*`
>    or another gate). An operand with such coherent re-use → decline (the
>    channel-B dephasing case). **Cleared/widened only by independent Rule-13
>    review (§8); the shipped default is this conservative form** (§9).
> 6. **(distinct operands — §16.9 aliasing guard)** the two value operands
>    resolve to **provably-disjoint** post-lowering registers — each is a
>    `Constant`, or tainted SSA values whose diagonal-alias closures
>    (`diagonalAliasHit`, `ArmAnalysis.h:61`) do **not** intersect. The hoisted
>    in-place-arithmetic alias family → decline; the out-of-place `(q>5)?q:q+1`
>    (distinct `cq_template_add` handle) accepts.

Gates 1–2 are SSA-shape checks; **gate 3 is the load-bearing BLOCKER** (no
downstream backstop — §3.2); gates 4–6 are over-decline-safe type/coherence/alias
fences. The ladder makes the §5a/§5b accept and the full §5c decline matrix fall
out exactly. **§3c (clobber) is structurally vacuous** — a `select` writes
nothing (§16.6); there is **no** §3c decline fixture (its absence, plus a
`CHECK-NOT` on the clobber string in the operand-is-condition fixture, is the
contract).

> **The measured `-O1` accept shape** (Rule 9/11 — the existing
> `control_swap_defer_select.ll`, one quantum + one classical operand):
>
> ```
> %qc  = call i32 @cq_theta_si32(...)        ; q  (TAINTED)
> %c   = icmp sgt i32 %qc, 5                  ; tainted i1 condition
> %sel = select i1 %c, i32 %qc, i32 %x        ; true=q (quantum), false=x (classical)
> %m   = call i32 @cq_measure_si32(%sel)
> ```
> There is **no CFG** — the select is one instruction in one block. (`-O1`
> SimplifyCFG produces exactly this `select` from a side-effect-free C ternary or
> a small `if/else`; §8.4 of the PRD / §18 — the 4.2-deferred "select-folded"
> form.)

Decline dispositions (shared `diagnoseUnderControl`, `ControlPlan.h:292`;
rendered `cq controlled lowering: <What> under quantum control`). **Every string
below is pinned char-for-char to the string that ACTUALLY fires — confirmed by
running the real `-O1` IR through the post-4.4 build, not assumed** (Rule 11/12):

| Shape (real `-O1`) | Disposition | Diagnostic `What` |
|---|---|---|
| **integer data-mux, one quantum + one classical operand** — `(q>5)?q:x` (§5a) | **ACCEPT** *(was: blanket `select` decline)* | — |
| **integer data-mux, two quantum operands** — `(q>5)?q:q+1` (distinct handles, §5b) | **ACCEPT** | — |
| **angle-use select** — `%sel` (transitively) feeds a `cq_phi`/`cq_theta` **arg-1** (`control_swap_defer_select_angle.ll`, RE-PINNED) | **decline** (§3.2 gate 3, the NEW detector) | **`rotation angle`** *(re-pinned; mirrors the region-angle string `ArmClassify` already uses)* |
| **fp-data select** — `f64` result feeding `fadd`/`measure` (not an angle) | **decline** (staged out — §16.4) | `control flow` |
| **vector / `i128` / pointer / aggregate** result | **decline** (§16.9 width gate, the null-callee trap) | `control flow` |
| **coherent operand** — a tainted value operand whose lineage also feeds a downstream `cq_phi`/rotation | **decline** (§16.7 conservative default, until cleared) | `control flow` |
| **aliasing operands** — the two operands share a post-lowering register (hoisted in-place arithmetic) | **decline** (§16.9 aliasing guard) | `control flow` |
| **non-lowerable condition** — non-`CmpInst` tainted `i1`, or out-of-scope `fcmp` pred | **decline** | `control flow` |
| **classical-condition tainted-data select** — `declineClassicalMuxes` path (`lowering_reject_classical_mux_select_*.ll`) | **decline (UNCHANGED, not 4.4's)** | `cq taint escape: tainted value muxed by a classical-condition select` |
| **nested select** — a select inside a tainted-`br` region (`control_swap_reject_nested_select.ll`) | **decline (UNCHANGED)** — fires on the OUTER branch before the select scan | `control flow` (outer) |

**Why a select decline uses GENERIC `control flow`, never the §3c PERMANENT
`arm rewrites a condition operand`** (the inverted-Defect-2 lesson, armclassify
gotcha): the §3c string fires ONLY on the proven diamond identity
(`StraightThrough && Hit==Routed`, `ArmClassify.cpp:891-894`). A bare `select` has
no straight-through edge, so that proof obligation can never be met — branding a
select shape information-theoretically impossible is the over-claim §8.3 warns
against. Select declines use `control flow` (or the angle-specific `rotation
angle`).

---

## 1. Module map

**No new TU exceeds 300 LOC; no WI-0 header promotion is needed** (4.3 already
de-anonymized every reused helper — see header). 4.4 adds two small TUs that
**call** existing primitives (Rule 14), never re-implement flag mint / copy /
diagnostic.

### New translation units (`ir-pass/src/` + `ir-pass/include/`)

| Module | ~LOC (cpp / h) | Concern | Mutates IR? |
|---|---|---|---|
| **`SelectClassify`** | ~160 / ~30 | Pure analysis. The §0 prove-or-decline ladder for a tainted-condition `SelectInst`: (1) tainted-cond entry, (2) `comparePredLowerable` condition gate, (3) the **NEW transitive arg-1 angle walk** (gate 3, the BLOCKER), (4) `abiWidthFromType` width gate, (5) conservative coherent-operand check, (6) `diagonalAliasHit` aliasing guard. On ACCEPT push a `ControlRegion{Kind=SelectRegion, Merge=Sel, Condition=Sel->getCondition()}`; else `diagnoseUnderControl(Sel, <What>)`. Called from `ControlDetect`'s select scan. | **No** |
| **`SelectMergeEmit`** | ~150 / ~25 | The mutating emitter `emitSelectRegion(const ControlRegion&, WidthDispatch&, ControlledSymbols&, TaintSet&)`: the §16.3 controlled-XOR-copy stream — mint flag, `alloc` the `\|0⟩` out rail, two `cqrt_copy_<Wd>_controlled` (¬flag X-bracketed), materialize classical operands (option A), strip flag + the **single** `cqrt_free`, RAUW `%sel→%out`, `scrubTaint`, erase. **No rail/route/flatten.** Dispatched from `SwapRouteEmit::lowerControlRegions` on `Kind==SelectRegion`. | **Yes** |

### Edits to existing files (thin)

| File | Change | LOC before → after |
|---|---|---|
| `ir-pass/src/ControlDetect.cpp` | **WI-1.** Replace the blanket select decline (`226-229`: `for (Instruction &I : BB) … diagnoseUnderControl(Sel, "select")`) with a call to `classifySelectRegion(Sel, taint, plan)` (SelectClassify) — prove-or-decline, mirroring how 4.3 flipped `case RegionShape::Nested:` from unconditional decline to `recoverRegionTree`. The per-block `SelectInst` scan loop stays; only its body changes. | 214 → ~222 |
| `ir-pass/src/SwapRouteEmit.cpp` | **WI-3.** In `lowerControlRegions` (`698`), add `if (R.Kind == SelectRegion) { emitSelectRegion(R, wd, csyms, taint); continue; }` **before** the Depth/child branch dispatch. **Plus** confirm the cross-region pre-flight (`711-752`, keys on `Pred/Arm/ArmFalse/MergeBB`) safely **skips** a SelectRegion whose block fields are all null (the `if (!Doomed) continue;` guard at `:732` must not deref null) — a SelectRegion is inert to that block-lifetime guard (it has no CFG blocks). | 698 → ~712 |
| `ir-pass/include/ControlledSymbols.h` + `.cpp` | **WI-2.** Add `copyControlledFn(StringRef abiWidth)` next to `cswapFn` (`.cpp:110`, `.h:90`): `getOrInsertFunction("cqrt_copy_"+abiWidth+"_controlled", FunctionType::get(VoidTy,{I32,I32,I32},false))` — control flag arg-0. **Integer-only guard via the public path** `Wd.llvmWidthType(abiWidth)->isIntegerTy()` (NOT `copyFn`'s private file-local `typeForAbiWidth`, unreachable here) → covers `{i1,i8,i16,i32,i64}`, returns `FunctionCallee()` for f32/f64 (loud decline, §16.4 staged). | ~120 → ~135 |
| `ir-pass/src/ChainWalk.cpp` | **WI-3 (§16.5 binding obligation).** Add a file-local `isControlledCopyOut(const CallInst*, const Value*)` (model on `isMeasureSink` :64-67: name `starts_with("cqrt_copy_") && contains("_controlled") && arg_size()>=2 && getArgOperand(1)==H` — **`src` is arg1** for a controlled copy) and OR `&& !isControlledCopyOut(CI, H)` into `forwardConsumerCount` (**`:77` ONLY**) so a controlled-copy reading an upstream lineage handle does not trip the fan-out bail (`:137`) that would silently drop an unrelated chain's uncompute. **Do NOT touch `isTerminalHandle`** — the no-free/leave-allocated behaviour is already its default (`:105` returns false for the copy's src). | ~190 → ~200 |
| `ir-pass/src/CMakeLists.txt` | Add `SelectClassify.cpp`, `SelectMergeEmit.cpp` to `add_library(CQPass MODULE …)`. | — |
| `runtime/cq_runtime.{h,c}` | **WI-2.** 5 hand-written core decls + trace bodies `void cqrt_copy_<W>_controlled(int32_t ctrl, int32_t src, int32_t dst)` after the existing `cqrt_copy` block (h:`243-247`, c:`431-454`), mirroring `cqrt_cswap`'s 3-arg no-arrow void trace (`c:416-419`). Extend the `h:235-237` no-FP comment to cover the controlled twin. **NOT** in `opcode_table.yaml` (core ABI, not generated — `gen_templates.py --check` stays clean). | — |
| `runtime/test_trace.c` + `test_trace.expected.log` | **WI-2.** 5 calls (void, reuse existing handles, counter frozen at `h32`) after the `cqrt_copy` block (`138-142`) + 5 appended golden lines (byte-diffed). | — |
| `tests/e2e/CMakeLists.txt` + new slice | **WI-4.** `slice_control_select.{c,expected.log}` + explicit `add_test` (e2e is NOT auto-globbed). | — |

**`CQLoweringPass.cpp` is untouched.** The pipeline position already serves the
select (verified order in `CQLoweringPass::run`, mirrored in the `runOnFunction`
twin — both route through `detectControlRegions`/`lowerControlRegions`, so the
hook is inherited and the **twin-pipeline trap is avoided**):

```
 L47  propagate                       taint built ONCE (pre-RAUW SSA identity holds to L84/L110)
 L64  declineTaintEscapes             skips select/phi (split ownership) — does NOT own selects
 L71  declineStaleRecordOps
 L83  detectControlRegions            <-- 4.4 SELECT DETECT HOOK (SelectClassify)
 L84  lowerControlRegions             <-- 4.4 SELECT EMIT HOOK (emitSelectRegion); RAUWs %sel→%out
 L96  declineClassicalMuxes           owns CLASSICAL-cond selects (kMsgClassicalSelect); 4.4 must NOT relax
 L110 lowerRotations                  ONLY caller of declineTaintedAngle — runs TOO LATE to backstop an accepted select
 L111 lowerOps  L112 lowerMeasures  L115 uncompute (Phase 5, LAST)
```

The **binding obligation** the position imposes (§6): `emitSelectRegion` must
RAUW `%sel→%out` + `scrubTaint` + erase the select **inside** `lowerControlRegions`
(L84), **before** `declineClassicalMuxes` (L96) — else a surviving tainted-condition
select reaches that guard. (It would harmlessly `continue` at `TaintPropagation.cpp:752`,
but a *surviving* tainted-condition select means emission failed; a §8 probe
asserts none survives.)

---

## 2. Shared diagnostic helper

Unchanged — `diagnoseUnderControl` (`ControlPlan.h:292`, defined
`ControlDetect.cpp:45-50`), rendering `cq controlled lowering: <What> under
quantum control` as `DiagnosticInfoUnsupported(DS_Error)` with the offending
`SelectInst`'s `!dbg`. 4.4 introduces **one new `What` string** — **`rotation
angle`** for the §3.2 angle-select decline (re-using the exact word `ArmClassify`
already passes for the region-angle case, so the dialect stays consistent) — and
reuses `control flow` for every other select decline (width, fp-data, coherent,
aliasing, non-lowerable condition). It does **NOT** use `RotationLowering`'s
`diagnoseUnsupported` dialect (`cq rotation lowering: unsupported …`,
`RotationLowering.cpp:51`) — that is the straight-line angle path, a different
surface; the select-angle decline fires in the **control** detector and must
carry the control dialect. Each string is mirrored character-for-character by its
decline fixture (Rule 12).

---

## 3. Detection & classification (pure analysis, before any mutation — Rule 9)

### 3.1 The select-acceptance ladder — `SelectClassify::classifySelectRegion`

`classifySelectRegion(SelectInst *Sel, TaintSet &taint, ControlPlan &plan)` is
invoked from `ControlDetect`'s per-block select scan exactly where the blanket
`diagnoseUnderControl(Sel, "select")` lives today (`ControlDetect.cpp:226-229`).
All checks are by SSA-value identity **before any mutation** (Rule 9), so they
survive rotation lowering's RAUW-to-handle (the detector runs at L83; emission at
L84; rotation lowering at L110):

```
classifySelectRegion(Sel, taint, plan):
  # Entry: only tainted-condition selects (classical-cond is declineClassicalMuxes's, §16.8).
  if (!taint.Tainted.count(Sel->getCondition())) return;        # not ours; leave for L96

  # GATE 2 — lowerable compare condition.
  auto *Cond = dyn_cast<CmpInst>(Sel->getCondition());
  if (!Cond || !comparePredLowerable(Cond))                     # ArmAnalysis.h:133
      return diagnoseUnderControl(Sel, "control flow");

  # GATE 3 — the §16.2 BLOCKER: NOT an angle (transitive arg-1 forward walk). FIRST.
  if (selReachesRotationArg1(Sel))                              # §3.2, NEW code
      return diagnoseUnderControl(Sel, "rotation angle");       # re-pins the angle fixture

  # GATE 4 — ABI-width integer result (§16.9). After the FP-use fence (gate 3 covers FP-as-angle;
  #          this rejects fp-as-DATA + vector/i128/ptr/aggregate). The f64 trap: never key on width alone.
  Type *T = Sel->getType();
  if (T->isFPOrFPVectorTy() || !T->isIntegerTy() || abiWidthFromType(T).empty())
      return diagnoseUnderControl(Sel, "control flow");

  # GATE 5 — conservative coherent-operand default (§16.7), decidable v1 proxy.
  for (Value *Op : { Sel->getTrueValue(), Sel->getFalseValue() })
      if (taint.Tainted.count(Op) && hasCoherentDownstreamUse(Op, Sel, taint))  # §3.3
          return diagnoseUnderControl(Sel, "control flow");

  # GATE 6 — distinct operands / aliasing guard (§16.9), conservative form.
  if (operandsAlias(Sel->getTrueValue(), Sel->getFalseValue(), taint))           # §3.4
      return diagnoseUnderControl(Sel, "control flow");

  # ACCEPT.
  ControlRegion R; R.Kind = ControlRegion::SelectRegion;        # ControlPlan.h:119
  R.Merge = Sel; R.Condition = Sel->getCondition();             # SelectInst fits Instruction* Merge
  plan.Regions.push_back(R);
```

No `ControlPlan` field is added — `Kind::SelectRegion` (`ControlPlan.h:119-124`,
present-but-unused since the WP4 vocabulary landed) and the `Instruction* Merge`
slot (`:129`) already hold a `SelectInst`; the emitter reads
`TrueValue`/`FalseValue` off `cast<SelectInst>(R.Merge)` and `Wd` off
`abiWidthFromType(Sel->getType())` (valid at emit time — L84 precedes rotation
lowering at L110, so the select and its operands still carry real logical types,
§4).

**Reuse (Rule 14):** gate 2 = `comparePredLowerable` (`ArmAnalysis.h:133`);
gate 4 = `abiWidthFromType` (`OpcodeSupport.h:84`) with the FP-use fence ordered
exactly as `ArmClassify.cpp:820`→`:834`; gate 6 = `diagonalAliasHit`
(`ArmAnalysis.h:61`) + `condProvenance` (`ArmAnalysis.h:52`). Gate 3 is the one
genuinely new walk (§3.2).

### 3.2 The NEW transitive arg-1 angle gate — `selReachesRotationArg1` (the BLOCKER)

The §16.2 BLOCKER: **there is no downstream backstop.** `declineTaintedAngle`
(`RotationLowering.cpp:74`, tests `taint.Tainted.count(Rot->getArgOperand(1))`)
is the only rotation-angle decline reachable from a select arm, and it is called
**solely** inside `lowerRotations` (L110). `lowerControlRegions` (L84) runs 26
lines earlier and **RAUWs an accepted select's product to a fresh untainted
`cqrt_alloc` `i32` handle** — so by L110 `taint.Tainted.count(arg1)` is `false`
and the angle leaks silently (verify-clean miscompile, the f64/angle family).
Therefore 4.4 detects the angle **at detection time, pre-mutation**, mirroring the
region twin `ArmClassify::taintedAngleGate` (which declines via
`diagnoseUnderControl(Bad, "rotation angle")`).

`selReachesRotationArg1` is a **new forward worklist walk** (no existing helper
walks forward from a value to a rotation arg-1 — `taintedAngleGate` walks arm
spines *backward*; `condProvenance` walks condition operands backward;
`findNonDiagonalWireGate` follows arg-0 *handle* wires). It reuses the
**carrier-set pattern** from `WireWalk.cpp:105-113` and the **arg-1 predicate**
from `TaintPropagation.cpp:300-303` (Rule 14, pattern-source not drop-in):

```
selReachesRotationArg1(Sel):
  worklist W = { Sel };  visited V = {};
  while (U = W.pop()):
    for (User *X : U->users()):
      if (X already in V) continue;  V.insert(X);
      # arg-1 angle reach (the per-use predicate from TaintPropagation.cpp:300-303):
      if (auto *CI = dyn_cast<CallInst>(X))
        if (callee name starts_with "cq_phi_" || "cq_theta_")
          if (CI->arg_size() >= 2 && CI->getArgOperand(1) is reached-from-Sel)
            return true;                                  # angle — decline WHOLE select (fan-out rule)
      # value-preserving carriers only (do NOT cross arithmetic/compare — those re-realize the value):
      if (isa<FPExtInst,FPTruncInst,BitCastInst,SelectInst,PHINode>(X))
        W.push(X);                                        # but for a SelectInst, only if X uses U as a VALUE operand,
                                                          #   not as the condition (CompareLowering.cpp:54-56 discriminator)
  return false;
```

The **fan-out rule** (PRD §16.2): `%sel` can be tainted-as-data **and** feed an
arg-1 angle at once, because the arg-1 exclusion is **per-operand-use**, not
global (`TaintPropagation.cpp:300-303` — the `&& getArgOperand(0) != V` clause).
Splitting (merge for data uses, rotate for the angle use) double-realizes the
value = silent miscompile. So a single arg-1 reach declines the **entire**
select. A §8 probe pins a dual-use select (`%sel` feeding both `cq_phi` arg-1 and
a `measure`) and a transitive-cast probe (`%w = fpext %sel; cq_phi(%qd, %w)`).

`isPhiCall`/`isThetaCall` are TU-local in `ArmClassify.cpp`/`RegionTreeDetect.cpp`
(deliberately not exported — they collide across TUs); `SelectClassify` re-derives
the two-line name-prefix checks locally.

### 3.3 The conservative coherent-operand proxy — `hasCoherentDownstreamUse` (§16.7)

The PRD ships **conservative**: accept basis-valued operands, decline coherent
(`Ry`/phase-carrying) operands, until the §8 Rule-13 clearance answers whether any
basis/phase combination makes `%out` *wrong* (not merely entangled). The
**decidable v1 proxy** — over-decline-safe, accepts the canonical
`(q>5)?q:x`, and matches the §16.7 probe exactly (*"a coherent operand whose
lineage also feeds a downstream cq_phi"*):

> A tainted value operand is **coherent-for-decline** iff it has a **quantum use
> beyond this select** — i.e. (forward-scanning its users) it feeds a separate
> rotation (`@cq_phi_*`/`@cq_theta_*`) or another gate whose interference would
> observe its coherence. Reads by the condition `icmp`, the strip `icmp_inv`, the
> select's own copy, a downstream `cq_measure`, or `ret` do **not** count (those
> are owned by the mint/strip/measure/caller — the §16.5 operand-disposition
> matrix).

`(q>5)?q:x` where `%q`'s only further uses are the condition `icmp` + the select +
a downstream `measure` → **accept** (the canonical e2e shape). `%q` additionally
feeding `cq_phi(%q, θ)` downstream → **decline** (channel-B dephasing). This is a
single forward-use scan; the **exact coherent-vs-basis boundary is the binding
Rule-13 clearance item before any widening** (§8, §9) — the dialogue's position is
full coherent accept, the clearance adjudicates it. **Design note for the build:**
this proxy is the most-conservative reading that still accepts §15's canonical
shape; if the clearance proves a narrower or wider line, re-pin gate 5 then (it is
the one gate whose predicate the PRD explicitly leaves to clearance).

### 3.4 The aliasing guard — `operandsAlias` (§16.9, conservative form)

The two value operands must resolve to **disjoint** post-lowering registers; an
operand aliasing the other (the hoisted in-place-arithmetic corner) would make one
copy read a register the merge is muxing against. The dangerous alias is only
literal *after* rotation lowering's RAUW-to-handle (which pre-mutation SSA cannot
see), so the **conservative form** (recommended, Prime-Directive-safe):

```
operandsAlias(A, B, taint):
  if (isa<Constant>(A) || isa<Constant>(B)) return false;       # a classical literal never aliases a handle
  # materialize A's backward cq_phi diagonal-alias closure, test B against it:
  SmallPtrSet<Value*,8> clo; for (V = A; ; V = phiArg0(V)) { clo.insert(V); if (!isPhiCall(V)) break; }
  return diagonalAliasHit(B, clo) != nullptr;                   # shared physical wire → decline
```

A fresh **out-of-place** template result (`q+1` → a new `cq_template_add` handle,
distinct from `q`) has a disjoint closure → `(q>5)?q:q+1` **accepts**. The
hoisted-in-place family (the arithmetic aliasing `q`'s register) intersects →
decline. `diagonalAliasHit` takes a `Prov` **set**, so operand-vs-operand needs A's
closure materialized inline (there is no closure-vs-closure helper — armclassify
gotcha). A §8 probe pins both directions (distinct-closure accept, intersecting
decline).

---

## 4. Emission — `SelectMergeEmit::emitSelectRegion` (the controlled-XOR copy merge)

Dispatched from `SwapRouteEmit::lowerControlRegions` (`:698`) on
`R.Kind == SelectRegion`. The whole job (PRD §16.3) emitted **before the
select**, one `IRBuilder` at `Sel`, in this **exact order** (the §5a contract).
**No rail, no route `cqrt_cswap`, no `RegionFlatten`, no reverse-play** — the
single biggest simplification vs. the br-diamond emitters:

```
emitSelectRegion(R, wd, csyms, taint):
  Sel = cast<SelectInst>(R.Merge);  Cond = cast<CmpInst>(R.Condition);
  Tru = Sel->getTrueValue();  Fls = Sel->getFalseValue();
  StringRef Wd = abiWidthFromType(Sel->getType());      # valid: emit (L84) precedes lowerRotations (L110)
  IRBuilder<> B(Sel);  DebugLoc DL = Sel->getDebugLoc();

  1. MINT the flag (Wc = condition operand width, handled inside the helper):
        %f = lowerCompareToFlag(Cond, wd, taint, /*qq=*/{}, /*inverse=*/false, /*before=*/Sel)
        if (!%f) return;                                  # already diagnosed (unsupported width / Q+Q)
  2. ALLOC the |0> result rail (Wd):
        %out = B.CreateCall(wd.allocFn(Wd), {Constant::getNullValue(llvmWidthType(Wd))}, "out")
        taint.Tainted.insert(%out); taint.BirthOrder.push_back(%out)   # downstream keeps treating it as a handle
  3. COPY the TRUE value on the flag (materialize if classical):
        %ta = materialize(Tru, Wd, B)                     # quantum handle: identity; classical: cqrt_alloc_<Wd>(Tru)
        B.CreateCall(csyms.copyControlledFn(Wd), {%f, %ta, %out})       # fires on f=1
  4. COPY the FALSE value on ¬flag (X-bracketed, the 4.1 convention):
        B.CreateCall(csyms.xFn(), {%f})                   # cqrt_x(%f)
        %fa = materialize(Fls, Wd, B)
        B.CreateCall(csyms.copyControlledFn(Wd), {%f, %fa, %out})       # fires on original f=0
        B.CreateCall(csyms.xFn(), {%f})                   # cqrt_x(%f) — restore f for the strip
  5. STRIP the flag (structurally valid — the merge never wrote Cond's lineage, §16.5):
        lowerCompareToFlag(Cond, wd, taint, {}, /*inverse=*/true, /*before=*/Sel)   # icmp_<Wc>_hl_inv
        B.CreateCall(wd.freeFn(), {%f})                   # the ONLY cqrt_free
  6. REWIRE (NO flatten — there is no CFG):
        Sel->replaceAllUsesWith(%out); scrubTaint(Sel, taint); Sel->eraseFromParent()
```

`materialize(V, Wd, B)`: a **quantum handle** operand is already a register —
return it unchanged. A **classical** operand (compile-time constant **or** runtime
classical value) is materialized `%h = cqrt_alloc_<Wd>(V)` (option A, PRD §16.4 —
all-core ABI, no template `_controlled`; the scratch is left allocated, a benign
classical-valued §0 leak). Both `Tru` and `Fls` flow through it; for the
Q+Q case (`(q>5)?q:q+1`) both are handles and `materialize` is the identity.

**Frees / leaks (§16.5).** **Exactly ONE `cqrt_free`** — the flag, after the strip
(provably `\|0⟩`). `%out`, both operands, and any materialized scratch are **NEVER
freed**: `%out` is the live result (owned downstream by the user's `cq_measure` or
`ret`); operands/scratch are left allocated (freeing an operand entangled with
`%out` via the copy would be a hidden measurement — Rule 6/8). The spine
(`uncompute`, L115) adds **no** free: `isTerminalHandle(%out)` is `false` (the
copy_controlled is a non-`isInPlaceGateOn`/non-`isMeasureSink` CallInst user →
`ChainWalk.cpp:105`), and the operands are non-terminal for the same reason — all
left allocated by default (§16.5 / the ChainWalk no-free-is-default correction).

**The ¬flag bracket scope is order-sensitive** (PRD §16.3, the load-bearing
correctness beyond the `dst=\|0⟩` precondition): the `cqrt_x` must tightly enclose
**only** the second copy. A mis-bracketed emitter (`cqrt_x` before *both* copies)
double-writes `a` then `b` on the same basis branch yet produces the **identical
symbol multiset** — invisible to a count-only CHECK. §5a pins an **ordered
FileCheck** (`copy(f,a,out)` → `x(f)` → `copy(f,b,out)` → `x(f)`), the 4.3 §12.3
strip-order precedent.

**Width source (Rule 9, the resolved gotcha).** `Wd = abiWidthFromType(Sel->getType())`
is read at emit time and is **reliable** because emission (L84) runs **before**
`lowerRotations` (L110) — the select and its operands still carry their real
logical types (`select`'s result/operand types are identical per LLVM, and the
tainted `cq_theta` handle is typed by its suffix, e.g. `si8→i8`). This is *not*
the post-RAUW i32-laundering trap (which only bites a width read *after* L110).
`Wc` (the condition width) is handled internally by `lowerCompareToFlag`. A
`select` whose result type is i32 from an i32 mux is genuinely `Wd=i32`; nothing
keys off a laundered handle.

---

## 5. Target symbol sequences (the FileCheck contract)

### 5a. Quantum+classical accept — `(q>5) ? q : x` (`control_swap_select_qc.ll`)

Pinned from the measured `-O1` shape (§0). `%[[Q]]` is the `@cq_theta` handle;
`%[[F]]` the flag:

```
%f   = call i32  @cq_template_icmp_sgt_i32_hl(i32 %qc, i32 5)       ; 1 mint (Wc=i32)
%out = call i32  @cqrt_alloc_i32(i32 0)                             ; 2 |0> result rail (Wd=i32)
       call void @cqrt_copy_i32_controlled(i32 %f, i32 %qc, i32 %out) ; 3 true=q on f=1
       call void @cqrt_x(i32 %f)                                    ; 4 ¬flag bracket open
%xh  = call i32  @cqrt_alloc_i32(i32 %x)                            ; 4 materialize classical false operand
       call void @cqrt_copy_i32_controlled(i32 %f, i32 %xh, i32 %out) ; 4 false=x on ¬f
       call void @cqrt_x(i32 %f)                                    ; 4 ¬flag bracket close
%f0  = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %qc, i32 5)   ; 5 strip (vs qc)
       call void @cqrt_free(i32 %f)                                 ; 5 the ONLY free
%m   = call i32  @cqrt_measure_i32(i32 %out)                        ; (sel RAUW'd → out)
```

Hard postconditions: `CHECK-NOT: cqrt_cswap`, `CHECK-NOT: phi i32`,
`CHECK-NOT: cqrt_{rz,ry}{{.*}}_controlled` (**narrowed** — the bare
`CHECK-NOT: _controlled` would falsely fire on the intended
`cqrt_copy_i32_controlled`), **`CNT-COUNT-1: @cqrt_free`** + trailing
`CNT-NOT: @cqrt_free` (no second free from `uncompute`), and a `CHECK-NOT:
@cqrt_measure` *unless the source writes one* (a `ret %sel` variant proves the
emitter adds no measurement — Rule 5).

**THE 4.4-specific ordered FileCheck** (`--check-prefix=ORD`, §6, §8 — the
structural CHECKs are order-blind; a mis-bracketed emitter yields the identical
multiset):
```
; ORD: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
; ORD: call void @cqrt_x(i32 %{{.*}})
; ORD: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
; ORD: call void @cqrt_x(i32 %{{.*}})
```
The `alloc`/`free`/mint/strip lines float around these four (a full-sequence pin
over-constrains — PRD §16.9).

### 5b. Quantum+quantum accept — `(q>5) ? q : q+1` (`control_swap_select_qq.ll`)

Both operands are handles (`%q1 = cq_template_add_i32_hl(%qc, 1)` is the distinct
out-of-place false operand, §3.4 → accept). The stream is §5a with **no
materialization** (both copies read existing handles):

```
%f   = call i32  @cq_template_icmp_sgt_i32_hl(i32 %qc, i32 5)
%out = call i32  @cqrt_alloc_i32(i32 0)
       call void @cqrt_copy_i32_controlled(i32 %f, i32 %qc, i32 %out)   ; true=q
       call void @cqrt_x(i32 %f)
       call void @cqrt_copy_i32_controlled(i32 %f, i32 %q1, i32 %out)   ; false=q+1 (distinct handle)
       call void @cqrt_x(i32 %f)
%f0  = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %qc, i32 5)
       call void @cqrt_free(i32 %f)
```
Same hard postconditions + ordered ORD CHECK. Confirms `materialize` is the
identity on handles and **no `cqrt_alloc` is emitted for a quantum operand**.

### 5c. Decline contrast set (each its own fixture, one region per file, string confirmed against real `-O1`)

- `control_swap_defer_select_angle.ll` — **RE-PINNED** (PRD §16.2): a `double`
  `%ang = select i1 %c, double 0.25, double 0.75` feeding `cq_phi` arg-1 →
  **`rotation angle`** (the new §3.2 detector). A `CHECK-NOT: cqrt_copy` /
  `CHECK-NOT: cqrt_alloc` asserts **nothing is emitted** for it. *(This is a
  deliberate baseline action, Rule 12 — the fixture does NOT "stay green"; its
  old `select` CHECK is replaced. Confirm `rotation angle` actually fires against
  the post-4.4 build before pinning — Rule 11.)*
- `control_swap_reject_select_angle_cast.ll` — transitive-cast angle
  (`%w = fpext %sel; cq_phi(%qd, %w)`) → **`rotation angle`** (proves the walk
  follows value-preserving carriers, not just direct users).
- `control_swap_reject_select_dualuse.ll` — dual-use fan-out (`%sel` feeds a
  `cq_phi` arg-1 **and** a `measure`) → **`rotation angle`** (declines the WHOLE
  select — the §3.2 fan-out rule; never split).
- `control_swap_reject_select_fpdata.ll` — `f64` result feeding `fadd`/`measure`
  (not an angle) → **`control flow`** (fp-data staged out, §16.4; re-pin to accept
  once fp is cleared).
- `control_swap_reject_select_vector.ll` / `…_i128.ll` — vector / `i128` result →
  **`control flow`** (the §16.9 width gate / null-callee trap).
- `control_swap_reject_select_coherent.ll` — a tainted operand whose lineage also
  feeds a downstream `cq_phi` → **`control flow`** (the §16.7 conservative
  default; re-pin once the boundary is cleared).
- `control_swap_reject_select_alias.ll` — the two operands share a post-lowering
  register (intersecting diagonal-alias closures) → **`control flow`** (§16.9).
- `control_swap_reject_select_badcond.ll` — a non-`CmpInst` tainted `i1` condition
  (or an out-of-scope `fcmp` predicate) → **`control flow`** (gate 2).
- `control_swap_reject_nested_select.ll` — **UNCHANGED**, still declines on the
  OUTER tainted branch (`control flow`) before the select scan runs — a
  regression floor the §3.1 entry must not disturb.
- `lowering_reject_classical_mux_select_{onereg,alltainted_main,measured,escape}.ll`
  — **UNCHANGED**, the `declineClassicalMuxes` classical-condition path
  (`cq taint escape: tainted value muxed by a classical-condition select`); 4.4
  must NOT relax it (§16.8). These stay green by construction (the §3.1 entry
  only handles tainted-condition selects).

**§3c-vacuity contract (§16.6).** `control_swap_select_condreg.ll` — the
operand-is-the-condition-register select `(q>5)?q:x` (already §5a) carries a
`CHECK-NOT: arm rewrites a condition operand` proving the §3c clobber string is
**never** emitted for a select (its absence is the contract — there is no §3c
decline fixture for 4.4).

**Baseline regeneration (Rule 12, deliberate).** `control_swap_defer_select.ll`
(the select-over-handle decline) **graduates to an accept** at WI-3 — it becomes
`control_swap_select_qc.ll` (or is converted in place). Until WI-3 it stays in
suite under a transitional decline; its accept CHECK lands only when emission does
(the 4.2 `control_swap_defer_valuearm.ll` / 4.3 `control_swap_defer_nested.ll`
graduation precedent). `control_swap_defer_select_angle.ll` is **re-pinned, not
retired** (it stays a decline, just to a different string).

---

## 6. Interlock hazards (Rule 10 / Rule 13 — the silent-miscompile surface)

Each is verify-clean-invisible; each ships with a §8 verification.

1. **No downstream angle backstop (the §16.2 BLOCKER).** `declineTaintedAngle`
   runs at L110, after L84 RAUWs `%sel→%out` (untainted) — `taint.Tainted.count(arg1)`
   is false by then. The angle gate MUST be the pre-mutation §3.2 detector.
   **Probe (§8):** the angle / cast-angle / dual-use fixtures decline at detection
   with **no** `cqrt_copy`/`cqrt_alloc` emitted; `opt -verify` green proves
   nothing.
2. **¬flag bracket order (the 4.4 core hazard, §16.3).** The `cqrt_x` must enclose
   only the second copy. A mis-bracket double-writes on one basis branch with an
   **identical symbol multiset** → wrong `%out`. Order-blind to count CHECKs →
   **needs the ordered FileCheck** (§5a) + the written two-row `(f=0,f=1)` trace
   (§8), not just structural CHECKs.
3. **Width source pre-RAUW** (§4). `abiWidthFromType(Sel->getType())` is read at
   emit (L84) **before** rotation lowering (L110) launders handles to i32. A
   read after L110 silently forces `Wd=i32` (a width miscompile). **Probe:** an
   i8-mux accept fixture (`select i1 %c, i8 %q, i8 %x`) emits `cqrt_alloc_i8` /
   `cqrt_copy_i8_controlled`, not i32.
4. **Erase before `declineClassicalMuxes`** (§1, the pipeline coupling).
   `emitSelectRegion` is the sole owner of the select: RAUW→`%out` + `scrubTaint`
   + erase in step 6, inside `lowerControlRegions` (L84), **before**
   `declineClassicalMuxes` (L96). A surviving tainted-condition select would mean
   emission failed. **Probe (§8):** a `kMsgClassicalSelect`-never-fires assertion
   on an accepted select.
5. **ChainWalk fan-out silent drop (§16.5).** A controlled-copy reading an
   upstream lineage handle `H` must not push `forwardConsumerCount(H)>1` and
   silently drop an **unrelated** chain's uncompute (the bail at `:137` is a
   **silent `continue`**, not a diagnostic — `Uncomputation.cpp:180`). Fix: the
   `isControlledCopyOut` exemption at `forwardConsumerCount:77` (**only** — never
   `isTerminalHandle`, whose no-free default is already correct). **Probe (§8):** a
   no-spurious-free fixture — an operand whose lineage also feeds a downstream
   rotation chain keeps that chain's adjoint+free.
6. **§3c vacuity** (§16.6). A select writes nothing; the clobber string is
   unreachable. **Probe:** `CHECK-NOT: arm rewrites a condition operand` on the
   operand-is-condition fixture.
7. **Polarity (Rule 9).** A select has no successor blocks to swap, but `-O1`
   canonicalizes the `icmp` predicate/operand order. The flag mint uses the
   **actual emitted predicate** (`lowerCompareToFlag` handles `flipPredicate`); the
   select's true-value (operand 1) maps to `f=1`, false-value (operand 2) to
   `f=0`. **Probe (§8):** a polarity-canonicalized `icmp` fixture
   (`!=`-canonicalized) lowers to the correctly-mapped stream.
8. **Stale work-list scrub** (the §6.1-4.1/4.2 hazard). The erased select is
   `scrubTaint`'d from `Tainted`/`BirthOrder`/`StaleDeclined`/`PhiCalls`
   (`SwapRouteEmit.cpp:59` pattern, mirrored per-TU in `SelectMergeEmit`); `%out`
   is inserted so downstream consumers keep classifying it as a handle. A missed
   scrub dangles a later `lowerRotations`/`uncompute` walk.
9. **Conservative-default honesty** (§16.7). The shipped accept set declines
   coherent operands; the proxy (§3.3) is the most-conservative reading that
   accepts §15's canonical shape. **Cleared/widened only by §8 Rule-13 review** —
   a green suite does not authorize widening gate 5.

---

## 7. Test-driven work-item sequence

Red-green per Rule 12 (fixture first, watch it fail, implement minimally; accepts
land `; XFAIL: *` until their WI, removed at XPASS). One commit per WI. WI-3 is a
core-lowering change — it does **not** ship on a green suite alone (Rule 13); it
clears only after §8.

| WI | Goal (observable) | Lands | Red→Green fixtures |
|---|---|---|---|
| **WI-1** | **Select detection ladder + all declines** (no emission). `SelectClassify` proves/declines the §0 shape (incl. the §3.2 transitive arg-1 angle gate, the §16.9 width/aliasing gates, the §16.7 conservative coherent proxy); accepted selects decline *transitionally* via the existing `select`→`control flow` string (or stay `XFAIL`) while emission is unbuilt, so nothing mis-lowers. | `SelectClassify.{cpp,h}`; `ControlDetect.cpp` (replace the blanket decline); CMake. | **green (all real-`-O1`-pinned, §5c):** the full decline matrix (angle **re-pinned `rotation angle`**, cast-angle, dual-use, fp-data, vector/i128, coherent, alias, bad-cond) + the UNCHANGED nested-select + 4× classical-mux fixtures. **XFAIL:** the §5a/§5b accepts. |
| **WI-2** | **`cqrt_copy_<W>_controlled` ABI + minter** (the only new ABI). 5 hand-written core decls/bodies in `cq_runtime.{h,c}`; `ControlledSymbols::copyControlledFn` (integer-only via `llvmWidthType().isIntegerTy()`); `test_trace.c` + golden. | `cq_runtime.{h,c}`, `ControlledSymbols.{h,cpp}`, `test_trace.c`, `test_trace.expected.log`. | **green:** `runtime_trace_test` (5 appended golden lines), `runtime_header_compile`; `gen_templates.py --check` clean (YAML untouched). |
| **WI-3** | **Emit the controlled-XOR copy merge** (core, Rule 13). `SelectMergeEmit::emitSelectRegion` + the `lowerControlRegions` `SelectRegion` dispatch + the pre-flight null-block skip; the §16.5 `isControlledCopyOut` ChainWalk exemption; RAUW→`%out` + erase before `declineClassicalMuxes`. **Graduate `control_swap_defer_select.ll`** → `control_swap_select_qc.ll`. | `SelectMergeEmit.{cpp,h}`, `SwapRouteEmit.cpp` dispatch, `ChainWalk.cpp` exemption. | **green (un-XFAIL):** `control_swap_select_qc.ll` (§5a, incl. the ordered ORD CHECK + `CNT-COUNT-1`) + `control_swap_select_qq.ll` (§5b) + the i8-width + polarity + no-spurious-free + `condreg` §3c-vacuity probes. |
| **WI-4** | **e2e golden** (Rule 16/2 — the ONLY layer that links; proves `cqrt_copy_<W>_controlled` resolves + signature-matches). | `tests/e2e/slice_control_select.{c,expected.log}` + explicit `add_test`. | **green:** `ctest -R e2e-slice-control-select`. |
| **WI-5** | **§8 adversarial clearance + docs + closeout** (Rule 13). The two-row `(f)` bracket-order trace + the §16.7 coherent-operand boundary cleared by independent review; ROADMAP 4.4 flip; PRD §17 done-criteria check; `bd remember`. | docs, memories, residual XFAIL removal. | full `ctest` green; `gen_templates.py --check` clean. |

Dependencies: WI-3 ← {WI-1, WI-2}; WI-4 ← WI-3; WI-5 ← {WI-3, WI-4}. (No WI-0 —
the header-promotion the new TUs would need was already paid by 4.3's WI-0; see
header.)

---

## 8. Adversarial verification plan (Rule 13 — clears the core change)

A green suite does not clear `emitSelectRegion` or the §16.7 boundary. Scope (bd
`rule13-no-backend-clearance-scope` / `no-simulations-at-this-stage`):
**analytic/trace-level review + lowered-IR reading + structural probes** — no
backend, no statevector simulation (owner decision 2026-06-10). The PRD's 5-lens
pre-clearance (2026-06-15, `CLEARED-WITH-AMENDMENTS`) cleared the **shape**;
WI-3/WI-5's obligation is the **emitter-fidelity** clearance (the implemented
stream matches the cleared design) **plus** the two residual lenses the PRD names:
the §16.7 coherent-operand boundary and the §3.2 angle gate.

1. **The two-row `(f)` bracket-order trace (§16.3), written + reviewed before
   WI-3 ships.** On a basis condition, show `f=1` writes only `a` into `%out` and
   `f=0` writes only `b` (the ¬flag bracket making the two copies disjoint), and
   the mis-bracketed emitter (`x` before both copies) writes `a` then `b` on the
   same branch → wrong `%out`. Mapped to the §5a **ordered FileCheck** (the only
   automated layer that catches the misorder — the multiset is identical).
2. **The §3.2 angle-gate airtightness (the BLOCKER lens).** Reason that the
   transitive forward walk through value-preserving carriers
   (`fpext`/`fptrunc`/`bitcast`/`select`/`phi`) catches every path `%sel`→rotation
   arg-1, and that the fan-out rule (decline the whole select) is sound given the
   per-use arg-1 exclusion. Confirm against real `-O1` IR that the re-pinned
   `rotation angle` string actually fires (Rule 11), not a leaked
   `declineTaintedAngle`.
3. **The §16.7 coherent-operand boundary (both channels, the residual lens).**
   Reason analytically (the 4.2 §8.2 closed-form analogue): `%out` is the correct
   `c?a:b` in the computational-basis/reversible model (each branch holds the
   right value); a CNOT-copied coherent operand leaves `%out` entangled (channel
   A) **and** kills the operand's own marginal off-diagonal so a *standalone*
   downstream use of the operand is dephased (channel B). Adjudicate whether any
   basis/phase combination makes `%out` *wrong* (not merely entangled) — the
   gate for widening gate 5 beyond the §3.3 conservative proxy. `cq_invert`
   (Phase 7) restores fidelity only for compute→use→uncompute, not keep-and-continue.
4. **Read the actual lowered IR** (Rule 11) for §5a/§5b and diff against §4 — the
   emitter-fidelity gap is invisible to every automated layer.
5. **No-spurious-free + single-free.** `CNT-COUNT-1: @cqrt_free` + trailing
   `CNT-NOT` (the flag is the only free; `uncompute` adds none); the §16.5
   no-spurious-free probe (an operand whose lineage also feeds a downstream
   rotation keeps that chain's adjoint+free — proves the `isControlledCopyOut`
   exemption suppressed the fan-out bail without dropping the unrelated chain).
6. **Width fidelity.** The i8-mux fixture emits `cqrt_alloc_i8` /
   `cqrt_copy_i8_controlled` (width read pre-RAUW, hazard §6.3).
7. **Over-accept/decline matrix.** Every §5c row declines with the **exact**
   diagnostic confirmed by running its real `-O1` IR; the classical-mux + nested
   fixtures stay green untouched (the §16.8 ownership split holds); no constructed
   over-accept survives (vector/i128/ptr, fp-data, coherent, alias).
8. **Detection-structural probes.** (a) `kMsgClassicalSelect`-never-fires on an
   accepted select (hazard §6.4); (b) the §3c-vacuity `CHECK-NOT` (§6.6);
   (c) polarity-canonicalized `icmp` maps true/false operands correctly (§6.7).
9. **Dephasing guard (negative).** `CHECK-NOT: cqrt_cswap`,
   `CHECK-NOT: cqrt_{rz,ry}{{.*}}_controlled`, `CHECK-NOT: phi i32` on §5a/§5b
   (the merge is a copy, not a route — Rule 7/8).
10. **e2e trace diff** (WI-4) — the linking proof that `cqrt_copy_<W>_controlled`
    resolves + signature-matches.

**§8.x clearance verdict** *(added at WI-5 closeout)* — records the independent
review outcome (lenses, confirmed defects, silent-miscompile count), per the 4.2
§8.10 / 4.3 §8 precedent. **The shipped 4.4 default is the conservative form**
(classical/basis integer operands accept; coherent + fp-data decline); the
clearance gates each widening.

---

## 9. Done criteria (maps PRD §17)

- [ ] A tainted-condition **integer-data `select`** lowers to the merge stream the
      `.ll` fixtures pin (`icmp_<Wc>_hl` flag → `alloc <Wd>(0)` →
      `copy_<Wd>_controlled` on flag → `cqrt_x` / `copy` / `cqrt_x` on ¬flag →
      `icmp_<Wc>_hl_inv` strip → `cqrt_free`), `%sel` RAUW'd to `%out`, with the
      **narrowed** `CHECK-NOT: cqrt_{rz,ry}{{.*}}_controlled` (NOT bare
      `_controlled`), `CHECK-NOT: cqrt_cswap`, `CHECK-NOT: phi i32`, **exactly ONE
      `cqrt_free`** (`CNT-COUNT-1` + `CNT-NOT`), `%out`/operands/scratch never
      freed, `opt -verify` clean.
- [ ] **The ordered FileCheck** pins the ¬flag bracket scope
      (`copy(f,a,out)` → `cqrt_x(f)` → `copy(f,b,out)` → `cqrt_x(f)`); the two-row
      trace (§8.1) is **written + cleared by independent review** before WI-3 ships.
- [ ] `cqrt_copy_{i1,i8,i16,i32,i64}_controlled` land in the hand-written core ABI
      with the pinned signature/trace; the new `WidthDispatch`/`ControlledSymbols`
      minter (integer-only via `llvmWidthType().isIntegerTy()`, **not** a clone of
      `copyFn`) mints them; `runtime_trace_test` covers them;
      `gen_templates.py --check` clean (YAML untouched). fp widths deferred (§16.4).
- [ ] **`%out` carries no measurement and no `phi`** — the select step emits zero
      `cqrt_measure`; a `ret %sel` variant proves no measure appears (Rule 5).
- [ ] **Decline fixtures** (each `not … | FileCheck`, mirroring the string that
      ACTUALLY fires — confirmed against real `-O1`, one tainted region per file):
      angle-use → **re-pinned `rotation angle`** via the §3.2 detector
      (`+ CHECK-NOT cqrt_copy/cqrt_alloc`); transitive-cast angle → same;
      dual-use fan-out → same (whole select); fp-data / vector / i128 → `control
      flow`; coherent operand → `control flow` (conservative default);
      aliasing → `control flow`; non-lowerable condition → `control flow`;
      classical-condition + nested-select → **UNCHANGED** strings, still green.
- [ ] **§3c is structurally vacuous** — no §3c decline fixture; a `CHECK-NOT: arm
      rewrites a condition operand` on the operand-is-condition accept (§16.6).
- [ ] The §16.5 `isControlledCopyOut` ChainWalk exemption lands (`forwardConsumerCount`
      only); the no-spurious-free probe proves an unrelated chain keeps its
      uncompute; `isTerminalHandle` untouched (no-free is its default).
- [ ] ≥1 **e2e trace golden** (C-sourced, linked) diffs clean — the only layer
      proving `cqrt_copy_<W>_controlled` resolves + signature-matches.
- [ ] The **§16.7 coherent-operand boundary** (both channels) and the **§3.2 angle
      gate** are **cleared by independent Rule-13 review** (analytic/trace, no
      simulation) **before** any coherent/fp accept widens; a green suite alone
      does **not** clear it. **The shipped default is the conservative form.**
- [ ] 4.1/4.2/4.3 regression floor green (diamond / if-else / nested / value
      fixtures unchanged; no `cqrt_copy_<W>_controlled` leakage into non-`select`
      paths).
- [ ] Full `ctest` green; bd memory updated: `swap-route-detect-known-limits`
      (`select` no longer a blanket decline — tainted-condition integer-data
      selects accepted; angle-use / fp-data / coherent / classical-condition
      still decline) + a **new** memory for the **use-not-type discriminator +
      coherent-operand leave-allocated + ¬flag bracket-order** invariant (the
      verify-clean-invisible 4.4 rules).

---

## 10. Reuse map (Rule 14 — every need resolves to an existing symbol)

| Need | Existing symbol (file:line) |
|---|---|
| Flag mint / `_hl_inv` strip from the select's `icmp` condition | `lowerCompareToFlag` (`CompareLowering.cpp:207`, decl `CompareLowering.h:110`) — verbatim |
| Condition compare predicate gate | `comparePredLowerable` (`ArmAnalysis.h:133`) |
| Condition-vs-value-operand discriminator (the angle/coherent walks) | `isDataPositionCompare` pattern (`CompareLowering.cpp:45-56`) / `Sel->getCondition()` test |
| Result width gate (§16.9) | `abiWidthFromType` (`OpcodeSupport.cpp:148`, decl `OpcodeSupport.h:84`); FP-fence order from `ArmClassify.cpp:820`→`:834` |
| Diagonal-alias closure (§16.9 aliasing) | `diagonalAliasHit` (`ArmAnalysis.h:61`) + `condProvenance` (`ArmAnalysis.h:52`) — already de-anonymized |
| Carrier-set pattern for the §3.2 forward walk | `findNonDiagonalWireGate` carrier crossing (`WireWalk.cpp:105-113`) + the arg-1 predicate (`TaintPropagation.cpp:300-303`) — pattern source, not drop-in |
| `\|0⟩` rail (`%out`) + classical materialize + the single free | `WidthDispatch::allocFn` (`WidthDispatch.h:69`) / `freeFn` (`:126`) / `llvmWidthType` (`:59`) |
| **Flag-controlled basis copy** (the one new ABI) | **`ControlledSymbols::copyControlledFn`** (NEW, modelled on `cswapFn` `ControlledSymbols.cpp:110`) → `cqrt_copy_<W>_controlled` (NEW core ABI, `cq_runtime.{h,c}`) |
| ¬flag self-inverse bracket | `ControlledSymbols::xFn` (`ControlledSymbols.cpp:100`) → `cqrt_x` |
| RAUW + taint scrub on erase | `scrubTaint` (`SwapRouteEmit.cpp:59` pattern, mirrored per-TU) |
| Loud decline | `diagnoseUnderControl` (`ControlPlan.h:292`, def `ControlDetect.cpp:45`) |
| Region plan vocabulary | `ControlRegion::SelectRegion` Kind + `Merge`(SelectInst) + `Condition` (`ControlPlan.h:119-129`) — reused, no new field |
| Emit dispatch | `lowerControlRegions` (`SwapRouteEmit.cpp:698`) — add `Kind==SelectRegion` branch |
| Fan-out exemption for the controlled copy (§16.5) | `forwardConsumerCount` (`ChainWalk.cpp:73-80`) + new file-local `isControlledCopyOut` (model on `isMeasureSink` `:64`) |

Deliberately **NOT** used in 4.4 (each a documented decision): `cqrt_cswap`
routing / `emitRoute` (a select has no rail to route into — the controlled-XOR
copy writes directly into the `\|0⟩` out register, PRD §15/§16.1);
`RegionFlatten` / `flattenRegion` (no CFG diamond to collapse); the **uncontrolled**
`copyFn` (the merge must be flag-CONDITIONAL — `copyFn` is unconditional, PRD
§16.4); `emitInverseChain` reverse-play (a select has no arm chain to uncompute);
`computeFreePoint` (the single flag free is emitter-driven at the strip); the
option-B `cq_template_xor_<W>_hl_controlled` (would touch the YAML/SHA gate — PRD
§16.4 defaults to option A; recorded as the §11 open question);
`isTerminalHandle` edits (the no-free/leave-allocated default is already correct —
§16.5 correction).

---

## 11. Out of scope (declines wired in WI-1, implemented in later increments)

Honestly listed (PRD §18); each declines loudly until its increment.

- **Angle-use `select`** — `%sel` transitively reaching a rotation arg-1
  (§3.2). Its lowering is a controlled rotation (§6a/rotation path), not a merge.
  Declined by the **new 4.4 detector** (`rotation angle`); the fan-out form (also
  feeding data) declines the whole select.
- **fp-data `select`** (`f32`/`f64` result not used as an angle) — *in principle*
  data (type ≠ use) but **staged out** (§16.4): shipping
  `cqrt_copy_{f32,f64}_controlled` reverses the binding `cq_runtime.h:235-237`
  no-FP-twins invariant and is safe only once the §3.2 angle gate is independently
  cleared. Declines `control flow` until the fp-data accept path lands.
- **Vector / `i128` / pointer / aggregate result types** — the §16.9 width gate
  (null-callee trap). Declines `control flow`.
- **Coherent operands** (`Ry`/phase-carrying, downstream-reused) — the §16.7
  boundary; declines `control flow` under the conservative default until the
  Rule-13 clearance (§8) widens gate 5. The shipped default is conservative.
- **Classical-condition tainted-data `select`** (§16.8) — the
  `declineClassicalMuxes` path; not quantum control, stays declined untouched.
- **Aliasing operands** (§16.9) — an operand sharing the other's post-lowering
  register (hoisted in-place arithmetic). Declines until a fan-out/aliasing
  analysis proves disjointness; the out-of-place `(q>5)?q:q+1` is in scope.
- **Tainted `switch`** — 4.5 (per-case routing / `icmp eq`-flag chain).
- **One-copy degenerate merge** (an operand trivially `\|0⟩`) — a footprint
  optimization; out of scope, always emit two copies for correctness-first
  uniformity.
- **Open question — does the controlled copy want an `_hl` literal twin
  (option B)?** §4/§16.4 default to materialize-then-copy (option A, all-core
  ABI). If the e2e footprint argues for no classical scratch, the
  `cq_template_xor_<W>_hl_controlled` family is the alternative (touches the YAML
  / SHA gate). Resolved at WI-3 against the real linked trace, not assumed.

Each currently declines loudly — a feature, not a gap (Prime Directive).
