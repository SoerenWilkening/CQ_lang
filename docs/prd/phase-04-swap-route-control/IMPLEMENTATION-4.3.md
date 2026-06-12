# Phase 4.3 IMPLEMENTATION — RSSA swap-routed nested control (depth-2 phase arms)

Module layout, signatures, and the **test-driven** work-item sequence for the
4.3 increment defined by [`PRD.md`](PRD.md) **Part III (§§11–14)**. Companion to
the PRD (which fixes *scope* and *binding decisions* — the depth-2
homogeneous-phase nest, the mint-from-rail guard, the LIFO strip-order); this
file fixes *how the code is built*. Sibling of the closed 4.1
([`IMPLEMENTATION.md`](IMPLEMENTATION.md)) and 4.2
([`IMPLEMENTATION-4.2.md`](IMPLEMENTATION-4.2.md)) plans and follows their
structure §-for-§. **Every cited symbol/line was verified against the live tree
(branch `swap-route-control`, 2026-06-12) by a 5-area extraction pass — all PRD
citations CONFIRMED**; the real `-O1` shapes in §0/§5 were *measured*, not
guessed (Rule 9/11). Nothing here adds runtime ABI — 4.3 reuses every `cqrt_*` /
`cq_template_*` symbol 4.1 used (PRD §11, §13).

