# Phase 4.5 IMPLEMENTATION — RSSA swap-routed tainted `switch` (N-way eq-flag routing + const-fold re-anchor)

> **Build companion to PRD Part V (§§19–22).** This document does **not** restate
> the PRD's rationale; it turns the §19 scope, the §20 design decisions, the §20.7
> G0–G11 ladder, and the §21 done-criteria into an executable, modular,
> test-driven engineering plan. Read PRD §§19–22 first; this is the *how*, not the
> *why*. House style mirrors `IMPLEMENTATION-4.4.md` section-for-section (12
> sections: §0 accept criterion · §1 module map · §2 diagnostic helper · §3
> detection/classification · §4 emission · §5 symbol sequences · §6 interlock
> hazards · §7 TDD WI sequence · §8 adversarial verification · §9 done criteria ·
> §10 reuse map · §11 out of scope).

**Verification preamble.** Every cited symbol, line number, and LOC in this plan
was extracted and confirmed against the live tree (branch `swap-route-control`) by
a ground-truth pass on 2026-06-16, then re-confirmed after the first adversarial
review: orchestrator pipeline (`CQLoweringPass.cpp` detect `:83`/`:84`, rotations
`:110`; twin entry `:162`/`:163`/`:169`), the switch decline site
(`ControlDetect.cpp:223–225`), the eq-fold insertion gap (`ArmClassify.cpp:775`,
between the `Base==Routed` block ending `:774` and the leaf-base value path `:778`),
the 4.4 analog sizes (`SelectClassify.cpp` 311, `SelectMergeEmit.cpp` 179,
`emitSelectRegion` body `:82→:177`, `emitRegion` body `:440→:640`, `emitValueRegion`
body `:202→:422` = **221 LOC**), the build list (`ir-pass/CMakeLists.txt:43–71`,
**there is no `ir-pass/src/CMakeLists.txt`**), `WidthDispatch::rzRtFn`
(**confirmed `WidthDispatch.h:86`**, `@cqrt_rz_<W>`), the re-anchor hazard
(`RotationLowering.cpp:197/207/208`), and the New-ABI verdict NONE (every primitive
resolves to an existing symbol). Any item the live tree could not confirm is marked
**"verify at kickoff"** and is wired into §8 / the §22 open-question resolution; a
**conservative decline fixture ships regardless of how a kickoff-deferred predicate
resolves** (over-decline is always safe — Rule 12).