**Modularity budget (this increment's design directive): every NEW translation
unit is ≤300 LOC.** The two files 4.3 most extends are *already* over that line
(`SwapRouteEmit.cpp` = 683, `ArmClassify.cpp` = 846 — pre-existing debt); 4.3
therefore lands its logic in **new small TUs** and keeps edits to the bloated
files thin (§1). The `ArmClassify` homogeneity split (§3) *reduces* that file.

**Authoritative contracts** this plan is built against (FileCheck specs, all
**pinned from real `clang -O1` output** per PRD §12.1 — a hand-stacked
3-incoming merge is rejected at authoring time as a shape `-O1` never emits):
the new lit contracts `control_swap_nested_phase_diamond.ll` (§5g, accept) and
its polarity / derived-base / decline siblings (§5h), plus ≥1 C-sourced e2e
golden. **Symbol order IS the contract** (CHECK-pinned), with the hard
postconditions `CHECK-NOT: _controlled`, `CHECK-NOT: cqrt_toffoli`,
`CHECK-NOT: phi i32`, **`CHECK-COUNT-4: @cqrt_free`** (rail2, %f2, rail1, %f1),
and — the one 4.3-specific addition — a **targeted ordered FileCheck** pinning
the inner strip *before* the outer route-back (§5g, §8).

Fixture authoring rule (bd `swap-route-detect-known-limits`): `opt`'s
`DS_Error` handler exits on the FIRST diagnostic — author every swap-route
fixture with **one tainted region per file**.

---

## 0. Accept criterion (the one definition everything keys on)

> **4.3 additionally lowers a tainted-condition NEST iff ALL hold; otherwise it
> declines loudly and lowers nothing (Prime Directive):**
>
> 1. **(outer shape)** a `BranchInst` `isConditional()` with a tainted condition
>    forming a **one-content-arm diamond** (NOT `if/else` — §12.4 invariant-(i)),
>    whose single arm block (`Mid`) ends in **another** tainted-condition
>    `BranchInst` forming an inner **one-content-arm diamond**, both reconverging
>    at one **shared 3-incoming merge `PHINode`** with edges
>    `{[%h, Arm], [%g, Mid], [%q, Pred]}` (the §5 measured shape);
> 2. **(depth-2 cap)** the inner arm block does **not** itself end in a tainted
>    `br`, and the shared merge has **exactly 3 incomings** (§12.7);
> 3. **(exactly one phi)** the shared merge block holds **exactly one** `PHINode`
>    (real `-O1` emits two when inner cond/arm touch different registers — §12.4);
> 4. **(N-incoming RAUW-collapse / value homogeneity)** every merge incoming
>    (`%h`, `%g`, `%q`) resolves — post-rotation-lowering, through the `cq_phi`
>    diagonal-alias closure — to the **same `i32` base handle** (holds because
>    every gate is diagonal `Rz`; §12.4, `cwk-merge-phi-discriminator`);
> 5. **(mint-from-rail / inner-condition-operand — THE load-bearing accept
>    signal)** the inner tainted-condition operand lies in the **diagonal-alias
>    closure of the value the parent routes onto `rail1`** (i.e. the inner cond
>    reads `%g`, the outer-arm gate output, an `Rz`-alias of `%q`); §12.2, §12.4;
> 6. **(tree-homogeneous phase)** **every** arm in the tree is a pure phase chain
>    (only `@cq_phi`/Rz, classical angles, no value op), and every intervening
>    outer-arm gate (`Mid`'s body) is a `cq_phi` (diagonal `Rz`); §12.5;
> 7. **(nest-vs-sequential)** the inner `Pred` (= outer `Mid`) is **dominated by
>    the outer arm** and the diamond single-predecessor invariants hold at both
>    levels (`Arm->getSinglePredecessor()==Mid`, `Mid->getSinglePredecessor()==
>    Pred`) — NOT a sequential `if/else; if` whose merge is the next region's
>    Pred (§12.4 discriminator).

Criteria 1–3 + 7 are recovered by **SSA-value identity before any mutation**
(Rule 9); 4 is the merge-edge agreement; **5 is the binding signal** (4 is
necessary-not-sufficient — the multi-register false-accept passes 4 yet fails 5,
§0-below). This criterion makes the §5g accept and the full §5h decline matrix
fall out exactly.

> **The measured `-O1` accept shape** (Rule 9/11 — generated on this tree from
> `if (q>5) { q = cq_phi(q,b); if (q<9) { q = cq_phi(q,a); } }`):
>
> ```
> Pred(%0):  %1 = cq_theta_si32(...)            ; q
>            %2 = icmp sgt i32 %1, 5             ; outer flag f1, TAINTED
>            br i1 %2, label %3, label %8
> Mid(%3):   %4 = cq_phi_si32(%1, b)            ; intervening gate  g = %g  (on q)
>            %5 = icmp slt i32 %4, 9             ; inner flag f2 — reads the GATED %4
>            br i1 %5, label %6, label %8
> Arm(%6):   %7 = cq_phi_si32(%4, a)            ; inner-arm gate  h
>            br label %8
> Merge(%8): %9 = phi i32 [%7,%6], [%4,%3], [%1,%0]   ; 3-incoming, ONE phi
>            %10 = cq_measure_si32(%9)
> ```
> Both arms here are TRUE-successors (no negation); the four polarity probes
> (§5h) cover outer-neg × inner-neg. **No code between the two branches folds
> the nest to a flat diamond (`-O1` measured) — already 4.1's** (§12.1); the
> trigger for 4.3 is the **intervening tainted `cq_phi`** in `Mid`.

Decline dispositions added/confirmed by 4.3 (shared `diagnoseUnderControl`,
`ControlPlan.h`; `…: <What> under quantum control`). **Every string below was
confirmed by running the real `-O1` IR through the pass — the string that
ACTUALLY fires, not the one assumed** (PRD §13):

| Shape (real `-O1`) | Disposition | Diagnostic `What` |
|---|---|---|
| **depth-2 homogeneous-phase nest** (§5g) | **ACCEPT** *(was: defer `nested control flow`)* | — |
| **multi-register nest** — cond on `q`, arms gate `p` (the pre-clearance blocker; merge edges all `p`-lineage, inner cond reads `q` ∉ rail1-closure) | **decline** (§12.4 mint-from-rail guard) | `nested control flow` |
| **depth-3** / **asymmetric both-arm** nest (genuine 4-incoming merge) | **decline** (§12.7 depth cap) | `nested control flow` |
| **symmetric both-arm** nest (`-O1` hoists the shared gate into a separate **2-pred block** → 3-incoming i32 merge, NOT 4-incoming; an **FP angle phi appears only with differing arm angles** — identical angles give the same 3-incoming i32 merge with NO FP phi, *measured* FA1) | **decline** (§12.4 invariant-(i): outer not a one-content-arm diamond) | `nested control flow` |
| **two-phi merge** — inner cond + inner arm on different registers (`-O1` emits a `q`-phi **and** an `r`-phi at the 3-incoming merge) | **decline** (§12.4 exactly-one-phi) | `control flow` |
| **any value arm in the tree** — mixed phase/value | **decline** (§12.5 tree homogeneity) | `mixed phase/value arm` |
| **any value arm in the tree** — pure-value nest | **decline** (deferred value-nest increment) | `value-arm swap-route` |
| **inner-arm clobbers outer condition** (an inner value-write — §12.5 union-§3c is built but **VACUOUS** in 4.3: a value-write is a value arm, homogeneity fires first) | **decline** | `mixed phase/value arm` *(NOT `arm rewrites a condition operand`, which is dead-in-4.3)* |
| **distinct-base merge edges** (an incoming carrying an independently-derived base) | **decline** (§11 step-6 N-incoming RAUW-collapse) | `control flow` |
| **non-`cq_phi` intervening outer-arm gate** (a `cq_theta`/Ry or value op between the branches) | **decline** | **`control flow`** — the inner-cond wire `%g = cq_theta(%q)` is **not** in the `cq_phi` diagonal-alias closure (`diagonalAliasHit` walks `cq_phi` arg-0 only), so the Mid merge-edge resolves to a **distinct base** and §3.1 step-5 RAUW-collapse fires first, **before** `nonDiagonalGateBeforeBranch`'s `condition predates a non-diagonal gate` (ArmClassify.cpp:504-505) or homogeneity could. **Pin empirically against the post-4.3 build** — whichever of these fires first IS the contract (FA2); §5h |
| **nested `select` / `switch`** (inner construct unbuilt — 4.4/4.5) | **decline** (fired on the inner construct, before nested recovery) | `select` / `switch` |

**Multi-register false-accept (the blocker), real `-O1` measured** — why
criterion 4 is not enough and criterion 5 is the gate:
```
Mid(%4): %5 = cq_phi_si32(%2, b)   ; gates p  (p-lineage)
         %6 = icmp slt i32 %1, 9   ; inner cond reads %1 = q  — NOT %5 (p)
Merge:   %10 = phi [%8,%7],[%5,%4],[%2,%0]   ; ALL p-lineage → passes criterion 4
```
Minting the inner flag from `rail1` (which holds `p`) would compute `p<9` where
the source wrote `q<9` → **verify-clean silent miscompile**. Criterion 5
declines it `nested control flow`.

---

## 1. Module map

**No new translation unit grows a file past 300 LOC; 4.3's logic lands in three
new ≤300-LOC TUs (Rule 14 — they call existing primitives, never re-implement
routing/flag/flatten).** The PRD's "ControlRegion parent/child tree fields" are
**partly pre-existing** (`Depth`/`ParentIdx`/`ParentFlag`, `ControlPlan.h:245-
247`, from the excised WP5 nested-AND generation — inert in the swap-route path);
4.3 **reuses** them and adds only `ParentRail` (a minor PRD correction: the
fields are not wholly new).

> **WI-0 — header-promotion prerequisite (a real, unbudgeted blocker — MD1).**
> Every primitive 4.3's new TUs reuse is currently **internal-linkage**:
> `recoverRegion`/`soleMergePhi`/`hasTaintedCondBranch`/`uncondSucc`/`RegionShape`
> live in `ControlDetect.cpp`'s **anonymous namespace** (opens line 48, closes
> 184); `diagonalAliasHit`/`condProvenance`/`walkPhaseSpine`/`walkValueChain`/
> `taintedAngleGate`/`armBlockIsPureSpine`/`valueArmIsPureChain`/`isValueChangingOp`
> live in `ArmClassify.cpp`'s **anonymous namespace** (opens 44, closes 460). **No
> header declares any of them** (every header occurrence is a *comment*, not a
> declaration — `recoverRegion` in `ArmClassify.h:3`/`RegionFlatten.h:30`,
> `condProvenance` in `ArmClassify.h:12`, `taintedAngleGate` in
> `RotationLowering.h:10`; `diagonalAliasHit`/`soleMergePhi`/`hasTaintedCondBranch`
> and the rest appear in no header at all). A separate TU **cannot link**
> against them. So WI-0 (lands first, blocks WI-1): create **`ControlShape.h`**
> (declare `RegionShape`, `recoverRegion`, `soleMergePhi`, `hasTaintedCondBranch`,
> `uncondSucc` — move their defs into the named `cq` namespace) and **`ArmAnalysis.h`**
> (declare `diagonalAliasHit`, `condProvenance`, the per-arm walks — de-anonymized,
> shared by the re-hosted `ArmHomogeneity` PASS-1 **and** `ArmClassify.cpp`'s
> retained PASS-3). The "thin edit" LOC deltas below and the `ArmClassify`
> "846→820 net-reduction" do **NOT** account for this de-anonymization/header
> churn — re-budget for it (a real surface, not a comment-only change).

### New translation units (`ir-pass/src/` + `ir-pass/include/`)

| Module | ~LOC (cpp / h) | Concern | Mutates IR? |
|---|---|---|---|
| **`RegionTreeDetect`** | ~180 / ~40 | Pure analysis. Lift the `Nested` decline for the **proven** §0 accept-shape only: recursively recover the depth-2 nest, populate `Depth`/`ParentIdx`, and run the **four detection guards** — N-incoming RAUW-collapse (criterion 4), exactly-one-phi (criterion 3), **mint-from-rail inner-condition-operand** (criterion 5), nest-vs-sequential discriminator (criterion 7). Declines everything it can't prove with the §0 strings. Called from `ControlDetect::handleBranchRegion`'s `case Nested:`. | **No** |
| **`ArmHomogeneity`** | ~150 / ~30 | The §12.5 split: a **PASS-1 per-arm class-determination** (Phase/Value/reject, no emission) + **PASS-2 tree-homogeneity gate** (`mixed phase/value arm` / `value-arm swap-route` *before* any §3c emission). Called by `RegionTreeDetect` over the whole region tree; defers per-region §3c (PASS 3) to `ArmClassify`'s existing inline path, now gated behind homogeneity. | No |
| **`NestedRouteEmit`** | ~220 / ~35 | The mutating recursive emitter: the §0/§5g 9-step routed stream with **parent-rail threading**, **LIFO rail/flag frees**, and the **load-bearing inner-strip-before-outer-route-back order** (§12.3). Reuses `emitRoute`, `lowerCompareToFlag(Rail)`, `wd.allocFn/freeFn`, and the new `flattenRegionTree`. Dispatched from `SwapRouteEmit::lowerControlRegions` for a depth-0 region whose plan has a child. | **Yes** |

### Edits to existing files (thin)

| File | Change | LOC before → after |
|---|---|---|
| `ir-pass/include/ControlPlan.h` | **WI-1.** Add `llvm::Value *ParentRail = nullptr;` thread field to `ControlRegion` (reuse existing `Depth`/`ParentIdx`/`Mid`). **No `ChildIdx` field** — the parent locates its child by the existing `ParentIdx`/`indexOf` link (MD4), the same link the MD0 pre-flight exemption keys on. Add `enum class PerArmClass { Undetermined, Phase, Value };` if `ClassArm`/`ClassArmFalse` cannot carry the PASS-1 pre-classification. | 283 → ~296 |
| `ir-pass/src/ControlDetect.cpp` | **WI-1.** `case RegionShape::Nested:` in `handleBranchRegion` (line 167) calls `recoverRegionTree(BI, taint, plan)` (RegionTreeDetect) **instead of** the unconditional `diagnoseUnderControl(BI, "nested control flow")`; on a proven accept-shape it pushes the parent+child regions, else the tree builder fires the §0 decline. `soleMergePhi` (line 69) stays the 2-incoming gate for FLAT regions; the relaxed 3-incoming recognizer lives in RegionTreeDetect (never relax `soleMergePhi`). **PLUS the load-bearing inner-br-claim fix (blocker FA0):** `detectControlRegions` (line 191) loops `for (BasicBlock &BB : F)` calling `handleBranchRegion` (line 200) with **no skip set** — so after the outer nest ACCEPTs, the **inner** tainted `br` in `Mid` is independently re-visited, `recoverRegion` finds it FLAT (its merge is 3-incoming → `soleMergePhi` returns null at line 76 → `OffPattern`), and it false-declines **`control flow`** (line 164), killing the whole §5g accept. Add a `SmallPtrSet<BranchInst*> Claimed`: `recoverRegionTree`'s ACCEPT records the inner `BranchInst` (`Mid->getTerminator()`); the loop does `if (Claimed.count(BI)) continue;` before `handleBranchRegion`. (`-O1` block order visits Pred before Mid, so the outer's ACCEPT populates `Claimed` first; for visit-order robustness the ACCEPT may also scrub an already-emitted child.) `Claimed` is owned by `detectControlRegions` and threaded in via a `&Claimed` parameter added to both `handleBranchRegion` and `recoverRegionTree`. | 214 → ~245 |
| `ir-pass/src/CompareLowering.cpp` + `.h` | **WI-2.** `lowerCompareToFlagRail(cmp, railBase, wd, taint, qqWidth={}, inverse=false, before=nullptr)` — mint the flag with the parent-routed `railBase` substituted for the original (now-stale-on-`q`) handle operand; the OTHER operand classified as today. Forwards to the same template machinery. | 222 → ~262 |
| `ir-pass/src/RegionFlatten.cpp` + `.h` | **WI-3.** `flattenRegionTree(Outer, Inner, taint)` — capture **every** block identity before the first erase; follow `flattenRegion`'s **branch-first** discipline (RegionFlatten.cpp:7-10) — erase **both** conditional `br`s first (inner `br` in `Mid`, outer `Pred`-tail), then splice the **single shared `Merge` into `Pred` exactly once**, then erase the now-unreachable arm blocks `{InnerArm, then Mid}`, then `Merge` — each exactly once. **`Pred` itself SURVIVES** (it holds the emitted routed stream — only its dead `br`, the `Pred`-tail, is removed). Do **NOT** call the per-region `flattenRegion` (line 86's unconditional `Merge->eraseFromParent()` double-erases the shared merge → SIGSEGV). | 89 → ~175 |
| `ir-pass/src/SwapRouteEmit.cpp` | **WI-3.** `lowerControlRegions` (line 647) takes `const ControlPlan &plan`, so `plan.Regions` **cannot be sorted in place** (COMPLETENESS#7) — and no sort is needed: detection's §3.1 ACCEPT pushes Outer (Depth 0) **before** Inner (Depth 1), so plan order is already outer→inner. For a depth-0 region with a coordinated child, dispatch to `NestedRouteEmit::lowerNestedRegion(Outer, Inner, …)`. **NOT a thin dispatch — TWO live guards must change (blockers MD0 + MD4):** (1) **Pre-flight exemption.** The cross-region block-lifetime guard (lines 660-668) iterates every ordered pair `(A,B)` and declines `control flow` (line 670) + `return`s whenever `A.{Pred,Arm,ArmFalse,MergeBB}` equals any of `B.{Arm,ArmFalse,MergeBB}`. The accepted nest's Outer and Inner **share `MergeBB`** (§0 criterion 1) and `Outer.Mid == Inner.Pred`, so the guard fires and lowers **nothing**. The dispatch must **skip this pair-check for a coordinated parent/child** (e.g. `if (B.Depth==A.Depth+1 && B.ParentIdx==indexOf(A)) continue;`, symmetric for the `(Inner,Outer)` pair) while keeping it active for genuinely independent/sequential regions (the §8 SIGSEGV family it exists for). (2) **Emit-loop skip.** The loop (lines 679-680) calls `emitRegion(R)` for **every** region; the inner Depth-1 region is already consumed/flattened by `NestedRouteEmit`, so re-visiting it dereferences erased blocks. Loop must `if (R.Depth>0) continue;` and dispatch a depth-0 parent that HAS a coordinated child (the `B` with `B.Depth==R.Depth+1 && B.ParentIdx==indexOf(R)` — the SAME single link the pre-flight exemption keys on, so no unpopulated `ChildIdx` field is needed, MD4) to `lowerNestedRegion(R, B, …)`, else `emitRegion(R)`. | 683 → ~725 |
| `ir-pass/src/ArmClassify.cpp` + `.h` | **WI-1.** For the **tree** case `classifyArms` calls `ArmHomogeneity::determineClasses` (PASS 1) + `treeHomogeneous` (PASS 2) before its inline §3c emission (lines 716 **and** 824, PASS 3). The heterogeneous-mixture guards (lines 582/634) move into PASS 2 **for the tree only**; the **flat-region loop keeps its inline `Routed`-threaded 582/634 guards** so flat if/else declines are not reordered (MD2). **No new accept behavior** — the accepted set is identical; only the tree's emission *order* changes so the homogeneity string fires first (§12.5). Also de-anonymize the per-arm walks into `ArmAnalysis.h` (WI-0/MD1) since both the re-hosted PASS-1 and the retained PASS-3 use them. | 846 → ~820 (homogeneity extracted; excludes WI-0 header churn) |
| `ir-pass/CMakeLists.txt` | Add `RegionTreeDetect.cpp`, `ArmHomogeneity.cpp`, `NestedRouteEmit.cpp` to `add_library(CQPass MODULE …)`. | — |
| `tests/e2e/CMakeLists.txt` + new slice | **WI-4.** `slice_control_nested_phase.{c,expected.log}` + explicit `add_test` (e2e is not auto-globbed). | — |

`CQLoweringPass.cpp` is **untouched**: the pipeline position
(`detectControlRegions` line 83 → `lowerControlRegions` line 84 → **before**
`declineClassicalMuxes` line 96 → `lowerRotations` line 110) already serves the
nest. The **binding obligation** the position imposes (§6.1): the nested emitter
must RAUW→`q` + `scrubTaint` + erase the 3-incoming merge `phi` **inside**
`lowerControlRegions`, before `declineClassicalMuxes` runs — else the live
3-incoming tainted phi reaches `diagnoseEscape(Phi, kMsgClassicalPhi)`
(`TaintPropagation.cpp:775`; `liftOneRegisterMergePhi` hard-returns at line 616
on `getNumIncomingValues()!=2`, so it **cannot** rescue it) → a spurious
`classical phi` decline on a half-mutated module.

> **Pre-existing-debt note (not a 4.3 blocker).** `SwapRouteEmit.cpp` (683) and
> `ArmClassify.cpp` (846) violate the ≤300 budget before 4.3 touches them. 4.3
> does not worsen them materially (thin dispatch / net-reducing extraction). A
> follow-up `bd` issue should extract `emitValueRegion` (~210 LOC) into a
> `ValueArmEmit.cpp` TU (the split the 4.2 plan §1 already flagged) to bring
> `SwapRouteEmit` under budget — **out of 4.3 scope** (no correctness coupling).

---

## 2. Shared diagnostic helper

Unchanged — `diagnoseUnderControl` (`ControlPlan.h`, defined in
`ControlDetect.cpp:41-46`), `"cq controlled lowering: " + What + " under quantum
control"`. 4.3 introduces **no new string**: it reuses `nested control flow` (was
the blanket decline, now scoped to the real over-accept shapes — §0 table),
`control flow`, `mixed phase/value arm`, `value-arm swap-route`, `select`,
`switch` — each mirrored character-for-character by its decline fixture (Rule 12),
pinned to the string that **actually fires on real `-O1`** (§5h). **The 4.1 string
`condition predates a non-diagonal gate` (`ArmClassify.cpp:504-505`) is deliberately
NOT in this 4.3 list:** the theta-Mid intervening-gate nested row is classified
`Nested` → `recoverRegionTree`, whose §3.1 step-5 RAUW-collapse fires on the
theta's distinct base and declines the **existing** `control flow` BEFORE
`nonDiagonalGateBeforeBranch` could fire — so that 4.1 string is unreachable on any
4.3-nested decline row (FA2 resolved by pinning, not by enumerating). The WI-1
transitional decline likewise reuses the **existing** `nested control flow` (NOT a
new string — MD5); see §7.

---

## 3. Detection & classification (pure analysis, before any mutation — Rule 9)

### 3.1 Region-tree recovery — `RegionTreeDetect`

`recoverRegionTree(BranchInst *OuterBI, TaintSet &taint, ControlPlan &plan)` is
invoked from `ControlDetect::handleBranchRegion` exactly where the unconditional
`nested control flow` decline lives today (`ControlDetect.cpp:167`, the
`case RegionShape::Nested:`). The `RegionShape::Nested` is still *detected* the
same way (`recoverRegion` lines 93–96: `hasTaintedCondBranch(S0||S1)`), but the
disposition becomes **prove-or-decline** instead of blanket-decline:

```
recoverRegionTree(OuterBI, taint, plan):
  # All checks by SSA identity, BEFORE any mutation (Rule 9).
  1. Outer must be a ONE-CONTENT-ARM DIAMOND (criterion 1, §12.4 inv-(i)),
       re-recovered by SSA identity ignoring the inner gate's taint.  NOTE: a
       verbatim recoverRegion(OuterBI) returns RegionShape::Nested for BOTH the
       accept shape AND the symmetric both-arm nest (hasTaintedCondBranch on S0||S1
       fires before the IfElse recognizer, ControlDetect.cpp:95-96) — so the
       both-arm shape is NOT distinguished as "IfElse" here; it is rejected because
       its OUTER br has tainted gates on BOTH successors (not a one-content-arm
       diamond) → decline `nested control flow`.  Capture Pred, Mid(=outer Arm),
       ArmNegated_outer.
  2. Inner br = Mid->getTerminator(); must be conditional + tainted cond.
       Recover inner diamond by SSA identity: inner Arm, inner ArmNegated.
       Mid->getSinglePredecessor()==Pred  AND  Arm->getSinglePredecessor()==Mid
       (criterion 7 single-pred invariants); inner Pred(=Mid) dominated by outer
       arm (criterion 7 discriminator — a sequential `if/else; if` whose merge is
       this region's Pred fails this → decline `nested control flow`).
  3. DEPTH CAP (criterion 2, §12.7): inner Arm must NOT end in a tainted br,
       AND the shared merge must have EXACTLY 3 incomings.  >3 incomings OR a
       third tainted level → decline `nested control flow` BEFORE any emission
       (also avoids the §12.4 block-lifetime hazard of descending into a
       sub-region the outer flatten erases).
  4. EXACTLY-ONE-PHI (criterion 3, §12.4): the shared Merge block holds exactly
       one PHINode (mirror soleMergePhi's line-72 discipline, relaxed to 3
       incomings).  >1 phi (real `-O1` two-register shape) → decline `control flow`.
  5. N-INCOMING RAUW-COLLAPSE (criterion 4, §11 step 6, cwk-merge-phi-
       discriminator): the merge triple {[%h,Arm],[%g,Mid],[%q,Pred]} — every
       incoming resolves through the `cq_phi` diagonal-alias closure to the SAME
       i32 base handle.  A distinct independently-derived base → decline
       `control flow`.  (NECESSARY-NOT-SUFFICIENT — see step 7.)
  6. TREE HOMOGENEITY (criterion 6, §12.5): ArmHomogeneity::determineClasses over
       BOTH arms + the intervening Mid gate(s); treeHomogeneous must be all-phase.
       Any value arm → `mixed phase/value arm` (mixed) / `value-arm swap-route`
       (pure-value).  A non-`cq_phi` intervening Mid gate (cq_theta/Ry) is NOT a
       cq_phi diagonal alias, so it FAILS step 5's RAUW-collapse FIRST → `control
       flow` (FA2 — confirm the guard order empirically against the post-4.3 build
       and pin §5h to whatever fires first).  GATE-FREE Mid (no intervening cq_phi
       between the branches): criterion 6 is satisfied VACUOUSLY (all-phase over the
       empty gate set) → ACCEPT; step 2's collectArmPhis(Mid) replay is empty,
       emitting outer route-in/route-back with no intervening rz.  This is the
       degenerate `control_swap_defer_nested.ll` shape, now an accept (MD3).
  7. MINT-FROM-RAIL (criterion 5 — THE binding accept signal, §12.2/§12.4): the
       INNER condition operand must lie in the diagonal-alias closure of the value
       the parent routes onto rail1 (= %g's lineage, an Rz-alias of %q).  An inner
       cond reading a register OUTSIDE that closure (the multi-register nest:
       cond on q, data on p — which PASSES step 5) → decline `nested control flow`.
  ACCEPT: push Outer region (Depth 0) then Inner region (Depth 1, ParentIdx=outer,
       ParentRail populated at emit time) into plan.Regions; record the inner
       condition's rail-operand identity for lowerCompareToFlagRail; AND record the
       inner BranchInst (Mid->getTerminator()) into detectControlRegions's Claimed
       set so the detection loop does NOT re-visit it and false-decline `control
       flow` (blocker FA0 — §1 ControlDetect row).
```

**Reuse (Rule 14).** Steps 5/7 reuse `diagonalAliasHit` (`ArmClassify.cpp:205`,
the backward `cq_phi` arg-0 closure walk) and `condProvenance`
(`ArmClassify.cpp:159`, with its load-bearing arg-1 angle exclusion). Step 2's
domination uses a `DominatorTree` built once (the §12.4 gotcha: build fresh per
call — never reuse a stale DT across levels). Step 6 is `ArmHomogeneity` (§3.2).
The **mint-from-rail check (step 7) is the load-bearing signal** — step 5
(merge-edge agreement) is necessary-not-sufficient, mirroring §8.3's f64 fencing
(the multi-register false-accept passes 5 yet must decline).

### 3.2 Tree-homogeneity split — `ArmHomogeneity` (the §12.5 refactor)

Today `classifyArms` (`ArmClassify.cpp:462`) **interleaves** class-determination
with §3c emission: `SawPhaseArm` is set at arm acceptance (lines 594, 609) and
`SawValueArm` at line 795; the heterogeneous-mixture guards (lines 582, 634) +
the §3c diagnostic fire inline at **both** `arm rewrites a condition operand`
sites — line 716 (the in-arm `diagonalAliasHit` chain) **and** line 824 (the
**hoisted** out-of-arm value op reached via `isValueChangingOp(Base)` at line
811). It is NOT a single site (CD0). For a **tree** this mis-orders: a
genuinely-nested inner *value*
clobber (`if(q>5){q=cq_phi(q,b);if(q<9){q=q*7;q=q+3;}}`, real `-O1`) classified
per-region in isolation has `SawPhaseArm==false` *within the inner region* (the
outer `cq_phi` lives in `Mid`, not an inner arm), so the per-region mixed guard
never fires, classification reaches §3c, and emits `arm rewrites a condition
operand` instead of the `mixed phase/value arm` the §5h fixture pins.

4.3 splits the concern. **The accepted *set* is unchanged, but the split is NOT
"emission-order-only" for FLAT if/else (MD2):** today the heterogeneous guards
(582/634) fire on arm 2 *before* that arm's own per-arm checks (`valueArmIsPureChain`
:774 "impure value arm", `armBlockIsPureSpine` "impure phase arm"), so the live
string for an arm-2-also-defective if/else is `mixed phase/value arm`; a PASS-2
that runs the mixed check *after* PASS-1's per-arm declines inverts that. So the
PASS-1/PASS-2 extraction is **scoped to the TREE case only** — flat single regions
keep `classifyArms`'s existing `Routed`-threaded loop with its inline 582/634
guards intact, OR PASS-2's mixed check must run BEFORE PASS-1's per-arm declines
for flat regions. Either way add regression fixtures pinning the
arm-2-defect-beside-opposite-class declines (value-defect-beside-phase,
impure-phase-beside-value) to prove the same diagnostic+anchor fires post-4.3:

```
ArmHomogeneity::determineClasses(Region, taint) -> PerArmClass[2]   # PASS 1
   per arm: Phase | Value | <hard reject e.g. fan-out/non-quantum>  (NO emission,
   NO heterogeneous/§3c check); populate Region.ClassArm/ClassArmFalse + Shadow.

ArmHomogeneity::treeHomogeneous(tree, taint) -> bool                # PASS 2
   over EVERY region in the tree: all-Phase -> true; any Value (mixed or pure) ->
   emit the §0 homogeneity string, return false.  (A non-`cq_phi` intervening gate
   does NOT decline HERE: §3.1 step-5 RAUW-collapse fires FIRST on its distinct
   base -> `control flow` — FA2, §0 table. Homogeneity owns only the value-arm rows.)

# PASS 3 (unchanged ArmClassify inline path, now GATED): only reached when PASS 2
# returns all-phase-homogeneous.  In 4.3 the §3c emission (lines 716 AND 824) is
# therefore VACUOUS for the tree (a value-write is a value arm → declined by PASS 2
# first); the union-§3c provenance (§12.5) is BUILT but goes active only with value
# nests.  NOTE: PASS-1 determineClasses must classify a HOISTED out-of-arm value
# contribution (the line-811/824 case: Chain empty, isValueChangingOp(Base)) as
# PerArmClass::Value too, so PASS-2 declines `mixed phase/value arm` for it — not
# only the in-arm chain that reaches 716 (CD0).
```