**Corrections vs the PRD's informal cites and the DRAFT.** (1) The PRD writes the
detect/emit window as `:84`; the live `run()` is detect `:83`, emit `:84`, rotations
`:110` (exact). (2) The `ControlDetect` switch decline is `:223–225` (exact). (3) The
eq-fold gap is `:775` (the PRD says "after `Base==Routed` ~`:753`, before the value
path"; the block *ends* at `:774`, so the insertion line is `:775`). (4) **The build
list is `ir-pass/CMakeLists.txt:43–71`** — the DRAFT's `ir-pass/src/CMakeLists.txt`
does not exist (corrected in §1). (5) **`ArmAnalysis.h` is declaration-only; its
function bodies live in `ArmClassify.cpp`** (the header states "the definitions still
live in `ArmClassify.cpp`, only their linkage changed") — there is **no
`ArmAnalysis.cpp`**. Therefore the eq-fold helper goes in a **new compiled TU
`EqFoldArm.cpp`/`.h`**, not `ArmAnalysis.{h,cpp}` (corrected in §1/§3.2). (6)
`rzRtFn` is **confirmed** at `WidthDispatch.h:86` — no longer "verify at kickoff". (7)
A **second independent ground-truth re-verification (2026-06-16)** corrected three stale
cites this preamble first overstated: `emitValueRegion`'s body is `:202→:422` = **221
LOC** (not `:202→:440` = 238 — that span wrongly includes the inter-function
`struct ArmStream` gap; the DRAFT's ~220 was right); `walkValueChain`'s **declaration** is
`ArmAnalysis.h:85` (not `:64`, a comment header — the *body* at `ArmClassify.cpp:262` is
correct); and `findNonDiagonalWireGate`'s first **call** is `ArmClassify.cpp:420` (not
`:418`, which is the enclosing `wireGainsNonDiagonalGate` definition). All three are
line/LOC drift only — none touches a decline string, symbol, signature, or mechanism, and
every correctness anchor (the §5 const-fold re-anchor in `RotationLowering.cpp:189/197/207`,
the §8.5 cswap-arg0 seam in `EmitInverse.cpp:78–79`, the `:223–225` switch decline, the
`:775` eq-fold gap) re-confirmed **exact**.
These are the load-bearing anchors; the implementer keys edits on the surrounding
*code* (the `} else if (auto *SI = dyn_cast<SwitchInst>(Term))` block; the
`if (Routed && Base == Routed)` block), never on the bare line number — stock LLVM
IR / source line drift is real (Rule 9), and the file will shift as edits land.

---

## 0. Accept criterion (the one definition everything keys on)

A tainted `switch` (or an equality-folded `br` diamond) lowers **iff** it passes the
PRD §20.7 **G0–G11** ordered prove-or-decline ladder (for a switch) or the **D1–D7**
additive clause (for an eq-folded diamond), proven **whole, before any mutation**
(Rule 9 / §20.12). Each gate states what it proves and its **exact** decline string;
**gate order is load-bearing** (the FP-fence G4 precedes any width use; the homogeneity
gate G5 precedes the per-class base proof G6 — mirroring `ArmClassify.cpp:820→:834`).
Any miss → loud `diagnoseUnderControl(Where, What)`, **lower nothing** (Prime
Directive: over-decline is always safe; over-accept is the silent miscompile).

**Decline-disposition table** (the §0 contract — every real `-O1` shape and its fate):

| Shape (real `-O1`) | Disposition | Diagnostic `What` |
|---|---|---|
| `switch(q){case c_i: q=cq_phi(q,θ_i)} ` homogeneous phase, empty default | **ACCEPT** → `emitSwitchPhaseRegion` | — |
| `switch(q){case c_i: p=op_i(p)}` homogeneous value chain on `p≠q`, empty default | **ACCEPT** → `emitSwitchValueRegion` | — |
| `switch(q){case c_i: r=v_i; default: r=v_d}` all-`ConstantInt` merge incomings | **ACCEPT** → `emitSwitchDataMuxRegion` | — |
| `if(q==k){q=cq_phi(q,θ)}` / 2-case if/else eq-fold | **ACCEPT** → `emitRegion` (verbatim) via the D-clause | — |
| Scrutinee not tainted | not a region (no diagnostic) | — |
| ≥2 content merge `phi` (multi-phi, C1) | DECLINE | `control flow` |
| Merge result reaches a rotation arg-1 (angle, G3) | DECLINE | `rotation angle` |
| **fp-data** (f64/f32) merge (G4, FP-fence-first) | DECLINE | `control flow` |
| **vector** (`<2 x i32>`) merge (G4, `isFPOrFPVectorTy` on non-scalar) | DECLINE | `control flow` |
| **`i128` / pointer / aggregate** merge (G4, empty `abiWidthFromType`) | DECLINE | `control flow` |
| Mixed arm classes (phase+value in one switch, G5) | DECLINE | `mixed phase/value arm` |
| Non-empty `default:` body (C5, G5) | DECLINE | `control flow` |
| Impure phase spine (stray gate/fan-out, G6) | DECLINE | `impure phase arm` |
| Impure value chain (G6) | DECLINE | `impure value arm` |
| Value arm not bottoming at the merge default-edge incoming (G6/C2) | DECLINE | `value-arm swap-route` |
| Value arm rewrites a scrutinee-read register (§3c, G7) | DECLINE | `arm rewrites a condition operand` |
| ≥2 distinct-base **tainted** data-mux incomings (MUX-EXCH, G8) | DECLINE | `control flow` |
| Grouped fall-through label (≥2 case values → 1 label, C4, G9) | DECLINE | `control flow` |
| Scrutinee an un-owned data use / predates a non-diagonal wire gate (G10) | DECLINE | `condition data use neither escaped nor measured` / `condition predates a non-diagonal gate` |
| Nested tainted `br`/`switch` in a case body (G11) | DECLINE | `control flow` |
| Jump-table fold (`gep`/`load`) | declines **pre-detection** via `declineTaintEscapes` | `cq taint escape: tainted value reaches an unsupported instruction` |
| Eq-fold: icmp literal ≠ spine const (D4) | DECLINE | `control flow` |
| Eq-fold: icmp non-const operand ≠ routed handle (cross-handle, D3) | DECLINE | `control flow` |

> **No new diagnostic strings.** Every `What` above already exists in the dialect
> (`ArmClassify` / `ControlDetect` / `TaintPropagation`). The PRD §20.7 strings are
> all drawn from the shipped vocabulary. **Rule 12 authoring discipline (binding):
> the string a fixture pins is the one that *actually fires* — confirmed by piping a
> real `-O1` `.ll` through the pass and capturing `2>&1`, never copied from this
> table.** The precedent cautionary tale is `control_swap_reject_nested_switch.ll`,
> which pins `control flow` (the **outer** branch declines first), not `switch`.

---

## 1. Module map

**No new TU exceeds 300 LOC — whole-file, overhead included.** The two PRD-named
modules (`SwitchClassify`, `SwitchRouteEmit`) would each blow the budget if monolithic
— the classifier runs a 12-gate ladder per-case + per-merge over N arms (vs
`SelectClassify`'s single-instruction 6 gates → 311 LOC), and the emitter hosts three
full recipes (phase ≈ `emitRegion` body **200 LOC** + value ≈ `emitValueRegion` body
**221 LOC** (`:202→:422`; the `:202→:440` span wrongly swallows the inter-function
`struct ArmStream` gap) + data-mux ≈ `emitSelectRegion` body **96 LOC**
≈ 520 LOC). **Both are split along their natural seams.** Every new TU *calls* an
existing primitive (Rule 14); none re-implements flag mint / copy / route / inverse /
diagnostic.

> **LOC accounting is honest about per-TU overhead.** Each `~LOC` in the table below
> is **whole-file** (not a function-body span). Every compiled TU in this tree carries
> ~30–80 LOC of standard non-body overhead on top of its driver/recipe bodies: the
> license header + includes (~20), `using`/`namespace cq` (~5), the re-derived prefix
> predicates `isPhiCall`/`isThetaCall`/`isCallToPrefix` (~15, TU-local by house style —
> they collide if promoted), and (for emit TUs) the per-TU `scrubTaint` mirror (~14).
> Measured calibration: `SelectClassify.cpp` 311 = ~75 driver + ~147 four walk-helpers +
> ~89 preamble/predicates/namespace; `SelectMergeEmit.cpp` 179 = ~96 body + ~83 overhead.
> The two TUs flagged closest to the budget (`SwitchValueEmit`, `SwitchArmProve`) each
> **pre-commit a contingency split** in their row so the plan does not silently bust 300
> mid-WI. The N-way generalization (loop over cases, per-case LIFO R†) is strictly *more*
> work than the 2-way diamond, never less — so these estimates round **up**, not down.

### New translation units (`ir-pass/src/` + `ir-pass/include/`)

| Module | ~LOC whole-file (cpp / h) | Single responsibility | Mutates IR? | Split rationale / contingency |
|---|---|---|---|---|
| **`SwitchClassify`** | ~250–290 / ~40 | Pure analysis. `classifySwitchRegion(SwitchInst*, TaintSet&, ControlPlan&)`: the G0–G11 ladder *driver* — G0 taint, G1 sole-content-merge-`phi`, G2 flag-mintability, G3 angle BLOCKER (forward arg-1 walk), G4 FP-fence+width, G5 homogeneity+default-identity (**calls `classifyArmContent`**, see reuse note) → **dispatch to the per-class prover**; on whole-switch ACCEPT push the validated region; else `diagnoseUnderControl`. | **No** | ~210 driver body + ~40 per-TU overhead (predicates/includes/namespace) → ~250–290 whole-file, comfortably < 300. G5 homogeneity **reuses** `ArmHomogeneity`'s `classifyArmContent` (Rule 14, §10) rather than re-deriving per-arm class — shrinks the driver and widens the margin. The three per-class **G6 proofs** are split off (next row). |
| **`SwitchArmProve`** | ~215–225 / ~35 | Pure analysis. The G6/G7/G8/G9 per-class base/operand proofs, declared in the new header and called by the driver: `proveSwitchPhase` (each arm-gate arg-0 == its case literal; pure spine; classical θ — ~60), `proveSwitchDataMux` (every incoming `ConstantInt`; `operandsAlias` all-pairs MUX-EXCH G8; one-value-per-label G9 — ~60). **`proveSwitchValue` is the heaviest** (linear chain bottoming at the merge default-edge incoming, `≠ SI->getCondition()` — C2; base disjoint from `q`'s diagonal-alias closure; no non-diagonal wire gate; no Q+Q link; §3c clobber G7). | **No** | Three proofs (~60 each = ~180) + per-TU predicate block (~15) + includes/namespace (~20) ≈ ~215–225 whole-file. **`proveSwitchValue` carries C2 + G7 + Q+Q** and is plausibly ~80–90 LOC. **Contingency (pre-committed):** if the honest total approaches ~280, split `proveSwitchValue` into its own `SwitchValueProve.cpp` (pairs naturally with `SwitchValueEmit.cpp`), leaving `SwitchArmProve` = phase + data-mux proofs only (~120–140). |
| **`SwitchRouteEmit`** | ~190–220 / ~45 | Mutating. `emitSwitchPhaseRegion` (routed base = `q = SI->getCondition()`: per case mint `emitEqFlag` → `\|0⟩` rail → `emitRoute` in → `cqrt_rz` arg-1 only → `emitRoute` back → free rail → `emitEqFlag_inv` strip + free flag; per-case folded-gate scrub; RAUW merge→`q`; N-way flatten) + the per-class **dispatch** (called from `lowerControlRegions`) + the shared per-case folded-gate scrub helper + the N-way flatten call. | **Yes** | Phase recipe ≈ `emitRegion`'s 200-LOC path trimmed to the N-loop (~120) + dispatch + scrub helper (~30) + ~40 per-TU overhead ≈ ~190–220 whole-file, safe under 300. Value and data-mux recipes are split into their own TUs so each emit file stays < 300 and the heaviest (value) is isolated. |
| **`SwitchValueEmit`** | **~280–300** / (decl in `SwitchRouteEmit.h`) | Mutating. `emitSwitchValueRegion`: the N-way method-B — per case rail+`emitRoute` in, verbatim chain replay (`rewriteBinary`), `emitRoute` back, **one** `cqrt_copy_<W>(p,%out)` copy-out, LIFO reverse-play via `emitInverseChain` (**body chain only** — route cswaps bracketed by `emitRoute`, never fed to the inverter; §8.5 seam guard), clean rail frees, strip+free flags, RAUW merge→`%out`, erase chain, N-way flatten. | **Yes** | Calibrated against the **real 221-LOC** `emitValueRegion` body (`:202→:422`) + ~30 per-TU overhead (scrubTaint mirror + includes + namespace); the N-way generalization (loop over cases vs the diamond's fixed 2 arms, manual per-case route-bracket for R†) adds, not subtracts → realistically **~280–300**. **Contingency (pre-committed):** factor the per-case `route-in / replay / route-back / copy-out` single-case step into a free helper `emitSwitchValueCase(...)` so the driver loop stays thin and the file holds under 300 — apply this the moment the body crosses ~250. |
| **`SwitchDataMuxEmit`** | ~130–160 / (decl in `SwitchRouteEmit.h`) | Mutating. `emitSwitchDataMuxRegion`: `%out = cqrt_alloc_<W>(v_d)` preload; per non-default case `emitEqFlag` → `%d_i = cqrt_alloc_<W>(v_i^v_d)` (compile-time XOR-delta) → `copyControlledFn` `cqrt_copy_<W>_controlled(%f_i,%d_i,%out)`; strip+free N flags; RAUW merge→`%out`. No route, no flatten of arms beyond CFG collapse. | **Yes** | ≈ `emitSelectRegion`'s 96-LOC controlled-XOR merge generalized to N (preload + XOR-delta replaces the ¬-bracket) + ~30 overhead ≈ ~130–160 whole-file. Cohesive and small; split from the phase/value emit so each class recipe is independently readable and testable. |

> **Headers live in `ir-pass/include/` only** (zero `.h` in `ir-pass/src/`). New
> `SwitchClassify.h`, `SwitchArmProve.h`, `SwitchRouteEmit.h`, and `EqFoldArm.h` go in
> `include/`; the value/data-mux emitter entry points are declared in
> `SwitchRouteEmit.h` (one header, three `.cpp`). The three emit `.cpp` share the
> per-TU `scrubTaint` mirror (house style — duplicated, not exported; see §2) and the
> `materialize` decision (§4, promote-or-duplicate). **The eq-fold helper
> `tryEqFoldArm` gets its own compiled TU `EqFoldArm.cpp` (+ `EqFoldArm.h`)** — *not*
> `ArmAnalysis.{h,cpp}`, which has **no `.cpp`** (its declarations' bodies live in the
> 1024-LOC `ArmClassify.cpp`). A genuinely-new TU is the only option that actually
> relieves the monolith: `ArmClassify.cpp` grows by only the ~3-line call site, while
> the ~40-LOC helper body lands in `EqFoldArm.cpp` (see the ArmClassify edit row).

### Edits to existing files (thin)

| File | Change | LOC before → after |
|---|---|---|
| `ir-pass/src/ControlDetect.cpp` | **WI-1.** In the terminator dispatch, replace the blanket switch decline (`:223–225`: `} else if (auto *SI = dyn_cast<SwitchInst>(Term)) { if (taint.Tainted.count(SI->getCondition())) diagnoseUnderControl(SI, "switch"); }`) with `classifySwitchRegion(SI, taint, plan);` — keep the `taint.Tainted.count(SI->getCondition())` entry guard. Mirrors exactly how the select scan at `:234–237` calls `classifySelectRegion`. Add `#include "SwitchClassify.h"`. | 243 → ~245 |
| `ir-pass/src/ArmClassify.cpp` | **WI-5.** Insert the **strictly-additive** eq-fold accept clause (D1–D7) at the gap `:775` — *after* the `if (Routed && Base == Routed)` block ends (`:774`) and *before* the leaf-base value path `if (!Routed && !isValueChangingOp(Base))` (`:778`). **Do not weaken** the `:753` `Base==Routed` gate (a real cross-handle mux `if(q>5){t=qx}` must still fall through to decline). Because `classifyArms` is already a ~424-LOC function (`:599–1022`), the inserted clause is the **~3-line call site** `if (tryEqFoldArm(...)) { SawPhaseArm = true; continue; }` — the ~40-LOC helper body lives in the new TU `EqFoldArm.cpp` (next row), so `classifyArms`/`ArmClassify.cpp` does **not** grow materially. | `ArmClassify.cpp` 1024 → ~1027 (call site only) |
| `ir-pass/src/EqFoldArm.cpp` + `ir-pass/include/EqFoldArm.h` | **WI-5. New compiled TU** (declared `EqFoldArm.h`, declaration `tryEqFoldArm(...) -> bool` plus the if/else null-`Routed` anchor helper). Holds the ~40-LOC D1–D7 body; reuses `walkPhaseSpine`/`armBlockIsPureSpine`/`taintedAngleGate` (`ArmAnalysis.h`). **This is the only placement consistent with "spare the monolith"** — `ArmAnalysis.cpp` does **not** exist; a decl in `ArmAnalysis.h` would, by the established convention, land its body in `ArmClassify.cpp` (the file the split was meant to relieve). | new ~70 (cpp) / ~25 (h) |
| `ir-pass/src/SwapRouteEmit.cpp` | **WI-2/3/4.** In `lowerControlRegions` (`:699`), add `if (R.Kind == ControlRegion::SwitchRegion) { emitSwitch...(R, wd, csyms, taint); continue; }` **before** the Depth/child-nest branch — exactly parallel to the `SelectRegion` branch (`:765–773`). The switch dispatch reads the per-class discriminator (§ ControlPlan edit) to pick phase/value/data-mux. Confirm the cross-region pre-flight (`~:727–753`, keys on `Pred/Arm/ArmFalse/MergeBB`) handling of `SwitchArms[].Block` (see §6.4 / open-question resolution). | 789 → ~800 |
| `ir-pass/include/ControlPlan.h` | **WI-1.** **Reuse** the already-defined `Kind=SwitchRegion` (`:119–124`) + `struct SwitchArm{Values,Block,Shadow}` (`:64–68`) + `SwitchArms` (`:186`) + `SwitchDefaultDirect` (`:196`). **Add one** per-class discriminator field on `ControlRegion` — recommended `enum SwitchKind { Phase, Value, DataMux } SwitchClass;` (mirroring how `ClassArm`/`ClassArmFalse` discriminate within `BranchRegion`). **Do NOT add three top-level `Kind` enumerators** (`SwitchPhase`/`SwitchValue`/`SwitchDataMux`) — that diverges from the shipped one-`SelectRegion`-kind pattern. Re-verify/repurpose `MuxExch` (G8 bookkeeping). | 309 → ~315 (header; data shapes, not a compiled-`.cpp` split target) |
| `ir-pass/src/CQLoweringPass.cpp` | **WI-2.** **No new orchestrator step.** The dispatch is inside `lowerControlRegions` (already called at `run():84` and `runOnFunction():163`), so both entry points inherit it (twin-pipeline trap avoided). The only new obligation: the per-case folded-gate scrub happens *inside* the emit (before `RotationLowering` at `:110`/`:169`), owned by `SwitchRouteEmit`. Document the inherited position in the file comment near `:80`. | 179 → ~182 (comment only) |
| `ir-pass/CMakeLists.txt` (**`:43–71`**, the `add_library(CQPass MODULE …)` list — **there is no `ir-pass/src/CMakeLists.txt`**) | **WI-1/2/3/4/5.** Add `src/SwitchClassify.cpp`, `src/SwitchArmProve.cpp`, `src/SwitchRouteEmit.cpp`, `src/SwitchValueEmit.cpp`, `src/SwitchDataMuxEmit.cpp`, `src/EqFoldArm.cpp` by name (no glob — a forgotten file silently drops from `libCQPass.so` until a link-time undefined symbol; this is exactly the footgun the wrong path would invite). Headers in `ir-pass/include/` need no listing (picked up via `target_include_directories` at `:73–75`). | — |
| `tests/e2e/CMakeLists.txt` + 4 new slices | **WI-6.** Four `add_test` blocks (e2e is **not** auto-globbed) for `slice_control_switch_{phase,value,datamux,eqfold}` — copy the `e2e-slice-control-select` block verbatim and rename. | — |

> **`ChainWalk.cpp` / `FreePoint.cpp` / `Uncomputation.cpp` — NO CHANGE** (verified
> against source). `isDataProducer` excludes `_controlled` (`Uncomputation.cpp:65`);
> `isStep2Emittable` bails on `_controlled` (`:104–105`); `FlagImage` skips control
> flags; `isInPlaceGateOn` excludes `cqrt_x`/`cqrt_cswap` (`ChainWalk.cpp:46–54`).
> The N `cqrt_copy_<W>_controlled` copies are N legitimate consumers of the live
> `%out`; the rails / `%out` / delta scratch are left allocated (benign classical
> leak, Rule 6). **Caveat (verify at kickoff, §6.7):** `isDataProducer` *does*
> accept `cqrt_alloc_`, so `%out` is safe only because `isTerminalHandle` rejects it
> (it has ≥1 non-benign controlled-copy consumer) — a §8 probe must assert `%out`
> always has such a consumer.

**Pipeline position (inherited, both entry points):**

```
 L47  propagate                  taint built ONCE (pre-RAUW SSA identity holds to L84/L110)
 L64  declineTaintEscapes        jump-table gep/load declines HERE (kMsgOther), BEFORE switch detect
 L71  declineStaleRecordOps
 L83  detectControlRegions       <-- 4.5 SWITCH DETECT HOOK (classifySwitchRegion replaces :225 decline)
 L84  lowerControlRegions        <-- 4.5 SWITCH EMIT HOOK (emitSwitch{Phase,Value,DataMux}Region);
                                     per-case folded-gate scrub happens INSIDE here, before L110
 L96  declineClassicalMuxes      must NOT see a surviving tainted-reading merge phi (emitter RAUWs+scrubs it)
 L106 declineLiftedStaleRecordOps
 L110 lowerRotations             ANY surviving folded cq_phi(c_i,θ) RAUWs to const c_i -> wrong data-mux (BLOCKER)
 L111 lowerOps  L112 lowerMeasures  L115 uncompute (Phase 5, LAST)
 (twin entry runOnFunction: detect :162, emit :163, declineClassicalMuxes :166, rotations :169, uncompute :174)
```

---

## 2. Shared diagnostic helper

Unchanged — `diagnoseUnderControl(Instruction *Where, StringRef What)`
(`ControlPlan.h:292`, defined `ControlDetect.cpp:46–51`), rendering
`cq controlled lowering: <What> under quantum control` as
`DiagnosticInfoUnsupported(DS_Error)` with the offending instruction's `!dbg`, so
`opt` exits non-zero. **4.5 introduces ZERO new `What` strings** — every G0–G11 /
D1–D7 decline reuses the shipped vocabulary (`control flow`, `rotation angle`,
`mixed phase/value arm`, `impure phase arm`, `impure value arm`,
`value-arm swap-route`, `arm rewrites a condition operand`,
`condition data use neither escaped nor measured`,
`condition predates a non-diagonal gate`). The jump-table decline fires earlier in a
**different** dialect — `cq taint escape: …` from `declineTaintEscapes`
(`TaintPropagation.cpp`, `kMsgOther`) — and is not a switch-detector concern.

**Anchor choice (binding):** switch declines anchor on the `SwitchInst` (its `!dbg`);
eq-fold declines anchor on the offending arm instruction / `declAnchor(Region)` as
`ArmClassify` already does. **scrubTaint** is duplicated per emit TU
(`SwitchRouteEmit.cpp`, `SwitchValueEmit.cpp`, `SwitchDataMuxEmit.cpp`) as a
file-local mirror of `SwapRouteEmit::scrubTaint` (`:60–74`) — the house style for
trivial taint-set maintenance (it is currently anon-ns in `SwapRouteEmit.cpp`, not
exported; **decide promote-vs-duplicate at kickoff** — precedent: `emitRoute`/
`collectArmPhis` were de-anonymized into the `cq` namespace and declared in
`SwapRouteEmit.h` for `NestedRouteEmit` reuse; the lighter-touch choice is to
duplicate, matching `RegionFlatten`'s own mirror). It **must** clear
`Tainted`/`BirthOrder`/`StaleDeclined` and remove the `CallInst` from `PhiCalls`
(idiom: `auto &PC = taint.PhiCalls; PC.erase(std::remove(PC.begin(), PC.end(), CI),
PC.end());`, needs `<algorithm>`) and be called **before** `eraseFromParent()`
(§6.1 dangling-work-list SIGSEGV).

---

## 3. Detection & classification (pure analysis, before any mutation — Rule 9)

`classifySwitchRegion` (driver in `SwitchClassify.cpp`) runs G0–G11 in order, proving
the **whole switch — all cases, the merge, the default — before `SwitchRouteEmit`
mutates one instruction** (§20.12; the N-loop half-mutated-module hazard). Detection
is pure SSA-value identity, so it survives `RotationLowering`'s later RAUW-to-`i32`.
No block-pointer caching across erasures (there are no erasures in this TU).

```text
classifySwitchRegion(SI, taint, plan):
  G0  if !taint.Tainted.count(SI->getCondition()): return            // not a region
  q = SI->getCondition()
  G1  phi = soleContentMergePhi(SI)        // exactly ONE non-angle non-identity merge phi
      if !phi: decline(SI, "control flow")                            // multi-phi C1
  G2  for c_i in SI->cases(): if !flagMintable(q, c_i): decline(SI, "control flow")
  G3  if mergeReachesRotationArg1(phi): decline(SI, "rotation angle")  // the BLOCKER, no backstop
  G4  T = phi->getType()
      if T->isFPOrFPVectorTy() || !T->isIntegerTy() || abiWidthFromType(T).empty():
          decline(SI, "control flow")                                 // FP-fence FIRST
  G5  cls = homogeneousClassOrDecline(SI, phi)   // {Phase,Value,DataMux} all-cases+default
      // + default identity: default incoming == straight-through value
      if mixed: decline(SI, "mixed phase/value arm")
      if nonEmptyDefault: decline(SI, "control flow")                 // C5
  G6  switch cls:
        Phase:   if !proveSwitchPhase(SI, phi, taint): decline(...)    // strings per row
        Value:   if !proveSwitchValue(SI, phi, taint): decline(...)    // incl G7 §3c, C2 anchor
        DataMux: if !proveSwitchDataMux(SI, phi, taint): decline(...)  // incl G8 MUX-EXCH, G9
  G9  if anyLabelReachedByMultipleValues(SI): decline(SI, "control flow")  // C4 (also checked in proveDataMux)
  G10 if scrutineeIsUnownedDataUse(q, taint) || predatesNonDiagonalGate(q, taint):
          decline(SI, "<the matching G10 string>")
  G11 for case bb in SI: if hostsTaintedBranch(bb, taint): decline(SI, "control flow")
  // ACCEPT — whole switch proven:
  ControlRegion R; R.Kind = ControlRegion::SwitchRegion; R.SwitchClass = cls;
  R.Condition = q; R.Merge = phi; populate R.SwitchArms (Values, Block, folded gate in Shadow);
  R.SwitchDefaultDirect = true; plan.Regions.push_back(R);
```

### 3.1 The G0–G11 ladder mapped to concrete functions/helpers

Each gate names its concrete function and the **reused** helper (real signatures from
the ground-truth pass; never invent an API). Items the live tree could not confirm
are marked **verify at kickoff**.

| Gate | Function (TU) | Reused helper(s) + real signature | Decline string |
|---|---|---|---|
| **G0** | driver | `taint.Tainted.count(SI->getCondition())` | — |
| **G1** | `soleContentMergePhi` (SwitchClassify) | model on `soleMergePhi(BasicBlock*)` (`ControlDetect.cpp:74–84`, returns sole 2-incoming merge phi or null) — **generalize to N incomings + skip identity-only second `phi`s**; the RAUW-collapse predicate for identity-only phis is **verify at kickoff** (open-Q 1; v1 floor: any 2nd content phi ⇒ decline) | `control flow` |
| **G2** | `flagMintable` (SwitchClassify) | `emitEqFlag(Value*, ConstantInt*, WidthDispatch&, bool inverse, Instruction* before) -> Value*` (`CompareLowering.cpp:220`) — but **at classify time call a non-mutating mintability probe**: `abiWidthFromType(c_i->getType())` non-empty + supported, not Q+Q. **emitEqFlag itself is mutating (it builds the call)** — do NOT call it in the classifier; replicate its width gate. Verify at kickoff that `abiWidthFromType` is the exact check `emitEqFlag` uses for null-return parity (open-Q 5; the emit-time symbol CHECKs in the WI-2 positive gate this for parity — see §7). | `control flow` |
| **G3** | `mergeReachesRotationArg1` (SwitchClassify, the BLOCKER) | **new forward arg-1 walk**, modeled verbatim on `selReachesRotationArg1(SelectInst*) -> bool` (`SelectClassify.cpp`): forward worklist through value-preserving carriers (`FPExtInst`/`FPTruncInst`/`BitCastInst`/`PHINode`/nested value-operand) to a `cq_phi_`/`cq_theta_` call at arg index 1 (`CI->getArgOperand(1)==U && CI->getArgOperand(0)!=U`). Seed = the merge `phi`. **No downstream backstop** (`declineTaintedAngle` runs at `:110`, after the emitter RAUWs the merge to an untainted handle). | `rotation angle` |
| **G4** | driver | `abiWidthFromType(Type*) -> StringRef` (`OpcodeSupport.cpp:148`); FP-fence `T->isFPOrFPVectorTy()` (the f64 trap: f64 has a valid width yet is an angle — fence **first**, never key on non-empty width alone) | `control flow` |
| **G5** | `homogeneousClassOrDecline` (SwitchClassify) | per-case class read via **`classifyArmContent(BasicBlock*, Value*) -> ArmContent` (`ArmHomogeneity.cpp:66`)** — the §12.5 PASS-1 per-arm split already built for the 4.3 nest (Rule 14; do **not** re-derive). NB `classifyArmContent`/`ArmContent`/`isValueChangingOp` (`:49`) are currently **TU-local** in `ArmHomogeneity.cpp` (only `treeHomogeneous` is exported in `ArmHomogeneity.h`); **de-anonymize `classifyArmContent`+`ArmContent` into the `cq` namespace and declare in `ArmHomogeneity.h`** (precedent: `emitRoute`/`collectArmPhis`) so `SwitchClassify` can call them — confirm the signature/semantics fit a switch case block at kickoff (open-Q 8). Default identity = default incoming is the straight-through value. | `mixed phase/value arm` / `control flow` |
| **G6 Phase** | `proveSwitchPhase` (SwitchArmProve) | per arm: `walkPhaseSpine` bottoms at `c_i` (the folded const), each folded `cq_phi` arg-0 == its case literal, `armBlockIsPureSpine(const BasicBlock*, const Value*) -> bool` (`ArmClassify.cpp:118`), `taintedAngleGate(Value*, const BasicBlock*, Value*, TaintSet&) -> CallInst*` (`ArmClassify.cpp:360`, returns first tainted-arg1 gate or null) | `impure phase arm` / `rotation angle` / `control flow` |
| **G6 Value** | `proveSwitchValue` (SwitchArmProve) | `walkValueChain(Value* ArmIncoming, const BasicBlock*, TaintSet&, Value* RoutedHint) -> ValueChain` (`ArmClassify.cpp:262`); `valueArmIsPureChain(const BasicBlock*, ArrayRef<Instruction*>, const PHINode*) -> bool` (`ArmClassify.cpp:314`); **C2 anchor (deepest hazard):** assert each arm's chain bottoms at the merge **default-edge** incoming `p` and `p != SI->getCondition()`; `findNonDiagonalWireGate` (WireWalk.h, called `ArmClassify.cpp:420/928`) | `impure value arm` / `value-arm swap-route` |
| **G7** | inside `proveSwitchValue` | §3c clobber: `condProvenance(Value*, TaintSet&, SmallPtrSetImpl<Value*>&)` (`ArmClassify.cpp:173`) seeds the scrutinee-read set; `diagonalAliasHit(Value* Routed, const SmallPtrSetImpl<Value*>&) -> Value*` (`ArmClassify.cpp:219`) — a value arm rewriting a scrutinee-read register declines | `arm rewrites a condition operand` |
| **G8** | inside `proveSwitchDataMux` | all incomings `ConstantInt`; `operandsAlias(Value*, Value*) -> bool` (model on `SelectClassify.cpp`'s diagonal-alias closure) all-pairs over distinct-base **tainted** incomings = MUX-EXCH | `control flow` |
| **G9** | `anyLabelReachedByMultipleValues` (SwitchClassify) | walk `SI->cases()` grouping by `getCaseSuccessor()`; ≥2 values → 1 label declines (`SwitchArm.Values` is `SmallVector<ConstantInt*,2>` and *could* hold groups, but v1 declines) | `control flow` |
| **G10** | `scrutineeIsUnownedDataUse` / `predatesNonDiagonalGate` (SwitchClassify) | reuse the FreePoint/WireWalk data-use discipline; **verify at kickoff** the exact predicate (the select analog has no terminator condition; the switch scrutinee is a raw integer). Conservative v1: decline any scrutinee with a non-diagonal forward wire gate. | `condition data use neither escaped nor measured` / `condition predates a non-diagonal gate` |
| **G11** | `hostsTaintedBranch` (SwitchClassify) | per case block: a tainted `BranchInst`/`SwitchInst` terminator deeper than the 4.3 nest declines | `control flow` |

### 3.2 The equality-folded `br` diamond — the additive `classifyArms` clause (D1–D7)

This is **detection-only** (the emitter reuses `emitRegion` verbatim). The gap:
`classifyArms` declines an eq-folded diamond because `walkPhaseSpine` bottoms at the
const-folded `ConstantInt k` instead of the routed handle. The fix is a **strictly-
additive** clause inserted at `ArmClassify.cpp:775` (between the `Base==Routed` block
end `:774` and the leaf-base value path `:778`), with the body extracted into the
**new compiled TU `EqFoldArm.cpp`** (declared `EqFoldArm.h`) — **not**
`ArmAnalysis.{h,cpp}`, which has no `.cpp` (a decl there would put the body back in
`ArmClassify.cpp`, defeating the split):

```text
tryEqFoldArm(Region, ArmBB, ArmIncoming, Base, Routed, Cond, Taint) -> bool:
  D1  Cond = dyn_cast<CmpInst>(Region.Condition); require Cond && Cond->isEquality()  // ICMP_EQ/NE
  D2  spine base is a ConstantInt k  (walkPhaseSpine bottomed at k, NOT a handle)
  D3  Cond operands == { RoutedTaintedHandle, C }; the non-const operand IS the routed
      tainted handle  (cross-handle mismatch -> return false -> falls to value path -> decline "control flow")
  D4  C == k  by APInt/width equality  (literal mismatch -> false -> decline "control flow")
  D5  the routed operand is taint.Tainted  (classical -> false)
  D6  armBlockIsPureSpine(ArmBB, ArmIncoming)   // reuse ArmClassify.cpp:118
  D7  taintedAngleGate(ArmIncoming, ArmBB, Base, Taint) == nullptr  // reuse :360
  on all-pass: anchor Routed = the icmp's non-constant tainted operand; SawPhaseArm=true; return true
```

In `classifyArms`, the inserted clause is exactly the **~3-line call site**
`if (tryEqFoldArm(Region, ArmBB, ArmIncoming, Base, Routed, Cond, Taint)) {
SawPhaseArm = true; continue; }` — **after** the `Base==Routed` gate, **before** the
value path; the helper body lives in `EqFoldArm.cpp`, so `classifyArms` does not grow
materially. The if/else null-`Routed`-from-icmp anchor (D: when `Routed` is unset and
the arm bottoms at a const, set `Routed` = the icmp's non-const tainted operand) is
the helper's job too, gated D1+D5. **Do not double-set `Routed`** if the existing
if/else path already set it (open-Q 3 — verify both clang arm orderings converge).

---

## 4. Emission — the four recipes as ordered emit steps

Symbol **order is the contract** (a mis-ordered N-way emit yields the identical symbol
*multiset* — caught only by `ORD`+`XCT` FileCheck, §5/§7). `ControlledSymbols
csyms(M, wd)` is constructed once in `lowerControlRegions` (`SwapRouteEmit.cpp:755`)
and threaded in. Width is read via `abiWidthFromType(node->getType())` at emit time
(pre-RAUW; emit precedes `RotationLowering`). Every emitted handle that downstream must
treat as a quantum handle is inserted into `taint.Tainted` with a fresh
`BirthOrder[h] = taint.NextBirth++`.

### 4A. `emitSwitchPhaseRegion` (routed base = `q = SI->getCondition()`)

Per case `i` (generalizing `emitRegion`'s phase path, **zero controlled gates beyond
route cswaps**):

1. **Mint flag** — `Value *f_i = emitEqFlag(q, c_i, wd, /*inverse=*/false, before)`
   (`CompareLowering.cpp:220`) → `cq_template_icmp_eq_<Wq>_hl(q, c_i)`. Null ⇒ already
   declined at G2.
2. **Alloc rail** — `B.CreateCall(wd.allocFn(Abi), {Constant::getNullValue(RailTy)})`
   → `cqrt_alloc_<W>(0)` = `\|0⟩` rail `r_i`. (`wd.allocFn(StringRef) -> FunctionCallee`,
   `WidthDispatch.cpp:107`.)
3. **Route-in** — `emitRoute(B, csyms, f_i, q, r_i, /*Negated=*/false, DL)`
   (`SwapRouteEmit.cpp:684`) → `cqrt_cswap(f_i, q, r_i)`. Eq-flags are positive-
   polarity (mutually exclusive) — `Negated=false`, no `¬`-bracket (§20.1).
4. **Replay** — `B.CreateCall(wd.rzRtFn(Abi), {r_i, foldedGate->getArgOperand(1)})`
   → `cqrt_rz_<W>(r_i, θ_i)` — **arg-1 only**; the folded gate's arg-0 (`c_i`) is
   discarded (re-anchor by physics, NO RAUW of arg-0; §5). (`WidthDispatch::rzRtFn(
   StringRef) -> FunctionCallee` → `@cqrt_rz_<W>`, **confirmed `WidthDispatch.h:86`**.)
5. **Route-back** — `emitRoute(B, csyms, f_i, q, r_i, false, DL)` (join = adjoint of
   split; cswap is self-inverse).
6. **Free rail** — `B.CreateCall(wd.freeFn(), {r_i})` → `cqrt_free(r_i)`; provably
   `\|0⟩` (`Rz\|0⟩=\|0⟩` off-branch, basis-permutation roundtrip on-branch). (`wd.freeFn()
   -> FunctionCallee`, `WidthDispatch.cpp:257`.)
7. **Strip + free flag** — `emitEqFlag(q, c_i, wd, /*inverse=*/true, before)` →
   `cq_template_icmp_eq_<Wq>_hl_inv(q, c_i)`; then `cqrt_free(f_i)`.

After the N-loop: **scrub+erase each folded `cq_phi(c_i,θ_i)`** (the re-anchor scrub,
§5) → RAUW the merge `phi` → `q` → `flattenRegion` the N-way CFG. `q` never freed.

### 4B. `emitSwitchValueRegion` (routed base = `p` = merge default-edge incoming, ≠ q)

Generalizes `emitValueRegion` (method-B). Per case: mint `f_i`, `\|0⟩` rail `r_i`,
`emitRoute(B, csyms, f_i, p, r_i, false, DL)` route-in, run the chain `op_i` verbatim
on `r_i` (`rewriteBinary`), `emitRoute` back (exactly one settles on `p`). Then:

1. **One uncontrolled copy-out** — `B.CreateCall(wd.copyFn(Abi), {p, out})` →
   `cqrt_copy_<W>(p, out)` (answer on `p` only at this point). (`wd.copyFn(StringRef) ->
   FunctionCallee`, `WidthDispatch.cpp:119`, integer-guarded, no `_inv` twin.)
2. **Reverse-play (LIFO)** — for each case in reverse: `emitRoute` route-in (manual
   bracket), `emitInverseChain(B, A.Fwd, wd, csyms, /*Flag=*/nullptr, /*Terminal=*/
   chainFinal)` → replays the **body chain only** (`_inv` twins + negated rz), `emitRoute`
   route-back. **CRITICAL SEAM (§8.5):** never feed the route cswaps to
   `emitInverseChain` — `emitInverseCall` threads `CurHandle` into `Args[0]`, which for
   `cqrt_cswap` is the **flag** slot = verify-clean wrong unitary (`EmitInverse.cpp:76–84`).
   Bracket route cswaps yourself with `emitRoute` (cswap self-inverse), exactly as
   `emitValueRegion` does at `SwapRouteEmit.cpp:374`.
3. **Free rails** on the final threaded handle (`cqrt_free`); strip+free flags
   (`emitEqFlag_inv`).

RAUW merge → `%out`; erase the chain; `flattenRegion`. **`p` and `%out` never freed** —
`p` is restored to `p₀` and left live (no-cloning never arises, Rule 8); `%out` is the
live result.

### 4C. `emitSwitchDataMuxRegion` (preload + XOR-delta, no route, no `¬`-bracket)

1. **Preload** — `%out = cqrt_alloc_<W>(v_d)` (the default literal):
   `B.CreateCall(wd.allocFn(Abi), {v_d})`.
2. Per non-default case `i`:
   a. `%f_i = emitEqFlag(q, c_i, wd, false, before)`.
   b. `%d_i = cqrt_alloc_<W>(v_i ^ v_d)` — the XOR-delta, a **compile-time constant**
      (`ConstantInt::get(RailTy, v_i->getValue() ^ v_d->getValue())`), materialized via
      `wd.allocFn(Abi)` (or `materialize` — see promote/duplicate note below).
   c. `%g_i = copyControlledFn(Abi)` → `cqrt_copy_<W>_controlled(%f_i, %d_i, %out)`
      (`out ^= f_i ? d_i : 0`). (`csyms.copyControlledFn(StringRef) -> FunctionCallee`,
      `ControlledSymbols.cpp:120`; integer-guarded, null ⇒ decline; flag arg-0, src
      arg-1, dst arg-2.)
3. **Strip + free all N flags** — `emitEqFlag(q, c_i, wd, true, before)` then
   `cqrt_free(%f_i)` (each strip reads pristine `q`).

RAUW merge → `%out`. Distinct literals ⇒ at most one `f_i=1` ⇒
`out = v_d ⊕ (v_k⊕v_d) = v_k`; default fires no copy ⇒ `out = v_d`. **No
`FlagConjunction` `¬OR` ancilla** (the default is the preload). `%out`, `q`, and each
delta scratch `%d_i` left allocated (benign classical leak; `%d_i` left **untainted**
so uncompute never selects it — confirm it does not enter `BirthOrder`, open-Q 6).

> **`materialize` promote-or-duplicate (binding decision at kickoff).** `materialize(
> Value*, FunctionCallee Alloc, const TaintSet&, IRBuilder<>&, const DebugLoc&) ->
> Value*` is **file-local static** in `SelectMergeEmit.cpp:70` (not exported). The
> data-mux delta-scratch alloc needs the same `cqrt_alloc_<W>(v)` materialize. Either
> (a) de-anonymize it into a shared header (precedent: `emitRoute`), or (b)
> re-implement the trivial alloc inline in `SwitchDataMuxEmit` (matches the per-TU-
> duplicate house style). **Recommend (b)** — the delta alloc is a one-liner
> `B.CreateCall(wd.allocFn(Abi), {delta})`; promoting `materialize` for one call site
> is not worth the cross-TU coupling.

### 4D. Equality-folded diamond — `emitRegion` (+ a one-line re-anchor for the if/else)

Once `tryEqFoldArm` accepts (§3.2), the region is a normal `ControlRegion` and
`emitRegion` (`SwapRouteEmit.cpp:440`) replays arg-1 θ on the rail exactly as the
inequality diamond does (re-anchor BY PHYSICS — only the angle is read, the folded
arg-0 constant is discarded), and `flattenRegion` reuses verbatim
(`RegionFlatten.cpp:45`).

> **CORRECTION (WI-5 implementation, 2026-06-17).** The DRAFT claim "**no new emit
> code**" held only for the eq-fold **diamond**, **not** the **if/else**. A diamond's
> routed handle `Q` is the Pred-edge merge incoming (`= q`, always correct). But an
> if/else has **no** Pred-edge incoming, so `emitRegion` derives `Q` via
> `phaseSpineBase(R.Arm)` — which on the `q==k`(true) arm **bottoms at the folded
> constant `k`** and would route a CONSTANT into `cqrt_cswap` and RAUW the merge to
> `k` (a verify-clean wrong unitary, caught only accidentally by the `cq_measure`
> operand guard; an escaping/`ret` merge would miscompile silently — reproduced as
> `cq_measure(7)`). This is the eq-fold analog of the §5 switch const-fold re-anchor,
> which §4D missed. **Fix:** a gated field `ControlRegion::RoutedBase`
> (`ControlPlan.h`) — `tryEqFoldArm` records the icmp's non-constant tainted operand
> on accept, and `emitRegion`'s `Q`-derivation **prefers** `R.RoutedBase`.
> `RoutedBase` is null for every non-eq-fold region, so the default
> Pred-edge/`phaseSpineBase` path is byte-identical there (zero regression; full
> suite green). The accept gates that make this safe are **D4** (icmp literal ==
> folded const, by `APInt`+width — rejects the `if(q==7){x=9}` data-mux that would
> else RAUW the merge to `q` and drop the mux) and **D3** (icmp non-const operand ==
> routed handle — rejects the cross-handle mux). Cleared by a 20-probe independent
> adversarial review (no silent miscompile, no regression). See bd
> `4-5-wi5-eqfold-routedbase-reanchor`.

---

## 5. The equality const-fold RE-ANCHOR + per-case folded-gate SCRUB

**The KEY new mechanism (BLOCKER-class, no downstream backstop).** `clang -O1`
const-folds each surviving phase case arm's gate to `cq_phi(i32 c_i, θ_i)` — **arg-0 is
the case literal `c_i`, not the scrutinee handle `q`**. If such a folded gate survives to
`RotationLowering` (`CQLoweringPass.cpp:110`):

- `RotationLowering.cpp:197` checks `taint.Tainted.count(Op)` where `Op = arg-0 = c_i`
  (a `ConstantInt`, **not** tainted) → **no `rz` emitted**;
- `:207` `Phi->replaceAllUsesWith(Op)` RAUWs the gate result to the constant `c_i`;
- `:208` queues it for erase.

Result: the merge `phi` degenerates into `select(q==c_i, c_i, q)` — a **verify-clean
wrong data-mux**. There is **no backstop** (`declineTaintedAngle` runs at `:110`, after
the emitter has RAUW'd the merge to an untainted handle, so `taint.Tainted.count(arg1)`
is already false).

**The two-part fix, owned by `emitSwitchPhaseRegion`, executed *during* emit (inside
`lowerControlRegions` at `:84`, before `RotationLowering` at `:110`):**

1. **Re-anchor by physics.** Step 4 emits `cqrt_rz_<W>(r_i, foldedGate->getArgOperand(1))`
   reading **only arg-1** — the angle. Arg-0 (`c_i`) is discarded; **no RAUW of the
   folded operand**. The phase is carried onto the routed rail `r_i`, not onto the
   constant.

2. **Per-case scrub+erase the folded gate BEFORE `RotationLowering`.** For each folded
   `cq_phi(c_i, θ_i)`: `scrubTaint(foldedGate, taint)` (which removes it from
   `taint.PhiCalls` via the `std::remove` idiom — the exact `SwapRouteEmit::scrubTaint`
   `:60–74` precedent), **then** `foldedGate->eraseFromParent()`. This guarantees no
   folded gate reaches `:110` to trigger the RAUW-to-const degeneration.

**Exact insertion point in `CQLoweringPass::run()`:** **none new.** The scrub/erase
happens inside `emitSwitchPhaseRegion`, which is dispatched from `lowerControlRegions`
(called `run():84`, `runOnFunction():163`). Because the scrub is *inside* the emit, it
is automatically ordered between detect (`:83`/`:162`) and `lowerRotations`
(`:110`/`:169`) **in both entry points** — no orchestrator edit, twin-pipeline trap
avoided. (The only `CQLoweringPass.cpp` change is a clarifying comment.)

**PhiCalls entry removal.** `taint.PhiCalls` is `SmallVector<CallInst*,8>`
(`TaintPropagation.h:45`), collected unconditionally for *every* `cq_phi`
(`TaintPropagation.cpp:112–113`) precisely so the lowering can delete it. The folded
gate's entry is removed by `scrubTaint` (`PC.erase(std::remove(PC.begin(), PC.end(),
foldedGate), PC.end())`). If this entry is **not** removed, a later module walk
dereferences freed memory (§6.1 SIGSEGV).

**No-block-pointer-caching discipline (§20.12).** The phase emitter and the N-way
flatten **capture all block/value identities before the first erase** — the folded-gate
scrub erases call instructions (not blocks), but the subsequent N-way `flattenRegion`
erases case blocks; capture `SwitchInst` + all `SwitchArm.Block` + the merge block into
local `SmallVector`s **before** the first `eraseFromParent`, then erase in a fixed order
(model the capture-then-erase on `flattenRegionTree`, `RegionFlatten.cpp:91–175`). Never
re-read a block pointer after an erase.

---

## 6. Interlock hazards (Rule 10 / Rule 13 — the silent-miscompile surface)

Each is verify-clean-invisible and carries its own probe (§8). Numbered for the §8
clearance lenses.

1. **Dangling work-list SIGSEGV.** Erasing a folded gate / chain instruction without
   `scrubTaint` first leaves a freed pointer in `Tainted`/`BirthOrder`/`StaleDeclined`/
   `PhiCalls`; a later module walk (`lowerOps`/`uncompute`) derefs it. **Probe:** a
   3-case phase fixture + an ASan/valgrind-equivalent reasoning pass; FileCheck that the
   folded `cq_phi` is gone and no `phi i32` survives.

2. **Const-fold re-anchor (§5, BLOCKER).** A surviving folded `cq_phi(c_i,θ)` → wrong
   data-mux. **Probe:** `control_swap_switch_phase.ll` must `CHECK-NOT: cq_phi` and
   `CHECK-NOT: phi i32`, and pin `cqrt_rz_<W>` reading the rail (not `q`, not a const).

3. **Mis-ordered N-way emit (identical multiset).** A reordered or unbalanced N-way
   stream produces the same symbol *count* — `ORD` (ordered CHECKs) + `XCT`
   (`CHECK-COUNT-N` per flag/rail/free with a `-NOT` guard) catch it; a count-only CHECK
   does not. **Probe:** `control_swap_switch_phase.ll` `ORD` pins
   `eq → cswap → rz → cswap → free(rail) → eq_inv → free(flag)` per case; `XCT` pins
   exactly N rails freed and N flags freed.

4. **SwitchRegion vs the cross-region pre-flight block guard.** The pre-flight aliasing
   loop (`SwapRouteEmit.cpp:~727–753`) keys on `Pred/Arm/ArmFalse/MergeBB`. A
   `SelectRegion` is inert (all-null block fields). A `SwitchRegion` **populates**
   `SwitchArms[].Block` and the merge — **decide at kickoff** whether to (a) leave case
   blocks out of the pre-flight (treat the switch like select — its merge is the only
   shared block) or (b) extend the pre-flight to cover `SwitchArms[].Block`. **Probe:** a
   switch whose merge is another region's predecessor (block-lifetime) — must not
   SIGSEGV or silently mis-flatten.

5. **Value-arm routed-base mis-anchor (C2, deepest — the PRD's named-deepest hazard).**
   Routing `q` (instead of `p` = the merge default-edge incoming) into the rails is a
   self-inflicted §3c clobber + wrong unitary. **Probe (Rule-12 fixture, not an assert):**
   the dedicated WI-3 negative `control_swap_reject_switch_value_swaproute.ll` — a value
   switch whose chain bottoms at a **non**-default-edge incoming (or whose routed base
   would resolve to `q`), pinned `CHECK: error{{.*}}value-arm swap-route under quantum
   control` (string captured from a real `-O1` run; this is the **only** §0 row carrying
   the `value-arm swap-route` string, and it had no fixture in the DRAFT). The in-code
   `proveSwitchValue` assertion `valueChainBase(arm) == defaultEdgeIncoming && !=
   SI->getCondition()` is kept as **defense-in-depth**, **not** counted as the probe — it
   is `assert`-compiled-out under `-DCMAKE_BUILD_TYPE=Release` and cannot be pinned by
   `RUN: not … | FileCheck`. The separate `case 1: q=q+1` G7 fixture
   (`control_swap_reject_switch_value_clobber.ll`) exercises a **different** predicate
   (`arm rewrites a condition operand`), not C2.

6. **EmitInverse cswap-arg0 seam (§8.5).** Feeding a route cswap to `emitInverseChain`
   threads a rail handle into the flag slot. **Probe:** the value fixture pins the R†
   stream is the body chain only (`_inv` twins), with route cswaps bracketed separately
   — a `XCT` count of `cqrt_cswap` that excludes the inverter region.

7. **`%out` accidental uncompute selection.** `isDataProducer` accepts `cqrt_alloc_`, so
   `%out` is safe only because `isTerminalHandle` rejects it (≥1 non-benign controlled-
   copy consumer). **Probe:** a §8 assertion + a data-mux fixture confirming `%out` has a
   `cqrt_copy_<W>_controlled` consumer and is never freed; uncompute emits nothing for it.

8. **Jump-table pre-emption.** A data-mux clang folds to `gep`/`load` declines via
   `declineTaintEscapes` (`kMsgOther`) at `:64`, **before** switch detection. **Probe
   (two fixtures, both required):** (i) a dedicated WI-1 **negative**
   `control_swap_reject_switch_jumptable.ll` — a many-case data switch that `clang -O1`
   actually folds to a `switch.table` `gep`/`load`, pinned `CHECK: error{{.*}}tainted
   value reaches an unsupported instruction`, **authored from a real run that confirms
   the fold happens** (whether a given switch folds is clang-version- and
   case-count-dependent, Rule 9/11); and (ii) the positive `control_swap_switch_datamux.ll`
   FileChecks the **input** retains `switch i32` (not `@switch.table`) — else the test
   exercises the gep decline, not the switch path. Both ship; (i) proves the
   pre-detection decline, (ii) proves the real switch survives `-O1`.

9. **¬-bracket / double-write (data-mux).** Recipe C uses **no** `¬`-bracket (distinct
   literals are disjoint). A spurious `cqrt_x` would double-write yet match a count-only
   CHECK. **Probe:** `control_swap_switch_datamux.ll` `CHECK-NOT: cqrt_x` and `ORD` pins
   `alloc(out) → (eq → alloc(delta) → copy_controlled)×N → eq_inv×N`.

---

## 7. Test-driven work-item sequence (Rule 12 red-green throughout)

**Authoring discipline (binding):** for every WI, write the negative
`RUN: not %cq-opt … -S %s 2>&1 | %filecheck %s` fixture **first**, with the `CHECK:
error{{.*}}<string>` mirroring the **actually-fired** string character-for-character
(captured by piping a real `-O1` `.ll` through the pass, not from the §0 table), watch
it fail, then implement minimally. One tainted region per fixture (opt's `DS_Error`
handler exits on the first diagnostic). Positives carry the verify-clean second-opt RUN
(`| %cq-opt -passes=verify -disable-output -`) and the multi-prefix RUNs
(`--check-prefix=CNT/ORD/XCT/ACC`).

**Red-green is explicit per-WI (binding).** Negatives are red by construction (they
fail until their gate fires). **Positive accept fixtures get their red state by landing
in WI-1 as `; XFAIL: *`** — WI-1's emit is *stubbed-decline*, so every positive
`control_swap_switch_{phase,value,datamux}.ll` and `control_swap_eqfold_{diamond,
ifelse,polarity}.ll` **fails** there (its accept never happens → that IS the red).
Then WI-2/3/4/5 each **removes the `; XFAIL: *` line** from its class's positive as the
green step (XPASS). This is the 4.2/4.3 graduation precedent. Each WI row's **Red→Green**
column names the exact `XFAIL` removed. One commit per WI.

| WI | Goal | Lands (modules/functions) | Negatives authored FIRST (red) + positives landed `; XFAIL: *` | Red→Green (XFAIL removed) | Dep |
|---|---|---|---|---|---|
| **WI-1** | Detect-all classifier (emit **stubbed-decline**) | `SwitchClassify.{cpp,h}` (`classifySwitchRegion` G0–G11 driver) + `SwitchArmProve.{cpp,h}` (per-class G6 proofs) + `ControlDetect.cpp:223–225` replace + `ControlPlan.h` `SwitchClass` field + `ArmHomogeneity` `classifyArmContent` de-anon + CMake | **Negatives (red first, one per §0/§22 row, every string captured from a real run):** `…_multiphi.ll` (C1, `control flow`), `…_nonempty_default.ll` (C5, `control flow`), `…_grouped.ll` (C4, `control flow`), `…_muxexch.ll` (C8 distinct-handle, `control flow`), `…_mixed.ll` (`mixed phase/value arm`), `…_angle.ll` (G3, `rotation angle`), **`…_fpdata.ll`** (G4 FP-fence-first, `control flow`), **`…_vector.ll`** (G4 `<2 x i32>`, `control flow`), **`…_i128.ll`** (G4 empty-`abiWidth`, `control flow`), **`…_impure_phase.ll`** (G6, `impure phase arm`), **`…_nested.ll`** (G11, `control flow`), **`…_jumptable.ll`** (a many-case data switch `clang -O1` folds to `switch.table` gep/load → pre-detection decline `tainted value reaches an unsupported instruction`; author from a real run that confirms the fold), **`…_datause.ll`** (G10, `condition data use neither escaped nor measured`, v1-floor) **and** **`…_predates_gate.ll`** (G10, `condition predates a non-diagonal gate`, v1-floor). **Positives landed as `; XFAIL: *` (their red):** `control_swap_switch_{phase,value,datamux}.ll`, `control_swap_eqfold_{diamond,ifelse,polarity}.ll` — all fail because emit is stubbed-decline. **`control_swap_defer_switch.ll` resolved explicitly (no "whatever it does"):** its switch has an **identity merge `phi`** (`%qm = phi [%q,…],[%q,…],[%q,…]`, no `cq_phi` in any arm) — a no-op switch, **not** a phase arm. **Chosen path:** repurpose it as a **decline fixture** pinned to the string `classifySwitchRegion` actually fires (G1 finds no content phi → no arm class → decline; capture from a real run, expected `control flow`); author the real 2-case **phase** positive fresh as `control_swap_switch_phase.ll`. No dangling XFAIL on `defer_switch`. | — | — |
| **WI-2** | Phase-arm emit + re-anchor scrub | `SwitchRouteEmit.{cpp,h}` (`emitSwitchPhaseRegion` + dispatch + folded-gate scrub) + `SwapRouteEmit.cpp` dispatch branch | `control_swap_switch_phase.ll`: default `CHECK` pins per-case `cq_template_icmp_eq_<W>_hl` / `cqrt_alloc` / `cqrt_cswap` / `cqrt_rz` / `cqrt_cswap` / `cqrt_free` / `_hl_inv` / `cqrt_free` (the `_hl`/`_hl_inv` symbol pins are the G2 emit-time parity gate, open-Q 5); `CHECK-NOT: cq_phi`, `CHECK-NOT: phi i32`, `CHECK-NOT: cqrt_ry{{.*}}_controlled` / `cqrt_rz{{.*}}_controlled`; `ORD` per-case order; `XCT-COUNT-N`/`XCT-NOT` exactly N rail+flag frees; `ACC-NOT: under quantum control`; optional `CHECK-NOT: cq_phi` on the post-opt IR (re-anchor survival). Verify-clean RUN. **Author at N≥3 cases** (exercises the N-way folded-gate scrub + N-way flatten — the re-anchor BLOCKER has no backstop). | **Remove `; XFAIL: *` from `control_swap_switch_phase.ll`** (XPASS). | WI-1 |
| **WI-3** | Value-arm emit | `SwitchValueEmit.cpp` (`emitSwitchValueRegion`, C2 anchor, one copy-out, LIFO R† with §8.5 seam) | `control_swap_switch_value.ll` (method-B stream: `cswap` in → chain → `cswap` back → `cqrt_copy_<W>` → `_inv` reversed R† → frees; `ORD`+`XCT`). **Negatives (red first):** `control_swap_reject_switch_value_clobber.ll` (G7 `arm rewrites a condition operand` — the **only** G7 fixture; §3c clobber is a **value-arm-only** proof, so there is **no** generic `…_clobber.ll` in WI-1), `control_swap_reject_switch_value_swaproute.ll` (C2/G6 mis-anchor, `value-arm swap-route` — the C2 kill-shot probe, §6.5), `control_swap_reject_switch_impure_value.ll` (G6, `impure value arm`). | **Remove `; XFAIL: *` from `control_swap_switch_value.ll`** (XPASS). | WI-1 |
| **WI-4** | Data-mux emit | `SwitchDataMuxEmit.cpp` (`emitSwitchDataMuxRegion`, preload + XOR-delta) | `control_swap_switch_datamux.ll`: `ORD` pins `alloc(out=v_d) → (eq → alloc(delta) → copy_controlled)×N → eq_inv×N`; `CHECK-NOT: cqrt_x`, `CHECK-NOT: cqrt_cswap`, `CHECK-NOT: phi i32`, narrowed `CHECK-NOT: cqrt_rz{{.*}}_controlled`; **must FileCheck the INPUT retains `switch i32`** (not `@switch.table`); `XCT` exactly N flags freed. | **Remove `; XFAIL: *` from `control_swap_switch_datamux.ll`** (XPASS). | WI-1 |
| **WI-5** | Equality-folded diamond | `ArmClassify.cpp:775` ~3-line call site + `tryEqFoldArm` in **`EqFoldArm.{cpp,h}`** (new TU) | `control_swap_eqfold_diamond.ll` (1-case `if(q==k)`), `control_swap_eqfold_ifelse.ll` (2-case if/else, both clang orderings), `control_swap_eqfold_polarity.ll` (FALSE-successor polarity). **Negatives (red first):** `control_swap_reject_eqfold_wrong_literal.ll` (D4, `control flow`), `control_swap_reject_eqfold_cross_handle.ll` (D3, `control flow`). | **Remove `; XFAIL: *` from `control_swap_eqfold_{diamond,ifelse,polarity}.ll`** (XPASS). | WI-1 |
| **WI-6** | e2e goldens (≥1 per class) | `tests/e2e/slice_control_switch_{phase,value,datamux,eqfold}.c` + `.expected.log` + 4 `add_test` blocks (copy the `e2e-slice-control-select` block, `tests/e2e/CMakeLists.txt:139–144`, verbatim — e2e is **not** auto-globbed; reconfigure to register) | Each slice: `int slice(void){ int q=<lit>; q=cq_theta(q,0.5); <switch/eqfold>; return cq_measure(...); } int main(void){ (void)slice(); return 0; }`; golden captured from **real linked output** (absolute LLVM path), byte-diffed by `run_slice.sh`. **The phase slice uses N≥3 cases** so the byte-diff exercises the N-way folded-gate scrub + N-way flatten (the re-anchor BLOCKER's only downstream backstop). The **eqfold slice is a regression floor for `emitRegion`-reuse** (§4D re-tests the golden 4.1 diamond path, not new mechanism — noted, kept). The only layer that LINKS + signature-matches every emitted symbol. | — | {WI-2,3,4,5} |
| **WI-7** | Rule-13 adversarial clearance | `docs/design/rssa-swap-control/WI7_SWITCH_CLEARANCE.md` + ROADMAP/PRD/CLAUDE.md flips + a `bd remember` | Independent analytic/trace review (no simulation) of the four kill-shots (C1/C2/C4/C5) + the two residual boundaries; §8 lens table; verdict. | — | WI-6 |

Dependencies (binding): **WI-{2,3,4,5} ← WI-1**; **WI-6 ← {WI-2..WI-5}**; **WI-7 ← WI-6**.

> **Minor consciously deferred:** `control_swap_reject_switch_impure_phase.ll` (G6
> `impure phase arm`) lands in **WI-1** (a pure-classifier decline, provable before emit
> exists), while its value twin `…_impure_value.ll` and the C2 `…_value_swaproute.ll`
> land in **WI-3** beside the value emitter/`proveSwitchValue`. All ship; only their WI
> placement differs by which TU first makes the decline live.

---

## 8. Adversarial verification plan (Rule 13 — clears the core change)

A green suite alone does **not** clear the lowering-core changes (`classifySwitchRegion`,
the three emitters, the `ArmClassify` D-clause, the re-anchor scrub). Each lens below is
a deliberate adversarial probe-family (analytic/trace reasoning, **no statevector
simulation** — owner decision 2026-06-10).

1. **Re-anchor lens (§5/§6.2).** Does any folded `cq_phi(c_i,θ)` survive to `:110`?
   Trace the emit for N=1,2,3 cases; confirm scrub+erase precedes rotations in both
   entry points; FileCheck `CHECK-NOT: cq_phi`.
2. **N-way order/multiset lens (§6.3).** Construct a deliberately reordered emit by hand;
   confirm `ORD`+`XCT` reject it where `CNT` accepts it.
3. **C1 multi-phi kill-shot.** A 2-content-phi switch — must decline `control flow`,
   never lower one phi and dangle the other.
4. **C2 value-anchor kill-shot.** A value switch where the chain *could* be mis-anchored
   on `q`; the **fixture** `control_swap_reject_switch_value_swaproute.ll` (WI-3) pins the
   `value-arm swap-route` decline (Rule-12 probe, not the `assert`); `proveSwitchValue`
   anchors on `p` (merge default-edge incoming) and asserts `!= SI->getCondition()` as
   defense-in-depth (assert-compiled-out under Release, so it is **not** the probe).
5. **C4 grouped-case kill-shot.** `case 0: case 1: X` (two values → one label) — must
   decline `control flow`, never mint one flag and drop the second value.
6. **C5 non-empty-default kill-shot.** A `default:` body — must decline `control flow`,
   never lower it without the (excised, prohibited) `FlagConjunction` `¬OR`.
7. **G8 MUX-EXCH no-cloning lens.** Distinct tainted handles per case — must decline
   `control flow` (XOR-delta not const-computable; freeing superposed sources needs cswap,
   Rule 8). Confirm the input retains `switch i32`.
8. **cswap-arg0 seam lens (§6.6).** Confirm `emitSwitchValueRegion` brackets route cswaps
   with `emitRoute` and passes only the body chain to `emitInverseChain`.
9. **Uncompute non-selection lens (§6.7).** Confirm `%out` (a `cqrt_alloc_`) is never an
   uncompute terminal (has a non-benign controlled-copy consumer) and the N controlled
   copies are never selected.
10. **Jump-table pre-emption lens (§6.8).** Confirm a foldable data-mux declines at
    `declineTaintEscapes` (`:64`) with the **fixture** `control_swap_reject_switch_jumptable.ll`
    pinning `tainted value reaches an unsupported instruction`, **and** the positive
    `control_swap_switch_datamux.ll` retains `switch i32` (exercises the real switch).
11. **Impure-arm / G10-scrutinee decline lens.** Confirm the G6 `impure phase arm` /
    `impure value arm` fixtures and **both** G10 fixtures (`…_datause.ll`,
    `…_predates_gate.ll`) fire their exact v1-floor strings — the kickoff predicate may
    *tighten* G10 but the conservative-decline fixtures ship now (Rule 12; over-decline
    safe).

### §8.11 Clearance verdict table (WI-7 artifact — `WI7_SWITCH_CLEARANCE.md`)

| Lens | Verdict | Key evidence |
|---|---|---|
| Re-anchor (§5) | (filled at WI-7) | scrub+erase trace; `CHECK-NOT: cq_phi` |
| N-way order/multiset | (filled at WI-7) | `ORD`+`XCT` reject reordered hand-build |
| C1 multi-phi | (filled at WI-7) | decline `control flow` fixture |
| C2 value-anchor | (filled at WI-7) | `…_value_swaproute.ll` decline fixture (`value-arm swap-route`) + `proveSwitchValue` `!= q` assert (defense-in-depth) |
| C4 grouped-case | (filled at WI-7) | decline `control flow` fixture |
| C5 non-empty-default | (filled at WI-7) | decline `control flow` fixture |
| G8 MUX-EXCH | (filled at WI-7) | decline + `switch i32` retained |
| cswap-arg0 seam | (filled at WI-7) | body-chain-only R† stream |
| Uncompute non-selection | (filled at WI-7) | `%out` terminal-rejection assertion |
| Jump-table pre-emption | (filled at WI-7) | `…_jumptable.ll` decline (`kMsgOther` at `:64`) + datamux retains `switch i32` |
| Impure-arm / G10 scrutinee | (filled at WI-7) | `…_impure_{phase,value}.ll` + `…_datause.ll` + `…_predates_gate.ll` decline fixtures |

**Two residual coherence boundaries (must clear before the emitter ships, WI-7):**
(a) the **value-arm method-B N-way coherent boundary** — is `%out` ever *wrong* (not
merely entangled) for N>2 cases? (b) the **data-mux N-ary coherent-operand gate** — the
§16.7 select coherent-operand boundary, now N-ary (a coherent / `Ry`-phase data operand
must ride the conservative decline, as 4.4 did for the select).

---

## 9. Done criteria (maps PRD §21)

- [ ] **(A)** Phase-arm switch lowers to the §4A stream; `control_swap_switch_phase.ll`
      green (CNT/ORD/XCT/ACC), verify-clean.
- [ ] **(B)** Value-arm switch lowers to the §4B method-B stream;
      `control_swap_switch_value.ll` green; the G7 clobber declines
      (`…_value_clobber.ll`), the C2 mis-anchor declines (`…_value_swaproute.ll`), the
      G6 impure-value declines (`…_impure_value.ll`).
- [ ] **(C)** Constant data-mux lowers to the §4C preload+XOR-delta stream;
      `control_swap_switch_datamux.ll` green; input retains `switch i32`.
- [ ] **(D)** Equality-folded diamond accepts via `tryEqFoldArm` and reuses `emitRegion`;
      `control_swap_eqfold_{diamond,ifelse,polarity}.ll` green; D3/D4 negatives decline.
- [ ] Every §0/§22 off-pattern shape fires its **exact** diagnostic string, **each with
      its own named negative fixture** (no bundled rows): the **separate** G4 trio
      (`…_fpdata.ll` / `…_vector.ll` / `…_i128.ll`), G6 impure-phase/impure-value, the C2
      `…_value_swaproute.ll`, both G10 fixtures (`…_datause.ll`, `…_predates_gate.ll`),
      the jump-table pre-emption `…_jumptable.ll`, C1/C4/C5/C8/G3/G7/G11 — all negatives
      green; `control_swap_defer_switch.ll` repurposed (no dangling XFAIL).
- [ ] ≥1 e2e golden per class (WI-6), byte-diff clean against real linked output.
- [ ] No new `What` string; no new ABI symbol; `gen_templates.py --check` clean (no YAML
      touched).
- [ ] Full `ctest` green (`ir-pass-lit`, `frontend-lit`, `^e2e-`, `runtime`).
- [ ] WI-7 Rule-13 clearance: `WI7_SWITCH_CLEARANCE.md` 0 silent miscompiles; ROADMAP/
      PRD/CLAUDE.md flips; `bd remember` of the const-fold re-anchor + the four kill-shots.

---

## 10. Reuse map (Rule 14 — every need resolves to an existing symbol)

| Need | Existing symbol (file:line) |
|---|---|
| Per-case flag mint + `_inv` strip (no live `CmpInst`) | `emitEqFlag(Value*, ConstantInt*, WidthDispatch&, bool, Instruction*)` (`CompareLowering.cpp:220`) |
| Eq-fold diamond flag (real `CmpInst`) | `lowerCompareToFlag(CmpInst*, WidthDispatch&, TaintSet&, StringRef, bool, Instruction*)` (`CompareLowering.cpp:207`) |
| `\|0⟩` rail / preload / XOR-delta alloc | `WidthDispatch::allocFn(StringRef)` (`WidthDispatch.cpp:107`) |
| Uncontrolled value copy-out | `WidthDispatch::copyFn(StringRef)` (`WidthDispatch.cpp:119`) |
| Controlled XOR copy (data-mux merge) | `ControlledSymbols::copyControlledFn(StringRef)` (`ControlledSymbols.cpp:120`) |
| Route / `¬`-bracket | `emitRoute(IRBuilder<>&, const ControlledSymbols&, Value*, Value*, Value*, bool, const DebugLoc&)` (`SwapRouteEmit.cpp:684`, `SwapRouteEmit.h:89`) |
| Body-chain reverse-play (R†) | `emitInverseChain(IRBuilder<>&, ArrayRef<CallInst*>, WidthDispatch&, ControlledSymbols&, Value*, Value*)` (`EmitInverse.cpp:111`) |
| Rail / flag free | `WidthDispatch::freeFn()` (`WidthDispatch.cpp:257`) |
| Phase replay (arg-1 only) | `WidthDispatch::rzRtFn(StringRef)` → `@cqrt_rz_<W>` (**confirmed `WidthDispatch.h:86`**) |
| Eq-fold accept clause (new TU, reuses spine walks) | `tryEqFoldArm(...)` in **new** `EqFoldArm.cpp`/`EqFoldArm.h` (reuses `walkPhaseSpine`/`armBlockIsPureSpine`/`taintedAngleGate`) — **not** `ArmAnalysis.cpp` (does not exist) |
| Width from real logical type (pre-RAUW) | `abiWidthFromType(Type*)` (`OpcodeSupport.cpp:148`) |
| Per-arm/per-case class split (G5 homogeneity) | `classifyArmContent(BasicBlock*, Value*) -> ArmContent` (`ArmHomogeneity.cpp:66`) + `isValueChangingOp` (`ArmHomogeneity.cpp:49`) + `treeHomogeneous` (`ArmHomogeneity.cpp:151`, exported) — **`classifyArmContent`/`ArmContent` are currently TU-local; de-anonymize into `cq` + declare in `ArmHomogeneity.h` to reuse (do not re-derive — Rule 14)** |
| Phase spine walk / value chain walk | `walkPhaseSpine` (`ArmAnalysis.h:45`, body `ArmClassify.cpp:85`), `walkValueChain` (`ArmAnalysis.h:85`, body `ArmClassify.cpp:262`) |
| Pure-spine / pure-chain proofs | `armBlockIsPureSpine` (`ArmClassify.cpp:118`), `valueArmIsPureChain` (`ArmClassify.cpp:314`) |
| Tainted-angle gate (G3/G6/D7) | `taintedAngleGate` (`ArmClassify.cpp:360`) |
| §3c provenance / alias (G7/G8) | `condProvenance` (`ArmClassify.cpp:173`), `diagonalAliasHit` (`ArmClassify.cpp:219`) |
| Sole merge phi (G1 base, generalize to N) | `soleMergePhi(BasicBlock*)` (`ControlDetect.cpp:74`) |
| Forward arg-1 angle walk (G3 template) | `selReachesRotationArg1` (`SelectClassify.cpp`) |
| Taint-set scrub before erase | `scrubTaint` (`SwapRouteEmit.cpp:60`) — per-TU mirror |
| Loud decline | `diagnoseUnderControl(Instruction*, StringRef)` (`ControlPlan.h:292` / `ControlDetect.cpp:46`) |
| CFG flatten (eq-fold diamond verbatim; switch N-way model) | `flattenRegion` / `flattenRegionTree` (`RegionFlatten.cpp:45/91`) |

**Deliberately NOT used / NOT touched.** No new `cqrt_*` or `cq_template_*` symbol; no
YAML edit (`opcode_table.yaml` untouched, `gen_templates.py --check` stays clean — New-
ABI verdict NONE, PRD §21.5). `ChainWalk.cpp` / `FreePoint.cpp` / `Uncomputation.cpp`
unchanged (N controlled copies are legitimate consumers of the live `%out`; rails/`%out`/
delta left allocated, Rule 6). The excised `lowerGatedSwitch` / `FlagConjunction` /
`SwitchNormalization` / `MergeDissolution` path is **not** revived (Rule 11 /
Hallucination-Risk); the `SwitchArm`/`MuxExch`/`SwitchDefaultDirect` ControlPlan fields
are retained design vocabulary repurposed for the swap-route, **not** the old generation.

---

## 11. Out of scope (declines wired in WI-1)

Each shape below declines loudly (the §0/§22 string in the decline matrix), lowering
nothing — implemented as WI-1 negatives, never deferred silently:

- **Jump-table data/angle muxes** — fold to `gep`/`load`, decline at
  `declineTaintEscapes` **before** detection (`cq taint escape: …`). `normalizeJumpTableAngle`
  **not** revived.
- **Distinct-handle / ≥2-base tainted data-mux** (MUX-EXCH, §20.10) → `control flow`. The
  coherent multiplexer is a future `cqrt_cswap`/Fredkin increment.
- **Non-empty `default:` body** (§20.8) → `control flow`. Needs the sanctioned `¬OR`
  default-flag (a future item).
- **Grouped fall-through labels** (≥2 case values → 1 label, §20.9) → `control flow`. The
  per-value-flag routing is a deferred positive with its own mutual-exclusivity fixture.
- **Mixed arm classes** (phase+value) → `mixed phase/value arm`.
- **fp-data / vector / `i128` / pointer merge** → `control flow` (G4).
- **Nested tainted branch inside a case** (deeper than the 4.3 depth-2 nest) →
  `control flow` (G11).
- **Value arm clobbering a scrutinee-read register** (`case 1: q=q+1`) →
  `arm rewrites a condition operand` (G7, permanent — information-theoretic, §3c).

---

## Appendix A. Resolution of the PRD §22 open questions + kickoff checks

Each is a concrete check against the live tree at IMPLEMENTATION-4.5 kickoff (not
assumed). Resolve **before** the dependent WI. **Binding rule:** for every
"verify at kickoff" predicate that gates a *decline* (G1, G10), the conservative
**v1-floor decline fixture ships in WI-1 NOW** (pinned to the v1-floor string);
kickoff verification may *tighten* the predicate but **never removes the fixture**
(over-decline is always safe — Rule 12).

1. **`soleMergePhi` → N-incoming lift (G1).** *Check:* read `soleMergePhi`
   (`ControlDetect.cpp:74–84`); generalize to N incomings and add the identity-only-
   second-phi RAUW-collapse predicate. *V1 floor (safe, ships now):* any 2nd **content**
   phi ⇒ decline `control flow`. *Resolve in:* WI-1, `soleContentMergePhi`. The
   `…_multiphi.ll` fixture (a 2nd content phi) is the v1-floor decline probe and ships in
   WI-1 regardless of how the RAUW-collapse predicate later tightens. (The repurposed
   `control_swap_defer_switch.ll` — an *identity*-only merge phi — also rides this gate.)

2. **Value-arm routed-base derivation (G6/C2).** *Check:* run `valueChainBase` over all
   `-O1` forms of a value switch; assert it returns the merge **default-edge** incoming
   for **every** case with `valueChainBase == defaultEdgeIncoming && !=
   SI->getCondition()`. Determine whether any clang form puts the routed base on a
   non-default case edge. *Resolve in:* WI-3, `proveSwitchValue`. If a non-default-edge
   form exists, decline it (`value-arm swap-route`) in v1.

3. **Eq-fold if/else `Routed` anchor ordering (D/§20.6).** *Check:* generate both clang
   arm orderings (const-arm-first, handle-arm-first) of a 2-case if/else eq-fold; confirm
   both converge on the same `Routed` and the existing if/else `Routed`-set does not
   double-set with the new anchor. *Resolve in:* WI-5 (`control_swap_eqfold_ifelse.ll`
   covers both orderings; `_polarity.ll` covers FALSE-successor).

4. **Per-case scrub vs `RotationLowering` (§20.2/§20.12).** *Check:* trace
   `emitSwitchPhaseRegion` for N=1,2,3; confirm the folded `cq_phi(c_i,θ)` erase + the
   `PhiCalls` removal precede `CQLoweringPass.cpp:110` for **all N** cases, with all
   block/value identities captured before the first erase (no block-ptr caching).
   *Resolve in:* WI-2 (§6.2 probe + `CHECK-NOT: cq_phi`).

5. **`emitEqFlag` vs `lowerCompareToFlag` parity.** *Check:* for all 5 int widths,
   confirm `emitEqFlag(q, c_i)` produces the byte-identical `cq_template_icmp_eq_<Wq>_hl`
   + `_hl_inv` strip pair the strip-validity argument depends on (the switch has no live
   per-case `CmpInst` to feed `lowerCompareToFlag`). *Resolve in:* WI-1 (G2 mintability
   probe) + WI-2 (the phase fixture pins the exact `_hl`/`_hl_inv` symbols per width).

6. **Data-mux delta-scratch lifetime.** *Check:* confirm `%d_i = cqrt_alloc(v_i^v_d)` is
   left **untainted**/unfreed (benign, mirroring 4.4 `materialize`), does **not** enter
   `BirthOrder`, and N such allocs don't trip a leak-accounting assertion in uncompute.
   *Resolve in:* WI-4 (§6.7 / lens 9; the data-mux fixture confirms no `cqrt_free` on
   `%d_i`).

7. **Two residual Rule-13 boundaries (WI-7).** *Check:* the value-arm method-B N-way
   coherent boundary (is `%out` ever *wrong*, not merely entangled, for N>2?) and the
   data-mux N-ary coherent-operand gate (the §16.7 select boundary, now N-ary — a
   coherent / `Ry`-phase data operand must ride the conservative decline). *Resolve in:*
   WI-7 (`WI7_SWITCH_CLEARANCE.md`, §8.11 residuals); these **must clear before the
   emitter ships**.

8. **`ArmHomogeneity::classifyArmContent` de-anon + switch-case fit (G5).** *Check:*
   `classifyArmContent`/`ArmContent`/`isValueChangingOp` are TU-local in
   `ArmHomogeneity.cpp` (only `treeHomogeneous` is exported). De-anonymize
   `classifyArmContent`+`ArmContent` into the `cq` namespace and declare in
   `ArmHomogeneity.h` (precedent: `emitRoute`/`collectArmPhis`); confirm its
   `(BasicBlock* ArmBB, Value* ArmIncoming) -> ArmContent` signature/semantics classify a
   **switch case block** (not just a diamond arm) correctly before keying G5 on it.
   *Resolve in:* WI-1, `homogeneousClassOrDecline`. If the fit is imperfect, fall back to
   the small `walkPhaseSpine`+`isValueChangingOp` composition (still Rule-14 reuse, no
   re-derivation of the lineage walks).

9. **G10 scrutinee data-use predicate.** *Check:* the select analog has no terminator
   condition; the switch scrutinee is a raw integer with its own data-use discipline.
   Determine the exact predicate (escaped/measured ownership; non-diagonal forward wire
   gate) at kickoff. *V1 floor (safe, ships now):* decline any scrutinee with a
   non-diagonal forward wire gate (`condition predates a non-diagonal gate`) or an
   un-owned data use (`condition data use neither escaped nor measured`). *Resolve in:*
   WI-1; **both** `…_datause.ll` and `…_predates_gate.ll` fixtures ship now regardless of
   how the predicate tightens.

---

## Appendix B. Build & test commands

`LLVM=/usr/local/opt/llvm@19/bin` (opt/clang/FileCheck are **not** on `PATH`; lit/ctest
bake absolute paths).

```bash
# Build the plugin (+ runtime + test exes)
cmake --build build -j8
cmake --build build --target CQPass        # just the pass → build/ir-pass/libCQPass.so

# Full suite
cmake --build build && ctest --test-dir build --output-on-failure

# Per layer
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # the *.ll fixtures (auto-discovered)
ctest --test-dir build -R '^e2e-'      --output-on-failure   # the vertical slices (LINK + golden diff)
ctest --test-dir build -R runtime      --output-on-failure   # trace golden-diff + header compile

# One fixture
cd build && lit -v ir-pass/test --filter 'control_swap_switch_phase'

# Run the pass on one .ll by hand (absolute tool path, capture the real fired string)
$LLVM/opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
    -S ir-pass/test/control_swap_switch_phase.ll \
  | $LLVM/FileCheck ir-pass/test/control_swap_switch_phase.ll

# Capture a real decline string for a negative fixture (Rule 12 — never copy from the table)
$LLVM/opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
    -S ir-pass/test/control_swap_reject_switch_multiphi.ll 2>&1 | grep error

# ABI drift gate (must stay clean — no YAML touched)
python3 tools/gen_templates.py --check
```

**Full pipeline for one e2e `.c`** (mirrors `tests/e2e/run_slice.sh`; link order is
load-bearing — `libcq_templates.a` **before** `libcq_runtime.a`):

```bash
$LLVM/clang -Iinclude -include CQ.h -O1 -emit-llvm -S tests/e2e/slice_control_switch_phase.c -o /tmp/s1.ll
$LLVM/opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S /tmp/s1.ll -o /tmp/s2.ll
$LLVM/clang /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a
/tmp/a    # → trace; byte-diff vs tests/e2e/slice_control_switch_phase.expected.log
```

**Rule-13 clearance plan (WI-7).** Artifact `docs/design/rssa-swap-control/
WI7_SWITCH_CLEARANCE.md` — the §8.11 lens verdict table (0 silent miscompiles) + the
two residual coherence boundaries (value-arm N-way; data-mux N-ary coherent-operand).
Independent second reviewer/agent, analytic/trace reasoning, **no statevector
simulation** (owner decision 2026-06-10). A green `ctest` alone does **not** clear the
core change. On clearance: flip ROADMAP/PRD/CLAUDE.md to 4.5 DONE and `bd remember` the
const-fold re-anchor mechanism + the four kill-shots (C1/C2/C4/C5).