`determineClasses` is the existing per-arm logic (walkPhaseSpine line 75,
walkValueChain line 262, taintedAngleGate line 356, the entry guards 463-507)
**minus** the inline `SawPhaseArm`/§3c emission. The heterogeneous-mixture guards
(today 582/634) become PASS-2 `treeHomogeneous`. **Caveat (MD2): PASS-1 is NOT a
pure order-independent `PerArmClass[2]` for flat if/else** — `Routed` is anchored
**mid-loop** (line 610 first phase arm, 685 first value arm) and the second arm's
classification depends on it (`Base == Routed` :575, `Chain.Base != Routed` :677).
For a **diamond** the Pred-edge seeds `Routed` (line 514/529) before the loop, so
PASS-1 is order-independent there — which is why the tree-scoped extraction (above)
is safe and flat if/else must keep the existing loop.

**Outer-Mid purity carve-out (blocker COMPLETENESS#5 — the accept path itself).**
`armBlockIsPureSpine` (`ArmClassify.cpp:106-122`, called at 590/605) builds the
in-arm `cq_phi` spine of the arm-incoming, then returns **false** on the first
non-terminator instruction NOT in that spine. For the **outer** region of a tree
`Region.Arm == Mid`, and `Mid` legitimately holds the **inner condition compare +
inner `br`** beyond the outer gate — so a verbatim whole-block
`armBlockIsPureSpine(Mid)` declines the legitimate §5g accept as **`impure phase
arm`** (empirically reproduced). `determineClasses` MUST therefore, for a region
that has a child, run a **Mid-variant of `armBlockIsPureSpine` that STILL iterates
EVERY non-terminator instruction in `Mid`** (the stray-op guard at
`ArmClassify.cpp:97-101` must stay live) but accepts an instruction **iff** it is
(a) a member of the `collectArmPhis(Mid)` gate-chain spine, **OR** (b) the child
region's inner condition instruction `InnerCond` (and, for a *derived* inner cond,
the in-`Mid` operand lineage feeding it — the transitive in-block operands of
`InnerCond` that are not in the routed-base closure). **ANY other** non-terminator
in `Mid` — a stray value op (`q=q*7`), a measure, a fan-out sibling — STILL returns
false → decline **`impure phase arm`**. The carve-out narrows the rejection to
EXACTLY the inner cond/br the child owns; it must **NOT** skip the whole-block scan
(a `collectArmPhis`-only walk would silently accept a stray value op that the
emitter then drops on flatten — a verify-clean over-accept / dangling-taint UAF;
blocker, caught by the round-2 convergence check). Allow-set (b) is complementary
to step-7 mint-from-rail, not contradictory: a derived cond `icmp(add(%qb,1),9)`
has `%qb` in-closure (step 7) while the in-`Mid` `add` is the lineage the purity
scan must allow. Add an **accept-path regression** (an outer-arm-block-with-inner-
cond fixture that must NOT decline `impure phase arm`) AND the stray-op decline
fixture (§5h `…_nested_mid_stray.ll`). **Invariant preserved**: the
arm-block-bounded walks (lines 80, 268) stay — an unbounded walk double-collects
the shared pre-region phi (SIGSEGV on emitter erase). **Do not** relax the
base-identity Defect-2 guard (lines 676-680) or the per-use angle exclusion.

---

## 4. Emission — `NestedRouteEmit::lowerNestedRegion` (the recursive routed stream)

Dispatched from `SwapRouteEmit::lowerControlRegions` (line 647; **no sort — `const ControlPlan&`, plan order already outer→inner per §1/§3.1**)
for a depth-0 region with a child. Emitted into the **`Pred` block before the
outer `br`** (one IRBuilder at `OuterBI`), in this **exact order** (the §5g
contract). Steps reuse the 4.1 primitives byte-for-byte except the inner flag
mint (the one new call) and the LIFO free/strip ordering:

```
lowerNestedRegion(Outer, Inner, wd, csyms, taint):
  B at OuterBI;  Q = Outer routed base (MergePhi Pred-edge incoming, line 515 reuse)
  1. OUTER mint + route-in:
        %f1   = lowerCompareToFlag(OuterCond, wd, taint, {}, false, OuterBI)
        %rail1= wd.allocFn(abi)(0)
        emitRoute(B, csyms, %f1, Q, %rail1, Outer.ArmNegated, DL)      # outer route-in
  2. OUTER arm body replay on rail1 (the intervening cq_phi, the 4.1 phase replay):
        Mid_phis := collectArmPhis(Mid)                                  # forward program order
        for Phi in Mid_phis:  cqrt_rz_<W>(%rail1, Phi.angle)             # %g lives on rail1
  3. RECURSE inner with base := rail1 (mint FROM the rail — §12.2):
        %f2   = lowerCompareToFlagRail(InnerCond, /*railBase=*/%rail1, wd, taint,
                                       {}, false, OuterBI)               # the ONE new call
        %rail2= wd.allocFn(abi)(0)
        emitRoute(B, csyms, %f2, %rail1, %rail2, Inner.ArmNegated, DL)  # inner route-in (route rail1)
        Arm_phis := collectArmPhis(Arm)                                 # forward program order
        for Phi in Arm_phis:  cqrt_rz_<W>(%rail2, Phi.angle)            # inner arm body
        emitRoute(B, csyms, %f2, %rail1, %rail2, Inner.ArmNegated, DL)  # inner route-BACK
  4. INNER clean-up, inside the outer bracket (LIFO — §12.3, the load-bearing order):
        wd.freeFn()(%rail2)                                            # rail2 |0> clean (Rz|0>=|0>)
        lowerCompareToFlagRail(InnerCond, %rail1, wd, taint, {}, true, OuterBI) # STRIP f2 vs rail1
        wd.freeFn()(%f2)
     # (i) inner route-back BEFORE inner strip (step 3 last cswap restores rail1's
     #     mint value); (ii) inner strip BEFORE outer route-back (rail1 not yet emptied).
  5. OUTER route-back + clean-up:
        emitRoute(B, csyms, %f1, Q, %rail1, Outer.ArmNegated, DL)      # outer route-BACK
        wd.freeFn()(%rail1)                                            # rail1 |0> clean
        lowerCompareToFlag(OuterCond, wd, taint, {}, true, OuterBI)     # STRIP f1 vs q
        wd.freeFn()(%f1)
  6. REWIRE + FLATTEN (owner of the 3-incoming phi — §6.1):
        MergePhi->replaceAllUsesWith(Q); scrubTaint(MergePhi); MergePhi->erase()
        allArmPhis := Mid_phis ++ Arm_phis       # Mid gates FIRST = forward cross-block
                                                 # lineage (Mid gate is arg-0 producer of
                                                 # the Arm gate); mirrors SwapRouteEmit.cpp
                                                 # :538-544 AllPhis.append discipline (ET1)
        for Phi in reverse(allArmPhis): scrubTaint(Phi); Phi->erase()
                                                 # reverse → erase inner-arm gate (uses the
                                                 # Mid gate) FIRST so each is use-empty;
                                                 # appending Arm before Mid asserts on erase,
                                                 # OMITTING a gate leaves it live in
                                                 # taint.PhiCalls → lowerRotations emits a
                                                 # stray uncontrolled cqrt_rz (verify-clean
                                                 # wrong-register gate — §6.1-4.1 hazard)
        flattenRegionTree(Outer, Inner, taint)   # coordinated, single shared-Merge erase
```

**Width source (Rule 9).** At emit time (before `lowerRotations`)
`taint.HandleWidth` is empty; recover the ABI width from the `cq_phi` suffix
(`abiWidthFor`) for `rail1`/`rail2`/`rz`. `cswap`/`x`/`free` are width-agnostic
(`i32` handles).

**`lowerCompareToFlagRail` (the one new emission primitive).** `lowerCompareTo
Flag` (CompareLowering.cpp:61) classifies operands by `taint.Tainted` SSA
membership and reads them in place. For the inner condition `icmp slt %g, 9`, the
operand `%g`'s **state physically lives on `rail1`** after step 1's route-in (the
original SSA register holds `|0⟩` on the `f1=1` path) — so the flag must be minted
`icmp(rail1, 9)`, not `icmp(%g, 9)`. The Rail variant takes the parent rail
explicitly, substitutes it for the parent-routed operand, classifies the OTHER
operand as today, and emits the identical `_hl`(/`_hl_inv` for the strip) symbol
with `rail1` in the handle slot. **Signature distinct (the `Rail` suffix) so the
substitution intent is unmistakable** (§12.2; the SwapRouteEmit gotcha: a plain
`lowerCompareToFlag` would mint from the stale `%g` register — verify-clean
wrong predicate).

**Rail/flag frees are emitter-driven LIFO scope-exit, NOT `computeFreePoint`**
(§12.4): `rail2`/`%f2` freed inside the inner bracket (step 4), `rail1`/`%f1`
after the outer route-back (step 5). A naive post-dominator would push the
inner-rail free to the outer merge (too late) — for a phase rail that late point
is `|0⟩`-clean and only wasteful, but the discipline is fixed now so it stays
correct when value nests (where the late point is *dirty*) land.

**`flattenRegionTree` (RegionFlatten extension).** Capture `{Pred, Mid, Arm,
Merge}` identities **before** the first erase. Follow `flattenRegion`'s
**branch-first** discipline (RegionFlatten.cpp:7-10 — the conditional `br`s before the dead blocks):
erase **both** conditional `br`s first (the inner `br` in `Mid` and the outer
`Pred`-tail), THEN splice `Merge`'s instructions into `Pred` once, THEN erase the
now-unreachable arm blocks (`InnerArm`, then `Mid`), THEN `Merge` — each exactly
once. **`Pred` SURVIVES** (it holds the emitted routed stream). Erasing `InnerArm`
while the inner `br` still references it dangles a successor (the block-lifetime
UAF the project guards against) — hence branch-first (ET2). **Do NOT** call
per-region `flattenRegion` (line 86 unconditionally erases `Merge`; two calls
double-free the shared block → the documented sequential-region SIGSEGV,
`swap-route-derived-base-clearance` hole 2).

---

## 5. Target symbol sequences (the FileCheck contract)

### 5g. Nested phase diamond — `if (q>5) { rz(q,b); if (q<9) { rz(q,a); } }`

Pinned from the measured `-O1` shape (§0). `%[[Q]]` is the `@cq_theta` handle;
all four cswaps capture-match their `%[[F1]]/%[[Q]]` or `%[[F2]]/%[[R1]]` pair:

```
%f1   = call i32  @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)        ; 1 outer mint
%rail1= call i32  @cqrt_alloc_i32(i32 0)
        call void @cqrt_cswap(i32 %f1, i32 %q, i32 %rail1)           ; 1 outer route-in
        call void @cqrt_rz_i32(i32 %rail1, double 0.25)              ; 2 intervening gate (g on rail1)
%f2   = call i32  @cq_template_icmp_slt_i32_hl(i32 %rail1, i32 9)    ; 3 inner mint FROM RAIL1
%rail2= call i32  @cqrt_alloc_i32(i32 0)
        call void @cqrt_cswap(i32 %f2, i32 %rail1, i32 %rail2)       ; 3 inner route-in
        call void @cqrt_rz_i32(i32 %rail2, double 0.75)              ; 3 inner arm body
        call void @cqrt_cswap(i32 %f2, i32 %rail1, i32 %rail2)       ; 3 inner route-back
        call void @cqrt_free(i32 %rail2)                             ; 4 rail2 |0> free
%f2s  = call i32  @cq_template_icmp_slt_i32_hl_inv(i32 %rail1, i32 9); 4 inner STRIP (vs rail1)
        call void @cqrt_free(i32 %f2)                                ; 4 inner flag free
        call void @cqrt_cswap(i32 %f1, i32 %q, i32 %rail1)           ; 5 outer route-back
        call void @cqrt_free(i32 %rail1)                             ; 5 rail1 |0> free
%f1s  = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)    ; 5 outer STRIP (vs q)
        call void @cqrt_free(i32 %f1)                                ; 5 outer flag free
%m    = call i32  @cqrt_measure_i32(i32 %q)                         ; (phi RAUW'd → q, then lowerMeasures: si32→i32)
```

Hard postconditions: `CHECK-NOT: _controlled`, `CHECK-NOT: cqrt_toffoli`,
`CHECK-NOT: phi i32`, **`CHECK-COUNT-4: @cqrt_free`** (`rail2`, `%f2`, `rail1`,
`%f1` — and a trailing `CHECK-NOT: @cqrt_free` guard: no fifth from `uncompute`).

**THE 4.3-specific ordered FileCheck (§8, §12.3 — the structural CHECKs above are
order-blind: a temporal-misorder emitter produces the identical symbol multiset
yet dirty-frees `%f2`).** Pin *only* the one sub-order — inner strip **before**
outer route-back — with ordered `CHECK:`:
```
; CHECK: call i32 @cq_template_icmp_slt_i32_hl_inv(i32 %{{.*}}, i32 9)
; CHECK: call void @cqrt_cswap(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})  ; the outer route-back
```
Do **not** pin the full sequence (the rail/flag frees float; a full-sequence pin
over-constrains — PRD §13).

### 5h. Decline contrast set (each its own fixture, one region per file, string
confirmed by running the real `-O1` IR)

- `control_swap_reject_nested_multireg.ll` — cond on `q`, arms gate `p`
  (pinned from the measured multi-register shape, §0) → `nested control flow`
  (criterion 5 mint-from-rail).
- `control_swap_reject_nested_depth3.ll` + `control_swap_reject_nested_botharm_asym.ll`
  — genuine 4-incoming merges → `nested control flow` (§12.7 cap).
- `control_swap_reject_nested_botharm_sym.ll` — `-O1` hoists the shared gate into
  a separate **2-pred block** → 3-incoming i32 merge (NOT 4-incoming). **Identical-
  angle arms are the simplest valid fixture** and produce this same 3-incoming
  merge with **NO FP phi**; differing angles merely ADD an FP angle phi at the gate
  block and are **NOT** required for the outer branch to survive (FA1 *measured* —
  the prior "identical arms over-fold to a 2-incoming flat diamond" rationale was
  false). The outer branch is an if/else both-arm nest (both successors carry
  tainted inner gates) → NOT a one-content-arm diamond → `nested control flow`
  (§12.4 invariant-(i)), regardless of whether the angles match.
- `control_swap_reject_nested_twophi.ll` — inner cond + inner arm on different
  registers (`-O1` two phis at the merge, §0) → `control flow` (criterion 3).
- `control_swap_reject_nested_value_mixed.ll` / `…_value_pure.ll` →
  `mixed phase/value arm` / `value-arm swap-route` (criterion 6).
- `control_swap_reject_nested_inner_clobber.ll` — inner value-write hitting the
  outer condition → **`mixed phase/value arm`** (the homogeneity string that
  fires first; **NOT** `arm rewrites a condition operand`, dead-in-4.3 — §12.5).
- `control_swap_reject_nested_distinct_base.ll` — a merge incoming carrying an
  independently-derived base → `control flow` (criterion 4).
- `control_swap_reject_nested_theta.ll` — a `cq_theta`/Ry intervening Mid gate →
  **`control flow`** (FA2: `cq_theta` is not in the `cq_phi` diagonal-alias closure
  so §3.1 step-5 RAUW-collapse fires before `nonDiagonalGateBeforeBranch`'s
  `condition predates a non-diagonal gate` at ArmClassify.cpp:504-505 — **confirm the
  guard order against the post-4.3 build and pin char-for-char to whatever fires
  first**; §0 table, §12.2).
- `control_swap_reject_nested_select.ll` / `…_switch.ll` — inner construct
  unbuilt → `select` / `switch` (before nested recovery).
- `control_swap_reject_nested_mid_stray.ll` — an outer-arm (`Mid`) block holding
  the intervening `cq_phi` gate, the inner cond/br, **AND a stray value op**
  (`%q7 = mul %qb, 7`) consumed by a non-merge user (so it neither feeds the merge
  nor is a value *arm*) → MUST decline **`impure phase arm`** (proves the Mid
  purity scan still catches a stray op — pins the COMPLETENESS#5 over-accept door
  shut; without it the carve-out silently accepts and the emitter drops `%q7`).

**Baseline regeneration (Rule 12, deliberate — retire/convert in WI-3, MD3).** The
existing `control_swap_defer_nested.ll` is a **hand-stacked** gate-free shape (inner
cond reads the **un-gated** `%q`, no intervening gate) whose decline premise
(nested→defer) 4.3 lifts. Its gate-free Mid passes all seven §3.1 criteria
(criterion 6 vacuously, criterion 5 trivially since the inner cond reads exactly
the routed `%q`) → it becomes an **accept** — **but only observably at WI-3, when
emission lands.** Under the WI-1 transitional-decline model (§7), a proven-accept
nest still emits the **existing** `nested control flow` string through WI-1/WI-2
(emission isn't built yet), so this fixture's pinned `nested control flow` CHECK
keeps **PASSING** — it does NOT break the Rule-12 gate mid-WI-1. Its CHECK only
fails once WI-3 drops the transitional decline and emits the §5g accept stream. So
**retire/convert it in WI-3**, together with un-`XFAIL`ing
`control_swap_nested_phase_diamond.ll` (§5g, the real-`-O1` accept replacement).
Until WI-3 it stays in-suite, correctly documenting the transitional decline. Do
not silently leave a stale decline fixture testing a now-accepted shape.

---

## 6. Interlock hazards (Rule 10 / Rule 13 — the silent-miscompile surface)

Each is verify-clean-invisible; each ships with a §8 verification.

1. **3-incoming phi must be erased before `declineClassicalMuxes`** (§1, the
   load-bearing pipeline coupling). `NestedRouteEmit` is the **sole owner** of
   the shared merge `phi`: RAUW→`q` + `scrubTaint` + erase in step 6, inside
   `lowerControlRegions` (line 84), **before** `declineClassicalMuxes` (line 96).
   A surviving 3-incoming tainted phi hits `diagnoseEscape(Phi, kMsgClassicalPhi)`
   (`TaintPropagation.cpp:775`) — `liftOneRegisterMergePhi` cannot rescue it
   (line 616 hard-returns at `!=2`). **Probe (§8): a `kMsgClassicalPhi`-never-
   fires assertion on an accepted nest.** Do NOT reorder the guard before
   detection (it would decline the live 3-incoming nested phi outright).
2. **Strip order (THE 4.3 core hazard, §12.3).** Inner strip `icmp_slt_..._hl_inv
   (rail1, 9)` must come **after** the inner route-back (restores `rail1`'s mint
   value) and **before** the outer route-back (`rail1` not yet emptied to `|0⟩`).
   A flat-loop emitter that strips `%f2` at the inner merge but after the outer
   route-back recomputes `c2(0)` on `rail1=|0⟩`, leaving `%f2=c2(k)⊕c2(0)` dirty
   on `f1=1,c2(k)≠c2(0)` → `cqrt_free(%f2)` is a hidden measurement collapsing
   `q`. Order-blind to the symbol multiset → **needs the ordered FileCheck** (§5g)
   + the written four-row trace (§8), not just structural CHECKs.
3. **Mint-from-rail, not from `%g`** (§12.2). The inner flag/strip read `rail1`
   (where `%g`'s amplitude lives post-route-in), via `lowerCompareToFlagRail`. A
   plain `lowerCompareToFlag` mints from the stale `%g` SSA register (holds `|0⟩`
   on `f1=1`) → verify-clean wrong predicate. The detection guard (criterion 5)
   *and* the emit primitive together enforce it.
4. **Coordinated flatten, single shared-Merge erase** (§12.4). `flattenRegionTree`
   erases the shared `Merge` exactly once; calling per-region `flattenRegion`
   twice double-frees it (SIGSEGV on valid input). Capture all block identities
   before the first erase. **Probe (§8): a double-erase regression fixture.**
5. **LIFO rail frees, emitter-driven** (§12.4). `rail2` before `rail1`; never via
   `computeFreePoint` post-dom (pushes the inner free past the outer merge).
6. **Per-level polarity (Rule 9, §12.6).** Either level's gate arm may be the
   FALSE successor (`ArmNegated`, the `cqrt_x` ¬flag bracket); outer and inner
   negate **independently**; straight-through edge selection
   (`getBasicBlockIndex`) is per level against the 3-incoming phi. **Probe (§8):
   all four outer-neg × inner-neg combinations.**
7. **Stale work-list pointers** (the §6.1-4.1/4.2 hazard, now two regions). Every
   erased instruction (both arms' `cq_phi`, both compares, both `br`s, the merge
   phi) `scrubTaint`'d from `taint.Tainted`/`BirthOrder`/`PhiCalls`/`StaleDeclined`
   — inner + outer instruction sets are disjoint, so no double-scrub, but a missed
   scrub dangles a later `lowerRotations`/`uncompute` walk.
8. **`uncompute` adds nothing** (§6.2-4.1/4.2). The rails/flags are not tainted-
   data terminals (their users are `cqrt_cswap`/`_hl_inv`/`cqrt_free`); `q` is the
   measure sink → exactly **four** frees, no fifth. `CHECK-COUNT-4` + trailing
   `CHECK-NOT`.
9. **Tree-homogeneity gate timing** (§12.5). PASS-2 homogeneity must fire
   **before** PASS-3 §3c, or an inner value-clobber reports `arm rewrites a
   condition operand` instead of `mixed phase/value arm` (the pinned string).
10. **Phase-arm regression / dephasing guard** (Rule 7). The nest emits **no**
    `cqrt_copy_*` and **no** `_controlled`/`cqrt_toffoli` — `CHECK-NOT` all three
    (a CNOT/copy on a phase nest dephases the answer, P0 0.585→0.500).
11. **Inner-br re-visit false-decline (BLOCKER FA0).** `detectControlRegions`
    (line 191) re-visits the inner tainted `br` after the outer accepts; with no
    `Claimed` set it recovers FLAT (3-incoming merge → `soleMergePhi` null →
    `OffPattern`) and false-declines **`control flow`** (line 164), making the §5g
    accept unachievable. Fix: `Claimed` set populated by `recoverRegionTree`'s
    ACCEPT, checked before `handleBranchRegion` (§1, §3.1). **Probe (§8): the §5g
    accept run through the FULL pass must NOT emit `control flow`.**
12. **Pre-flight cross-region guard over-declines the nest (BLOCKER MD0).** The
    block-lifetime pre-flight (`SwapRouteEmit.cpp:660-668`) declines `control flow`
    for any region pair sharing a doomed block; the accepted nest's Outer/Inner
    **share `MergeBB`** (and `Outer.Mid==Inner.Pred`), so it fires before dispatch
    and lowers nothing. Fix: exempt the coordinated parent/child pair (by
    `ParentIdx`/`Depth`) while keeping the guard for independent regions (§1, §4).
    **Probe (§8): the §5g accept lowers (no spurious `control flow`); a genuinely
    sequential two-region input still declines.**

---

## 7. Test-driven work-item sequence

Red-green per Rule 12 (fixture first, watch it fail, implement minimally; accepts
land `; XFAIL: *` until their WI, removed at XPASS). One commit per WI. WI-3 is a
core-lowering change — it does **not** ship on a green suite alone (Rule 13); it
clears only after §8.

| WI | Goal (observable) | Lands | Red→Green fixtures |
|---|---|---|---|
| **WI-0** | **Header promotion (MD1 — blocks WI-1).** De-anonymize the reused helpers into `ControlShape.h` (`recoverRegion`, `soleMergePhi`, `hasTaintedCondBranch`, `uncondSucc`, `RegionShape`) and `ArmAnalysis.h` (`diagonalAliasHit`, `condProvenance`, the per-arm walks) so the new TUs can link. **No behavior change** — pure move out of anonymous namespaces into named `cq`. | `ControlShape.h`, `ArmAnalysis.h`; `ControlDetect.cpp`/`ArmClassify.cpp` de-anon. | **green:** full existing suite unchanged (a pure refactor — `ctest` identical before/after). |
| **WI-1** | **Region-tree detection + homogeneity split + all declines** (no emission). `RegionTreeDetect` proves/declines the §0 shape (incl. the `Claimed`-set inner-br skip, blocker FA0); `ArmHomogeneity` splits class-determination from §3c **for the tree case** (PASS 1/2/3, flat path untouched — MD2); accepted nests decline *transitionally* via the **existing** `nested control flow` string (NOT a new string — MD5) while the §5g accept stays `XFAIL`, so nothing mis-lowers. `control_swap_defer_nested.ll` **stays green** via the transitional `nested control flow` decline (it retires in WI-3, not here — MD3). | `RegionTreeDetect`, `ArmHomogeneity`, `ControlPlan.h` fields; `ControlDetect` (`Claimed` set) / `ArmClassify` edits; CMake. | **green (all real-`-O1`-pinned, §5h):** the full decline matrix (multireg, depth3, both-arm sym+asym, twophi, value mixed+pure, inner-clobber **+ hoisted-clobber variant**, distinct-base, theta, nested select/switch) + the two MD2 arm-2-defect-beside-opposite-class regressions; existing 4.1/4.2 fixtures unchanged (incl. `control_swap_defer_nested.ll`, still passing via transitional decline). **XFAIL:** the §5g accept + 4 polarity + derived-base. |
| **WI-2** | **`lowerCompareToFlagRail`** (the rail-substituted mint). | `CompareLowering.cpp/.h`. | **green:** a focused unit fixture minting `icmp(rail,k)` from a substituted operand (or folded into WI-3's accept). |
| **WI-3** | **Emit the depth-2 phase nest** (core, Rule 13). `NestedRouteEmit` + `flattenRegionTree`; **dispatch (no sort — `const ControlPlan&`, plan already outer→inner, COMPLETENESS#7)** in `SwapRouteEmit` **including the pre-flight exemption for the coordinated parent/child pair and the `Depth>0` emit-loop skip (blockers MD0/MD4)**; the 3-incoming phi erase before `declineClassicalMuxes`; the LIFO frees + strip order. **Retire/convert `control_swap_defer_nested.ll` here** — its gate-free-Mid disposition becomes observable as an ACCEPT only once emission lands (passes via transitional decline until now — MD3); add `control_swap_nested_phase_diamond.ll` (§5g) as its replacement. | `NestedRouteEmit`, `RegionFlatten` extension, `SwapRouteEmit` dispatch + pre-flight/loop edits. | **green (un-XFAIL):** `control_swap_nested_phase_diamond.ll` (§5g, incl. the ordered strip CHECK + `CHECK-COUNT-4`) + the 4 polarity variants + `…_derived.ll` (FP-carrier derived outer cond, §8). |
| **WI-4** | **e2e golden** (Rule 16/2 — the ONLY layer that links; proves every symbol resolves + signature-matches across **two** routing levels). | `tests/e2e/slice_control_nested_phase.{c,expected.log}` + explicit `add_test`. | **green:** `ctest -R e2e-slice-control-nested-phase`. |
| **WI-5** | **§8 adversarial clearance + docs + closeout** (Rule 13). Written four-row `(f1,f2)` trace + strip-order proof cleared by independent review; double-erase probe; ROADMAP 4.3 flip; `bd remember`. | docs, memories, residual XFAIL removal. | full `ctest` green; `gen_templates.py --check` clean (no ABI change). |

Dependencies: WI-1 ← WI-0 (header promotion must land first — the new TUs cannot
link otherwise, MD1); WI-3 ← {WI-1, WI-2}; WI-4 ← WI-3; WI-5 ← {WI-3, WI-4}.

---

## 8. Adversarial verification plan (Rule 13 — clears the core change)

A green suite does not clear `NestedRouteEmit`. Scope (bd
`rule13-no-backend-clearance-scope` / `no-simulations-at-this-stage`):
**analytic/trace-level review + lowered-IR reading + structural probes** — no
backend, no statevector simulation (owner decision 2026-06-10). The PRD's
**depth-2 homogeneous-phase PHYSICS is already Rule-13-cleared**
(`CLEARED-WITH-AMENDMENTS`, 2026-06-12); WI-3/WI-5's obligation is the
**emitter-fidelity** clearance — that the *implemented* stream matches the cleared
design.

1. **The four-row `(f1,f2)` basis trace (§12.2), written + reviewed before WI-3
   ships.** Confirm the inner effect lands on `q` iff `f1∧f2`, with no
   `cqrt_toffoli`/conjunction ancilla:

   | `(f1,f2)` | `rail1` after step 2 | inner route+gate+route-back | reaches `q` |
   |---|---|---|---|
   | `(0,·)` | `\|0⟩` | cswaps move `\|0⟩↔\|0⟩`, `rz(\|0⟩)=\|0⟩` | nothing — `q` keeps `%q` |
   | `(1,0)` | `g(q)` | `%f2=0`: no inner swap; `rail1` keeps `g(q)` | `g(q)` — outer phase only |
   | `(1,1)` | `g(q)` | `%f2=1`: route to `rail2`, `rz`, route back | `h(g(q))` — both phases |

   Plus: every rail/flag provably `|0⟩` in population after its strip/free (the
   `(0,·)` row's `rz(|0⟩)=|0⟩` and the route-symmetry make each `cqrt_free` a
   clean reset, not a measurement). A phase nest **copies nothing out**, so there
   is no §8.2-style kept-source deviation channel — coherence is exact.
2. **The strip-order proof (§12.3), written + reviewed.** On the `f1=1,c2(k)≠
   c2(0)` population, show the misordered emitter (inner strip after outer
   route-back) leaves `%f2` dirty → hidden measurement; show the §4 order leaves
   every rail/flag `|0⟩` on all four rows. Mapped to the §5g **ordered
   FileCheck** (the only automated layer that can catch the misorder — the symbol
   multiset is identical).
3. **Read the actual lowered IR** (Rule 11) for §5g and diff against §4 — the
   emitter-fidelity gap is invisible to every automated layer.
4. **No-spurious-free probe.** `CHECK-COUNT-4: @cqrt_free` + trailing
   `CHECK-NOT: @cqrt_free` — proves `uncompute` added no fifth and `q` is never
   freed (the measure sink owns it).
5. **Polarity matrix.** All four outer-neg × inner-neg combinations lower to the
   correctly-bracketed routed stream (arms resolved by SSA identity, not edge
   order — §12.6).
6. **Derived-base probe.** A derived outer condition that **provably survives
   `-O1`** as a real derived compare — an **FP carrier `q + 1.0 > 5.0`** (verify
   it emits `fadd`; an *integer* `q+1>5` folds to `icmp sgt q,4` and exercises
   nothing — document, don't fight, the canonicalizer, §12.1) — drives the
   diagonal-alias closure on the outer level.
7. **Over-accept/decline matrix.** Every §5h row declines with the **exact**
   diagnostic confirmed by running its real `-O1` IR; the **multi-register
   blocker** declines `nested control flow` (criterion 5, not 4); no constructed
   over-accept survives.
8. **Detection-structural probes.** (a) `kMsgClassicalPhi`-never-fires on an
   accepted nest (hazard §6.1); (b) the **double-erase regression** — assert
   `flattenRegionTree` erases the shared `Merge` exactly once (no SIGSEGV, §6.4),
   and that no arm block is erased before its predecessor `br` (the branch-first
   discipline, ET2); (c) a sequential `if/else; if` sharing a merge still declines
   (the §12.4 dominator discriminator, criterion 7); (d) **inner-br-claim (blocker
   FA0)** — the §5g accept run through the FULL pass emits **no** `control flow`
   (proves the `Claimed` set suppresses the inner-br re-visit); (e) **pre-flight
   exemption (blocker MD0)** — the §5g accept lowers with no spurious `control
   flow` from the cross-region guard, AND a genuinely independent two-region input
   still declines `control flow` (the exemption is scoped, not blanket-removed).
9. **Dephasing guard (negative).** `CHECK-NOT: cqrt_copy`, `CHECK-NOT:
   _controlled`, `CHECK-NOT: cqrt_toffoli` on the §5g accept (Rule 7).
10. **e2e trace diff** (WI-4) — the linking proof that every symbol across two
    routing levels resolves + signature-matches.

---

## 9. Done criteria (maps PRD §13)

- [ ] The §5g depth-2 phase nest (pinned from real `-O1`) lowers to the routed
      stream: outer mint/route-in → outer-arm `rz` on `rail1` → inner mint **from
      `rail1`** → inner route/`rz`/route-back on `rail2` → inner `free` + inner
      `icmp_inv` strip (vs `rail1`, **before** the outer route-back) → outer
      route-back → outer `free` + outer strip; `CHECK-NOT: _controlled` /
      `cqrt_toffoli` / `phi i32`; **exactly four `cqrt_free`**; `opt -verify` clean.
- [ ] **The targeted ordered FileCheck** pins inner-strip-before-outer-route-back
      (the temporal-misorder emitter produces the identical multiset).
- [ ] `f1∧f2` implicit (no `cqrt_toffoli`/ancilla); the four-row trace (§8.1) and
      strip-order proof (§8.2) **written + cleared by independent review** before
      WI-3 ships — a green suite alone does not clear it.
- [ ] Full §5h decline matrix green, each char-for-char against the string that
      **actually fires on real `-O1`** (multireg → `nested control flow`, twophi →
      `control flow`, value → `mixed phase/value arm`/`value-arm swap-route`, …).
- [ ] 4 polarity probes + FP-carrier derived-base + sequential-`if/else;if`
      decline + double-erase regression all green.
- [ ] `declineClassicalMuxes` pass-through verified (the `kMsgClassicalPhi`-never-
      fires assertion) so fixtures exercise live code.
- [ ] **Blocker gates (FA0/MD0):** the §5g accept, run through the FULL pass,
      emits **no** `control flow` — the `Claimed`-set inner-br skip (FA0) and the
      pre-flight coordinated-pair exemption (MD0) both hold; a genuinely
      independent two-region input still declines `control flow` (exemption scoped).
- [ ] **WI-0 header promotion (MD1)** landed as a pure refactor (`ctest` identical
      before/after); the new TUs link against `ControlShape.h`/`ArmAnalysis.h`.
- [ ] ≥1 e2e trace golden (C-sourced, linked) diffs clean across two routing
      levels.
- [ ] 4.1/4.2 regression floor green (no nesting leakage into flat regions);
      `control_swap_defer_nested.ll` retired in **WI-3** (its gate-free-Mid shape
      ACCEPTs once emission lands; passes via the transitional `nested control
      flow` decline until then — MD3), replaced by `control_swap_nested_phase_diamond.ll`.
- [ ] Full `ctest` green; `gen_templates.py --check` clean (**no ABI change** —
      reuses 4.1's symbol set entirely).
- [ ] bd memory: `swap-route-detect-known-limits` updated (nested no longer a
      blanket decline — depth-2 phase accepted; depth-3 / if-else-nest / value-
      nest / multi-register still declined) + a **new** memory for the
      mint-from-rail + LIFO-strip-order invariant (the verify-clean-invisible
      4.3 core rule).

---

## 10. Reuse map (Rule 14 — every need resolves to an existing symbol)

| Need | Existing symbol (file:line) |
|---|---|
| Outer flag mint / `_hl_inv` strip | `lowerCompareToFlag` (`CompareLowering.cpp:61`) — unchanged |
| **Inner flag mint from the parent rail** | **`lowerCompareToFlagRail`** (NEW, the only new code in `CompareLowering`) |
| Route in/out (+¬flag bracket), both levels | `emitRoute` (`SwapRouteEmit.cpp:125`) over `ControlledSymbols::cswapFn`/`xFn` |
| `\|0⟩` rail (rail1/rail2) + clean free | `WidthDispatch::allocFn` (`WidthDispatch.h:69`) / `freeFn` (`:126`) |
| Verbatim arm `Rz` (both levels) | direct `wd` rotation callee (the 4.1 phase replay, `SwapRouteEmit.cpp:600-606`) |
| Arm `cq_phi` collection (bounded) | `collectArmPhis` (`SwapRouteEmit.cpp:104`) — unchanged, per level |
| Diagonal-alias closure (criteria 4/5) | `diagonalAliasHit` (`ArmClassify.cpp:205`) — **promote to `ArmAnalysis.h`** (WI-0/MD1: today anon-ns, unlinkable from new TUs) |
| Condition provenance (+angle exclusion) | `condProvenance` (`ArmClassify.cpp:159`) — **promote to `ArmAnalysis.h`** (WI-0/MD1) |
| Per-arm class (PASS 1) / homogeneity (PASS 2) | `walkPhaseSpine`/`walkValueChain`/`taintedAngleGate` (`ArmClassify.cpp:75/262/356`), re-hosted in `ArmHomogeneity` — **via `ArmAnalysis.h`** (WI-0/MD1) |
| Nesting metadata (Depth/ParentIdx/Mid) | `ControlRegion` fields (`ControlPlan.h:231,245-247`) — **reused**, +`ParentRail` |
| Taint scrub on erase | `scrubTaint` (`SwapRouteEmit.cpp:58-72`) |
| Loud decline | `diagnoseUnderControl` (`ControlDetect.cpp:41-46`) |
| Nested-decline detection entry | `recoverRegion` `RegionShape::Nested` (`ControlDetect.cpp:93-96,141-142`) — disposition flipped to prove-or-decline; **promote `recoverRegion`/`soleMergePhi`/`hasTaintedCondBranch`/`uncondSucc`/`RegionShape` to `ControlShape.h`** (WI-0/MD1) |
| Detection-loop claimed-br skip (blocker FA0) | `detectControlRegions` (`ControlDetect.cpp:191-200`) + new `SmallPtrSet<BranchInst*> Claimed` |

Deliberately **NOT** used in 4.3 (each a documented decision): `computeFreePoint`
(`FreePoint.h` — emitter-driven LIFO replaces post-dom for nested rails, §12.4);
`emitInverseChain` (no reverse-play for phase nests, §12.3 — returns with value
nests / `cq_invert`); `cqrt_copy_<W>` (4.2 value ABI; copying a phase nest
dephases, Rule 7); the `_controlled`/`cqrt_toffoli` family (§6a control-in-place
reserve — 4.3 keeps the routing, no conjunction ancilla, §12.2); per-region
`flattenRegion` (double-erases the shared merge — `flattenRegionTree` replaces it).

---

## 11. Out of scope (declines wired in WI-1, implemented in later increments)

Honestly listed (PRD §14); each declines loudly until its increment:

- **Outer `if/else` nesting** (else-nest / both-arm nest) — `nested control flow`
  (§12.4 invariant-(i) / §12.7 cap). The §4 routing + `flattenRegionTree` are
  framed for nesting in **one** arm; both-arm waits on two sibling subtrees.
- **Depth > 2** — `nested control flow` (§12.7). The two-flag traces generalize
  by the same parent-rail wire but are not auto-proven; a recorded deferral.
- **Value arms anywhere in the tree** — `mixed phase/value arm` / `value-arm
  swap-route` (§12.5). The value-nest needs the copy-out / reverse-play
  composition over the region tree (honest LIFO stack-unwind) with its own
  §8.2-style boundary + Rule-13 clearance; the union-§3c provenance is **built
  but inert** in 4.3 until then.
- **Multi-register nests** (inner condition outside the parent-routed closure) —
  `nested control flow` (criterion 5, now actively recognized — the disjoint-
  qubit sub-case could lower under the same emitter but the 4.3 contract targets
  the same-lineage shape and declines the rest conservatively).
- **Nested `select` / `switch`** — `select` / `switch` (4.4/4.5 unbuilt;
  fired on the inner construct before nested recovery).
- **§6a control-in-place peephole for the nest** — reintroduces the
  `cqrt_toffoli` conjunction + ordered uncompute (the old bug class); explicitly
  not the 4.3 mechanism.

Each currently declines loudly — a feature, not a gap (Prime Directive).
