# IMPL — Track P: the prep merge-φ as a PHASE leaf (bd `3qps`) + the ROOT-ONLY widening (bd `4aiu`)

Session 2026-09-14. Worktree `/Users/sorenwilkening/Desktop/CQ_phiphase`, branch `mergephi-phase-leaf`,
created off `main` `607b6fe4` (docs-only over the pass at `59ac5b7`). ORACLE hashes verified against
`PROTOCOL.md` before the first measurement. Gate lines: `GATES.md` (a gate result is a fact about a
BINARY — cite by hash, never by memory).

---

## 0. HEADLINE — one grammar, two consumers, and the emitted stream is the shipped one

**bd `3qps`** — `if (b1) cq_phi(θ)` where `b1` is a preceding controlled state PREP's merge φ — **now
lowers**. **bd `4aiu`** — a prep merge φ at an **INTERIOR** position of the `and`/`or`/`xor` condition
tree — **now lowers, at BOTH consumers** (the 4.4 data select and the branch phase).

Both are ONE predicate: Track M's `preppedRailPhiRegionIdx`, moved out of `SelectClassify.cpp`'s
anonymous namespace and declared in `SelectClassify.h`, **called** by each consumer and re-derived by
neither (Rule 14; the drbq Inc-3 (b′) defect was a second spelling of a predicate the tree already owned).

**The widening adds an ACCEPT, not a STREAM**, and that is measured rather than argued — see §4.

---

## 1. The predicate as actually spelled, and the proof that it is ONE spelling

`ir-pass/include/SelectClassify.h`:

```cpp
bool isCondRailPhiShape(const llvm::Value *V);                       // syntactic half (unchanged)
unsigned preppedRailPhiRegionIdx(const llvm::PHINode *P,             // SEMANTIC half — NEW: exported
                                 const ControlPlan &plan);
```

`preppedRailPhiRegionIdx` is **byte-for-byte the function Track M shipped** (`59ac5b7`); the only edit is
that the anonymous-namespace closer moved from *after* it to *before* its comment block, so it now has
`cq`-namespace linkage. Its body was not touched:

```cpp
for (i in plan.Regions)
  if (R.Kind == BranchRegion && R.Merge == P &&
      ((R.ClassArm      == ArmClass::InPlaceRotation && !R.Shadow.empty()) ||
       (R.ClassArmFalse == ArmClass::InPlaceRotation && !R.ShadowFalse.empty())))
    return i;
return ControlRegion::kNoParent;
```

**The proof that there is exactly one spelling** is a grep, not a claim:

```
$ grep -rn "preppedRailPhiRegionIdx" ir-pass/ | grep -v '^ir-pass/test'
ir-pass/include/SelectClassify.h:108:  # (a comment)
ir-pass/include/SelectClassify.h:179:  unsigned preppedRailPhiRegionIdx(...)          <- THE declaration
ir-pass/include/ArmAnalysis.h:435:     # (a comment)
ir-pass/src/ArmClassify.cpp:5378:      # (a comment)
ir-pass/src/ArmClassify.cpp:5426:      if (preppedRailPhiRegionIdx(P, plan) == ...) <- consumer 2, the KICKBACK
ir-pass/src/SelectClassify.cpp:562:    unsigned preppedRailPhiRegionIdx(...) {      <- THE definition
ir-pass/src/SelectClassify.cpp:1020:   const unsigned PrepIdx = prepped...(P, plan); <- consumer 1, the SELECT
```

Two call sites, one definition, no re-derived conjunct anywhere. The kickback's step 5c asks the same
three rungs the select's §M.0 asks, through the same helpers, with the **branch** as the read point
instead of the select:

| rung | select (§M.0, Track M) | kickback (step 5c, this increment) |
|---|---|---|
| 0 | `preppedRailPhiRegionIdx(P, plan)` | **the same call** |
| (i) | `taint.Tainted.count(P)` | the same |
| (ii) | `railMeasuredBeforeReadPoint(name, Sel, …)` over `condProvenance(P)` | the same, read point `Pred->getTerminator()` |
| (iii) | gate 2c, `RailProv` seeded from `condProvenance(P)` | `condWireDisposition` over `Prov`, seeded from `condProvenance(P)` |

**Rung (iii)'s one deliberate difference, and it is an L3 answer.** The kickback's wire ternary
(`RailCond ? railCondWireDisposition : condWireDisposition`) was **left exactly as it was**: `RailCond` is
a `CallInst *` and stays one, so a φ falls to the **compare** arm, which is *strictly more conservative*
— it adds the same-block positional scan (the φ is the first instruction of `Pred`, so its window to the
branch is bounded and real) and the `ShareCondFlag` prong (vacuous here: nothing is minted for a φ).
`railCondWireDisposition` drops those two on a ground argued about a `cq_theta_i1` **name** (M-C's G6
refusing the in-place `add`/`xor` conversion on a register read later by its own branch); transplanting an
unmeasured structural argument onto a different species is how an over-accept ships. L3 says the answer to
"what other predicate names the same object" is **not always "narrow it too"**.

### 1.1 Everything that changed, by file

| file | change | lines (approx) |
|---|---|---|
| `include/SelectClassify.h` | export `preppedRailPhiRegionIdx`; re-document `AllowRailPhi` (ROOT-ONLY retired) and re-arm the `RailPhiLeaves` obligation note for TWO callers | ~50 (almost all rationale) |
| `src/SelectClassify.cpp` | close the anon namespace before the helper; drop `V == Root` from the φ clause; `PrepIdx` → `PrepIdxs` (one per leaf) | ~20 |
| `include/ControlPlan.h` | `unsigned PrepRegionIdx` → `SmallVector<unsigned,2> PrepRegionIdxs` + why | ~20 |
| `include/ArmAnalysis.h` | `classifyPhaseKickback` gains `const ControlPlan &plan` + the order proof | ~18 |
| `src/ArmClassify.cpp` | `AllowRailPhi=true`; φ leaves in the size bound; **step 5c**; φ provenance into `Prov`; the φ positional scan; the string-partition constant | ~75 |
| `src/ControlDetect.cpp` | pass `Plan` at the one call site | 1 |
| `src/SwapRouteEmit.cpp` | read the condition off the LIVE anchor (`CondV`); `AllowRailPhi=true` in the emitter's re-derivation; `RailPhiCond` → `Flag`/`FlagIsRail`; ONE edge per `PrepRegionIdxs` entry | ~35 |
| `src/CondTreeEmit.cpp` | `isRailFlag` (rail **or** a φ in THIS tree) at the three rail tests; `emitCondNode` records a φ control read | ~35 |

**0 new frozen symbols. 0 new runtime templates. No new emitter.**

---

## 2. L1 — the round-2 window

**The question:** control detection + lowering run TWICE (`repropagateControlMerges`). Does rung 0's
lookup consult a verdict that exists at round 1, at round 2, or both — and what happens if a region enters
the plan only in round 2?

**The answer, in three parts.**

**(a) Which round produces the verdict.** Rung 0 reads `plan.Regions`, and `plan` is the SAME object in
both rounds' `detectControlRegions`. The verdict it needs — a `BranchRegion` with `ClassArm ==
InPlaceRotation` — is committed by `classifyArms` *in the same round and the same pass over the blocks*
that then classifies the φ's consumer, because `detectControlRegions` handles each block's TERMINATOR
first and the prep's `br` lives in `Pred` while the φ and the `br` that reads it live in the MERGE block,
which is later in block order. So for a given round the answer is ALWAYS "this round".

⚠ And the plan is FRESH per round, which is what makes "this round" a safe answer rather than a lucky
one: `repropagateControlMerges` does `ControlPlan plan2 = detectControlRegions(M, wd, taint);` — by value,
a new plan, no cached block or region pointers (`TaintPropagation.cpp`'s own note: *"pure analysis by SSA
identity (fresh `ControlPlan`+`Claimed` per call, no cached block …)"*). So rung 0 can never match a
round-1 region whose blocks a flatten has since erased, and there is no heap-address-reuse hazard in the
`R.Merge != P` pointer compare. This is a property of the CALLER, not of rung 0 — if a future round ever
reuses a plan, rung 0's comparison becomes a pointer compare against freed memory and must be re-derived.

**(b) What round 2 can add.** `repropagateControlMerges` re-seeds taint from the 6.5 classical-call-arm
and 4.5 switch data-mux `%out` rails only — `TaintPropagation.cpp`'s `if (taint.UntaintedMergeRails.empty())
return;`. A prep diamond's merge φ is neither, so **a region that a φ consumer depends on cannot appear
for the first time in round 2**: the prep's `br` is tainted from `cq_theta` directly, in round 1.

**(c) What happens if it did anyway.** The lookup finds no region and the consumer declines LOUDLY — the
Prime-Directive outcome, never a miscompile. There is no third path: `classifyPhaseKickback` either
returns `Accept` (pushed) or `Declined` (diagnosed); a `NotApplicable` φ condition falls through to
`recoverRegion`, which has its own loud decline.

**(d) The records this increment writes, and where they are re-asked.** `emitKickbackGroup`'s
`markRailCondRead(taint, Ctl, G)` now fires for a φ control (`CtlIsRail` is true for it), and
`emitCondNode`'s `record` was widened to a φ for the same reason. Both land in
`taint.RailCondReads`, which is `pair<WeakTrackingVH, WeakTrackingVH>` — **and a `WeakTrackingVH` FOLLOWS A
RAUW**. The prep's M-β RAUWs the φ to the hoisted `cq_theta_i1` CALL *inside* `lowerControlRegions`, i.e.
before `reverifyRailCondReads` runs, so `E.first` is a `CallInst` by the time the reader's
`dyn_cast<CallInst>` looks and rungs (ii)/(iii) **ARE** re-asked on the right register. This is bd `boi6`
site 12's argument, unchanged, with one more customer. ⚠ Its RETIREMENT TRIGGER is the one that header
already carries: re-derive it the day M-β's RAUW target stops being a theta.

**(e) Taint growth.** This increment manufactures **no** tainted value (unlike `MergePhiPeel`); it only
admits an existing one as a leaf. `adjudicateTaintDelta` has no new subject.

---

## 3. L2 — every predicate that enumerates leaves, with a per-row verdict

*"When you WIDEN a set, ask what OTHER set was computed over the same closure"* — and (L3) the answer is
not always yes. Enumerated by grep over `ir-pass/src` at the implementation tip, every row decided:

| # | site | enumerates | verdict | why |
|---|---|---|---|---|
| 1 | `collectCondTree` φ clause | the grammar | **WIDENED** (drop `V == Root`) | bd `4aiu` — this is the increment |
| 2 | `classifySelectRegion` rung 0/(i)/(ii) loop | `RailPhiLeaves` | already a LOOP — no change | per-leaf from the start |
| 3 | `classifySelectRegion` gate 2c seed | `RailPhiLeaves` → `RailProv` | already a LOOP — no change | per-leaf from the start |
| 4 | `classifySelectRegion`'s `RailLadderProven` | `RailPhiLeaves.empty()` | no change | already the `\|\|` |
| 5 | `ControlRegion::PrepRegionIdx` | ONE index per REGION | **WIDENED to a LIST** | a tree may now carry several φ leaves, each with its own prep and its own precedence edge. A scalar silently kept the LAST. Pinned by `control_swap_accept_select_mergephi_two_tree_leaves.ll` |
| 6 | `lowerControlRegions`' F-M1 edge loop | `PrepRegionIdx` | **WIDENED** (inner loop) | same reason; the loud out-of-range check is kept per entry |
| 7 | `classifyPhaseKickback` leaf-count bound | `Leaves + RailLeaves` | **WIDENED** (+ `RailPhiLeaves`) | each φ leaf is a live control rail between mint and strip |
| 8 | `classifyPhaseKickback` step 5b | `RailLeaves` | no change | a φ is not a `CallInst`; step 5c is its twin |
| 9 | `classifyPhaseKickback` `Prov` seed (IsTree) | `Leaves + RailLeaves` | **WIDENED** (+ `RailPhiLeaves`) | ⚠ **the whole increment's over-accept if omitted** — a φ leaf contributes to `Prov` through no other clause, so the wire walk would never look at the prepped register |
| 10 | `classifyPhaseKickback` `Prov` seed (!IsTree) | `condProvenance(Region.Condition)` | no change | for a φ root that IS `condProvenance(φ)`, by construction |
| 11 | `classifyPhaseKickback` per-leaf positional scan | `Leaves` | **WIDENED** (+ `RailPhiLeaves`, with an in-`Pred` requirement) | the root scan's window does not cover a leaf defined before it. Deliberately the COMPARE treatment, not the rail's (§1's L3 answer) |
| 12 | the wire ternary `RailCond ? rail… : cond…` | `RailLeaves.front()` | **NOT widened** | L3 — `condWireDisposition` is strictly more conservative and both its extra prongs have a live subject for a φ |
| 13 | `classifyPhaseKickbackNest` (5 sites) | `RailLeaves` | **NOT widened** | passes `AllowRailPhi=false` ⇒ `RailPhiLeaves` is always empty ⇒ no subject. Pinned by `control_phase_kickback_reject_mergephi_nest.ll`. ⚠ **ROUND 1 (F-P1-3 §2): this row cannot be reached from C at all** — `-O1` flattens `if (b1) { if (q>3) … }` into the flat `b1 && q>3` tree, which is bd `4aiu`'s intended ACCEPT (probe `r14`, 17 lines). So the row rests ENTIRELY on the hand-IR fixture plus a reading of both `collectCondTree` call sites (detect `ArmClassify:5827/5829`, emit `SwapRouteEmit:2166/2167`). Say that rather than implying a C witness exists |
| 14 | `classifyAngleSelect` | `Leaves + RailLeaves != 1` | **NOT widened** | measured safe two ways: `!Tree.Nodes.empty()` rejects any tree with a φ **leaf**, and `Cond != Sel->getCondition()` rejects a bare φ. Probes `d_angle`/`d_angle_ry`: `rotation angle` on BOTH binaries, identical |
| 15 | `Specialization.cpp` | `RailLeaves \|\| RailPhiLeaves` | no change | Track M already added the φ skip |
| 16 | `SelectMergeEmit`'s re-derivation | `collectCondTree(Cond, Tree)` default flags | **NOT widened** | by emit time M-β has made the φ a CALL. If it has NOT, the walk returns false and the H-1 backstop declines LOUDLY — which is the check, not an accident |
| 17 | `SelectMergeEmit`'s `RailLadderProven` backstop | `RailLeaves` | no change | same reason |
| 18 | `emitCondNetwork`'s three rail tests | `isCondRailLeaf` | **WIDENED** to `isRailFlag` = rail ∨ **membership of THIS tree's** `RailPhiLeaves` | membership, not shape: three of the four consumers pass `AllowRailPhi=false`, so their trees carry no φ and they keep the `Malformed` loud decline they have today |
| 19 | `emitCondNode`'s `markRailCondRead` | `isCondRailLeaf(Ctl)` | **WIDENED** (∨ `isCondRailPhiShape`) | at the PHASE consumer the φ is still a `PHINode` when the node's toffoli reads it, so a rail-only test left a user-register control read with NO record. ⚠ **THE REASON GIVEN HERE WAS WRONG — round-1 finding F-P1-5, corrected in source.** *"Over-recording only ever declines more"* is FALSE for a value that stays a `PHINode`: `reverifyRailCondReads` SKIPS it at its `dyn_cast_or_null<CallInst>`, so an over-recorded φ declines nothing — the skip is INERT, not conservative. The shape test is nonetheless right, on a MEMBERSHIP identity: `N.L`/`N.R` can be a `PHINode` only when it is a `RailPhiLeaves` member, because `FlagOf[V] = V` (the `isRailFlag` arm of `emitCondNetwork`'s walk) is the only path that maps a value to itself. Shape ≡ membership AT THIS SITE. What makes the record useful at all is M-β: it RAUWs the φ to the hoisted theta CALL before the re-verification, and the `WeakTrackingVH` follows it (see row 24) |
| 20 | `emitCondNetwork`'s `Out.RootIsRail` | `isCondRailLeaf(Root)` | **WIDENED** via `isRailFlag` | **VERDICT RIGHT, NARRATIVE WRONG — round-1 finding F-P1-4, corrected in source.** The stated hazard (*"a φ root reaching this function would return `RootIsRail=false` and the kickback would `cqrt_x`-BRACKET the user's register"*) **could not have occurred through this field**: `emitPhaseKickbackRegion` computes `FlagIsRail = IsTree ? Net.RootIsRail : (RailCond != nullptr \|\| RailPhiCond != nullptr)`, and a φ root takes the `!IsTree` arm, **which never reads `Net.RootIsRail`**. What keeps `cqrt_x` off the user's register here is that `\|\|`. Unreachability is also stronger than stated: `collectCondTree` records a φ root as a leaf and `continue`s ⇒ `Tree.Nodes` empty ⇒ `IsTree` false ⇒ the ONE `emitCondNetwork` call site that passes `AllowRailPhi=true` (`SwapRouteEmit:1896`, inside `if (IsTree)`, `CopyRailRoot=false`) is not called at all; the other three pass `AllowRailPhi=false`. **Of the three `isRailFlag` uses in `CondTreeEmit.cpp`, only the in-walk `FlagOf[V] = V` has a φ subject** — `CopyRoot` and `Out.RootIsRail` have none. The widening stays (one spelling, Rule 14) and is honestly labelled defence in depth. Rule 7 itself is MEASURED, not argued: **0 `call void @cqrt_x(` across every shipped φ PHASE accept** — 10 at review time, **11 re-measured at the fix tip** with `…_tree_leaf_data_use.ll` added — and on the two new φ SELECT accepts every `cqrt_x` targets the network's fresh `cqrt_alloc_i1(0)` root ancilla |
| 21 | `RegionFlatten`'s "never erase a user's rail" (3 sites) | `isCondRailLeaf \|\| isCondRailPhiShape` | **no change — and, MEASURED, it STILL has no subject** | Track M added the φ predicate as defence in depth with no subject and a retirement trigger naming "the first widening which gives a φ-conditioned region a `Pred`/`MergeBB` of its own". This increment IS that widening, so the trigger was followed and the COUNTERFACTUAL run: with the conjunct REVERTED and the pass rebuilt, all three φ accepts lower to BYTE-IDENTICAL IR, exit 0, clean under `libgmalloc`. **The claim that it now has a subject would have been FALSE** — §7.1. The conjunct stays (an unexercised guard on a UAF path is cheap); the record does not overstate it |
| 22 | `MergePhiPeel`'s `isCondRailLeaf`-keyed P7b | peel eligibility | no change | the peel runs BEFORE detection and decides about a *merge* φ, not a *condition* φ |
| 23 | `AngleSelectEmit`'s `isCondRailLeaf` | its own stem | no change | reached only through row 14, which refuses a φ |
| **24** | `classifyPhaseKickback` **step 5a**, `for (CmpInst *Leaf : Tree.Leaves)` — the six per-leaf gates (predicate lowerable, Q+Q, `compareFlagMintable`, tainted, i1-operand, in-`Pred`) | `Leaves` | **NOT widened** | a φ needs none of them: it mints nothing, so "predicate lowerable"/"mintable"/"i1-operand" have no subject, and its taint + position gates are step 5c's and row 11's. Step 5c IS this loop's twin, gate for gate |
| **25** | `condCmpMeasuredBeforeReadPoint(Tree.Leaves, …)` — the ONE call inside `classifyPhaseKickback` (`ArmClassify:5606` at the fix tip; `:5489` at the implementation tip — cite the CALL, not the line) | `Leaves` | **NOT widened** | the φ twin is step 5c's rung (ii), asked over `condProvenance(P)` rather than over the compare's operands — the same question, the closure the φ actually has |
| **26** | step 6's **`TreeSet` "condition used outside the branch"** fence | `Leaves` + `Nodes` | **NOT widened — and this one CHANGES THE ACCEPT SHAPE** | ⚠ so a φ leaf may have arbitrary out-of-branch DATA uses. MEASURED asymmetry: a COMPARE leaf with a use outside the branch declines `condition used outside the branch` (probe `r25`); the φ-leaf twin **ACCEPTS** (probe `r08`, 21 trace lines, STRICT 2b `4 / 3, 3 free sites: 3 verified, 0, 0`). **SOUND, and the argument is the RAIL leaf's, one construct over** (`ArmClassify` step 5b's header states it for both species now): the fence protects a flag this emitter MINTS, STRIPS and FREES inside the region — an out-of-tree reader would read a freed rail — while a φ leaf mints NOTHING (`FlagOf[V] = V`; the node reads it in a `cqrt_toffoli` CONTROL slot, diagonal and basis-label-preserving), so the data use lowers through the ordinary opcode net with its own `_unc` and free. **Now PINNED** by `control_phase_kickback_mergephi_tree_leaf_data_use.ll`. ⚠ RETIREMENT TRIGGER: the day a φ leaf (or a rail leaf) acquires a mint of its own, add `RailPhiLeaves` (and `RailLeaves`) to `TreeSet` |
| **27** | `emitPhaseKickbackRegion`'s post-flatten CASCADE ERASE — `for (Instruction *N : llvm::reverse(Tree.Nodes))` / `for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))` (`SwapRouteEmit:2114/2119`) | `Nodes` + `Leaves` | **NOT widened — and the stake is the highest in the table** | erasing a φ leaf here would free the PREP REGION'S `Merge` before the prep is emitted (the hcrg edge puts the kickback FIRST), i.e. Track M's H-1 use-after-free with the roles reversed. A φ leaf is the user's own value, exactly like a rail leaf, and this loop tears down only what the network MINTED. The two SIBLING cascade-erase loops (`SelectMergeEmit:400/405`, `Specialization:412/417`) iterate `Nodes`+`Leaves` identically and have no φ subject at all — both re-derive their tree with the default `AllowRailPhi=false` |

⚠ **Rows 24–27 were MISSING from this table at the implementation tip and were added by Rule-13 round-1
finding F-P1-3.** L2's whole method is *enumerate, then decide every row*; a table that claims completeness
is worth its most-missing row, and row 26 was one — an accept shape that was sound, measured, and argued
nowhere. The enumeration is now MEASURED rather than recalled — `grep -rn 'Tree\.Leaves|Tree\.Nodes|Tree\.RailLeaves|Tree\.RailPhiLeaves' ir-pass/src/*.cpp` at the fix tip returns **62 non-comment lines** at the fix tip —
`ArmClassify` 27, `SelectClassify` 15, `SwapRouteEmit` 8, `Specialization` 7, `SelectMergeEmit` 3,
`CondTreeEmit` 2 (`collectCondTree`'s four `push_back` writers are among the `SelectClassify` 15) — and
every one of them maps to a row above.
```
$ for f in ArmClassify SelectClassify SwapRouteEmit Specialization SelectMergeEmit CondTreeEmit; do \
    grep -nE "Tree\.Leaves|Tree\.Nodes|Tree\.RailLeaves|Tree\.RailPhiLeaves" ir-pass/src/$f.cpp \
    | sed 's/^[0-9]*://' | grep -vE '^\s*//' | wc -l; done
```

---

## 4. The stream — measured, and the discriminator that says it did not move

`trackP/probes/p17.ll` and `p18.ll` are the **T1 pins**: the owner-shaped module *after* the prep's M-β,
i.e. with the φ already replaced by the hoisted `cq_theta_i1` call. **The frozen ORACLE accepts both**
(20 and 18 trace lines, STRICT 2b clean). Their streams and the SUBJECT's streams for the φ spelling are
BYTE-IDENTICAL except for exactly one line each:

```
$ diff p01.trace p17.trace            # the 3qps customer vs its T1 pin
5c5
< cqrt_ry_i1_controlled(h0, h1, -0x1p-1)      <- the real program's prep IS controlled
---
> cqrt_ry_i1(h1, -0x1p-1)                     <- the hand-IR twin has no region left to control it
```

Everything the widening contributes — line 6, `cqrt_rz_i1(h1, 0.3)`, the DIAGONAL kickback on the user's
prepped register with no mint, no bracket, no strip and no free — **the ORACLE already emits**.
`p05`/`p18` is the same story for the interior-leaf form (`cqrt_toffoli(rail, cmpflag, g)`; `rz` on `g`;
the self-inverse undo; one proven-`|0⟩` free).

Rule 7 / Rule 6, readable off every new golden: **no `cqrt_x` ever touches a user register** (the ¬ arm is
the diagonal `cqrt_rz_i1(h, −θ)` on `X·P(θ)·X = e^{iθ}·P(−θ)`, a global phase D2 already discards; `fneg`
is exact in IEEE); **no user register is freed** (`Ry(θ)|0⟩ ≠ |0⟩` — left allocated, never freed dirty);
every ancilla returns to `|0⟩` on **every** branch before its free.

---

## 5. H-1 and F-M1 — the dispositions, and the probe that pins each

### H-1 (the dangling plan condition) — **NO SUBJECT at this consumer, and it is a CHECKED fact**

Track M's H-1 was that `SelectMergeEmit` dereferenced `ControlRegion::Condition` (a raw `Value *`) after
the prep's flatten had freed the φ. At the kickback the ORDER IS THE OPPOSITE, and the reason is
structural: a `PhaseKickback` has real block fields, so `lowerControlRegions`' bd `hcrg` alias pre-flight
sees `A.Pred == B.MergeBB` and takes the sanctioned `sequentialChainAlias` edge
`Precedes[kickback] = {prep}` — **the kickback is emitted FIRST, while the φ is still live**, which is
exactly what it wants (the prep's later M-β RAUW rewrites the emitted gate's operand to the hoisted theta,
which `lowerRotations` then RAUWs to the `i32` handle).

**Nothing depends on that premise being remembered**, because the shape that would need a different order
cannot reach the emitter:

* `condWireDisposition` declines a condition defined outside `R.Pred` ("unbounded gap across blocks"), and
  the tree spelling asks the same of every φ leaf;
* "the φ is in `Pred`" ∧ "the φ is some region's `Merge`" ⟹ `Pred` **is** that region's `MergeBB` ⟹ the
  chain edge fires. The order is a THEOREM over two checks, not an assumption.

**ROUND 1 ATTACKED THE THEOREM AND IT SURVIVED — and it is STRONGER than stated above.** The reviewer
attacked the argument rather than the hardening and could not break it; the full chain, with no gap:

> `P->getParent() == Region.Pred` ∧ `preppedRailPhiRegionIdx(P, plan) = j`
> ⟹ `P` IS `plan.Regions[j].Merge` (the helper's own `R.Merge != P → continue`)
> ⟹ `P` lives in `Regions[j].MergeBB`
> ⟹ `kickback.Pred == prep.MergeBB`
> ⟹ `MergeBB ∈ doomedBlocks(prep)`
> ⟹ the `Aliases` test fires
> ⟹ **EITHER** `sequentialChainAlias` returns true (edge added, `Precedes[kickback] = {prep}`, kickback
> emitted FIRST with the φ live) **OR** `declineRegion` fires and the module lowers nothing.
> **There is no third outcome.**

The in-`Pred` premise itself is supplied for a TREE by the positional loop's
`P->getParent() != Region.Pred` conjunct and for a φ ROOT by `condWireDisposition`'s
`Cond->getParent() != R.Pred → DeclineNow` (`ArmClassify.cpp:2048`) — both read, both measured
(`review_r1_probes/r18`, `control_phase_kickback_reject_mergephi_cross_block.ll`).

**Corollary, and it widens a claim this record scoped too narrowly:** *"recording a `PrepRegionIdxs` edge
here would close a precedence CYCLE"* is true of **EVERY φ kickback that lowers**, not only of the probed
ones. The hcrg edge `Precedes[kickback] = {prep}` is present for every one of them by the theorem above,
so an F-M1-style `Precedes[prep] = {kickback}` would always be a 2-cycle. **There is no φ kickback that
lowers without the hcrg edge.** (Direction checked at the source: `Precedes[a].push_back(b)` means *A
first*, and `sequentialChainAlias`'s `A.Pred == B.MergeBB` is the kickback-as-A case.)

Pinned by **`control_phase_kickback_reject_mergephi_cross_block.ll`** (probe `p19`), which is the
adjacency broken by one empty block: loud decline, `condition predates a non-diagonal gate`.

**The emitter was hardened anyway**, per the brief: it now derives `Value *CondV = BI->getCondition()` and
uses `CondV` everywhere; `R.Condition` is from that point **pointer-compared only, never dereferenced**.
Previously `anchor()` did `dyn_cast_or_null<Instruction>(R.Condition)` — a `dyn_cast` on freed memory in
exactly the case the identity check exists to catch. ⚠ NOT "fixed" with a `WeakTrackingVH` (bd `boi6` H-1,
tried and wrong): the φ is legitimately REPLACED, not deleted, so a tracking handle would silently follow
the RAUW and HIDE the ordering premise instead of checking it.

### F-M1 (the inert region in the precedence graph) — **TWO dispositions, opposite directions**

* **The 4.4 SELECT** keeps Track M's fix and gets it **per leaf**: `PrepRegionIdxs` is now a list, and
  `lowerControlRegions` adds one "prep before me" edge per entry. Pinned by
  `control_swap_accept_select_mergephi_two_tree_leaves.ll` (probe `p21`, 20 trace lines) — two prepped
  rails as the two controls of one `cqrt_toffoli`, both edges taken.
* **The PHASE kickback records NOTHING, deliberately.** It is not inert: the `hcrg` chain edge already
  orders it, in the direction it needs. Adding the select's edge here would demand the OPPOSITE order and
  **close a precedence CYCLE**, declining the whole module through the Kahn backstop. Pinned by
  **`control_phase_kickback_mergephi_then_region.ll`** (probe `p06`), which puts a SECOND control region
  after the φ kickback so the graph carries a three-region chain: every emitter inserts positionally, so
  the stream is SOURCE order regardless of the schedule, and the CHECK block pins exactly that.

---

## 6. The one string that moved, and the one that must not have

`ir-pass-lit` caught a silent re-labelling that no amount of reasoning about the new fixtures would have:
admitting the φ at the GRAMMAR moves every φ that rungs 0/(i) then refuse **out of** `collectCondTree`'s
`IsCondTree` split, which is where its message used to come from. `control_phase_kickback_reject_bare_i1_
loop_phi.ll` (bd `boi6`, the loop-carried `_Bool` header φ) went from `branch phase on a bare i1
condition` to `control flow` **with no change of disposition** — precisely bd `boi6` H-8's hazard.

Step 5c therefore reproduces the split explicitly:

* the φ **is** the whole condition → `branch phase on a bare i1 condition` (the message that shape took on
  the ORACLE, and the honest one: a bare `i1` value this consumer does not lower);
* the φ is a **leaf of a tree** → `control flow` (a condition TREE the grammar cannot use).

**Result: the ONLY string that moves in this increment is the one whose DISPOSITION moves.** The
discriminator survives intact and is pinned by `control_phase_kickback_reject_mergephi_three_incoming.ll`
(green on BOTH binaries) alongside the shipped `trunc`/`zext`/argument (bd `r903`) and loop-header-φ
(bd `boi6`) residuals.

---

## 7. Fixtures and slices — the table, with each one's ORACLE verdict

**19 new `ir-pass/test` fixtures + 1 flipped (`git mv`, contents re-derived) + 4 e2e slices with goldens.**
(18 at the implementation tip `98951fa1`; the 19th, `…_mergephi_tree_leaf_data_use.ll`, was added by
Rule-13 round-1 finding F-P1-3(c) — see §13.)
Every accept was written FIRST and watched RED on the frozen ORACLE (Rule 12, red-green); every decline
mirrors its string character-for-character and is pinned by the `not` inversion on the RUN line, not by
IR-text negatives (Rule 12(b) — a `DS_Error` decline writes 0 bytes to stdout).

### 7.1 ACCEPTS (bd `3qps`, the PHASE consumer)

| fixture | shape | ORACLE at `59ac5b7` | now |
|---|---|---|---|
| `control_phase_kickback_mergephi_rail.ll` | the headline: `if (b1) cq_phi(θ)` on a prep φ, TRUE-edge arm | `branch phase on a bare i1 condition` | ACCEPT |
| `…_mergephi_rail_negated.ll` | the polarity `-O1` actually produces (prep on the FALSE edge ⇒ unconditional Ry + a CONTROLLED cancelling Ry) | same | ACCEPT |
| `…_mergephi_ifelse.ll` | both arm polarities; the ¬ arm is the DIAGONAL `rz(h, −θ)` — **ZERO `cqrt_x`** | same | ACCEPT |
| `…_mergephi_two_gates.ll` | two `cq_phi` in one arm (also `-O1`'s fold of two same-condition regions) | same | ACCEPT |
| `…_mergephi_sdagger.ll` | a chained theta on the register AFTER the region (`ProvenPostRegion`) | same | ACCEPT |
| `…_mergephi_then_region.ll` | a SECOND control region after the φ kickback — the F-M1 ordering probe | same | ACCEPT |
| `…_mergephi_phi_use_empty.ll` | the φ's ONLY user is this region's `br` | same | ACCEPT |
| `control_phase_kickback_rail_after_prep.ll` | **the T1 DISCRIMINATOR** — the same module AFTER M-β | **GREEN on the ORACLE too** | ACCEPT |

### 7.2 ACCEPTS (bd `4aiu`, the INTERIOR leaf)

| fixture | shape | ORACLE | now |
|---|---|---|---|
| `control_phase_kickback_mergephi_tree_leaf.ll` | `if (b1 && q > 3) cq_phi(θ)` — φ ∧ compare | `control flow` | ACCEPT |
| `…_mergephi_rail_tree_leaf.ll` | φ ∧ a plain `cq_theta_i1` RAIL — the two leaf KINDS compose | `control flow` | ACCEPT |
| `control_swap_accept_select_mergephi_tree_leaf.ll` | **the flipped fixture** (was `…reject…`), the 4.4 DATA select's interior leaf | `control flow` | ACCEPT |
| `control_swap_accept_select_mergephi_two_tree_leaves.ll` | TWO φ leaves in one `and` tree at the select — the `PrepRegionIdxs` list | `control flow` | ACCEPT |
| `…_mergephi_tree_leaf_data_use.ll` (**round-1 F-P1-3(c)**) | `if (b1 && q>3) cq_phi(θ);` **plus** `int z = (int)b1 + q;` — a φ leaf with an OUT-OF-BRANCH DATA USE. The step-6 `TreeSet` fence does not cover `RailPhiLeaves`, so this ACCEPTS where the COMPARE-leaf twin declines `condition used outside the branch`. Stream = review probe `r08`'s 21-line trace, byte for byte; STRICT 2b `4 / 3, 3 free sites: 3 verified, 0, 0` | `control flow` | ACCEPT |

### 7.3 DECLINES

| fixture | shape | ORACLE | now | who owns it |
|---|---|---|---|---|
| `…_reject_mergephi_chained_arm.ll` | the arm theta is CHAINED (one wire, two basis labels) | `branch phase on a bare i1 condition` | `condition predates a non-diagonal gate` | rung (iii) — bd `drbq.7`. **String moves, disposition does not** |
| `…_reject_mergephi_cross_block.ll` | the φ is not in the kickback's `Pred` — the ORDER fence | same | `condition predates a non-diagonal gate` | `condWireDisposition`'s cross-block prong |
| `…_reject_mergephi_measure_before.ll` | `cq_measure(b1)` before the branch | same | `condition measured before the control route` | rung (ii) over `condProvenance(φ)` |
| `…_reject_mergephi_unclaimed.ll` | a 2-incoming φ no region claimed | same | **same** | rung 0 |
| `…_reject_mergephi_three_incoming.ll` | a 3-incoming φ — off `isCondRailPhiShape` | same | **same** | the grammar; the DISCRIMINATOR |
| `…_reject_mergephi_nest.ll` | the same φ at the DEPTH-2 NEST | `control flow` | **same** | `AllowRailPhi` is false there (the L2/L3 row) |
| `…_reject_mergephi_value_arm.ll` | a VALUE arm's φ | `bare i1 register condition` | **same** | the value region declines FIRST (bd `fg9k`); the header says so rather than claiming rung 0's class conjunct |

### 7.4 e2e slices (STRICT stage 2b on every one)

| slice | lines | 2b |
|---|---|---|
| `slice_control_phase_mergephi.c` (the 3qps customer) | **20** | 6 mints / 5 left allocated, 1 free site: 1 verified, 0 violations, 0 unproven |
| `slice_control_phase_mergephi_int.c` (the `int` twin, MUST NOT MOVE) | **25** | 6 / 5, 2 free sites: 2 verified, 0, 0 — **byte-identical to the ORACLE's own trace** |
| `slice_control_phase_mergephi_tree.c` (the 4aiu customer) | **17** | 4 / 3, 2 free sites: 2 verified, 0, 0 |
| `slice_control_phase_mergephi_ifelse.c` (the Rule-7 non-negotiable at the LINK layer) | **9** | 2 / 2, 0 free sites, 0, 0 |

Two cross-checks were MEASURED, not asserted: `slice_control_phase_mergephi.expected.log` lines **7-17**
are `slice_control_cascade_two_bools.expected.log` lines **6-16** byte for byte (the value path did not
move), and the `int` twin's golden is byte-identical to the frozen ORACLE's trace for the same program.

### 7.5 Hygiene

* **Vacuity** (`probes/impl/vacuity_p.py`): 12 accept fixtures, **101 negative patterns** checked for the
  bd `qta2` path-collision failure (a bare `-NOT: <word>` matching the module's own `ModuleID` line) —
  **0 bad**; **0 named handles** (these fixtures' negatives are pattern-based, so that arm has nothing to
  check — reported as 0, never as "n/a", per PROTOCOL S3).
* **Counts in their own whole-file prefixes**, negatives pure — no positive `CHECK` line sits inside a
  negative prefix (the Rule-12(a) windowing defect).
* ⚠ **Duplicate-body scan owed at merge.** `control_swap_reject_select_mergephi_tree_leaf.ll` was
  `git mv`'d to `…accept…`. CLAUDE.md L8: *a merge can resurrect a `git mv`'d fixture* — one module under
  two names with contradictory verdicts, invisible to every review that ran before the merge. **The
  merge-and-gate agent must run a sha-256-over-non-comment-lines duplicate scan after merging this
  branch.** ⚠ **Round 1 RAN it on the branch** (sha-256 over each fixture's non-comment, non-blank lines,
  all 1946 files at `98951fa1`): `duplicate-body groups: 9`, **none of them a `mergephi` fixture** — so
  the `git mv` is clean and this branch carries no resurrection risk of its own. The 9 groups are
  pre-existing (`control_predmux_reject_selectform_rotation_{hop_chained,poison_arg}`,
  `spec_reject_callbr`/`spec_overaccept_probe_callbr_visible`,
  `control_angle_select_reject_cond_{alias,register}`, `control_swap_diamond{,_derived}`,
  `control_inplace_ry_reject_stale_diag_alias_{backward,forward}`,
  `control_swap_reject_nested_{inner_clobber,value_mixed}`,
  `lowering_measure_round2_sixfive_handle`/`control_classical_call_arm_accept`,
  `control_swap_ifelse{,_derived}`, `control_angle_select_{phase_constants,rz_cond_register}`) and at
  least two look deliberate — **for the merge agent's information, not this track's to fix.** The scan is
  still owed AFTER the merge, on the merged tree, because that is where a resurrection would appear.

---

## 8. Mutation (injection) matrix — Rule 12's real validation

`probes/impl/inject_p.py`, 11 mutations over the 12 accept fixtures:
`x-on-user-register` · `extra-free-on-user-rail` · `extra-uncontrolled-ry` · `cqrt_cswap-injected` ·
`branchphase-record-dropped` · `kickback-angle-negated` · `kickback-gate-removed` ·
`kickback-retargeted-to-user-rail` · `toffoli-pair-unbalanced` · `two-copies-swapped` ·
`prep-control-dropped`.

```
TOTAL applied 97   MISSED 0   N/A 35
```

**MISSED = 0.** The 35 N/A rows are structural absences, all named: `two-copies-swapped` ×10 and
`toffoli-pair-unbalanced` ×8 (fixtures with no copy/toffoli), and ×2 each for the kickback-specific
mutations on the two SELECT fixtures (which have no `cqrt_rz_i1`). An N/A is a HOLE IN THE MATRIX, not a
pass — recorded as such.

⚠ **A 0-MISSED first run is exactly what the history says not to trust** (bd `f8eu`: 57 missed over 17
fixtures; the r9e5/eqpx precedent), so the harness was CONTROLLED rather than believed: the UNMUTATED
lowered IR was run against all **69 (fixture, prefix) pairs** and **0 failed**. A harness whose `passes()`
returned False for an unrelated reason would have reported every mutation as "caught" and been vacuous.
The likely real reason for 0 MISSED is that these accepts are short enough for a `CHECK-NEXT` chain to pin
the whole stream, so `CHECK` alone catches most mutations and the dedicated prefixes are (deliberately)
redundant with it.

---

## 9. What this increment does NOT do — filings owed, each with its measurement

⚠ **No `bd` record was created or edited from this worktree.** The tracker is a shared Dolt DB and four
tracks are in flight; the orchestrator files. Each item below is stated with the probe that measures it so
it can be filed verbatim.

### 9.1 OVER-DECLINE — a φ leaf outside the kickback's own `Pred` (probes `p19`, `p20`)

`condWireDisposition` refuses a condition defined outside `R.Pred` ("unbounded gap across blocks"), and
the tree spelling asks the same of every φ leaf. That is the ORDER fence of §5 and it is Prime-Directive
correct, but it declines two shapes whose circuits are valid and whose emission order would in fact be
right (the Kahn chain schedules EVERY kickback before EVERY prep):

* a SECOND kickback on the same φ from a later block — `p20`'s sibling;
* TWO prep φ conjoined when the second prep's diamond pushes the first φ out of `Pred`:
  `if (b0) b1 = cq_theta(b1,.5); if (b0) b2 = cq_theta(b2,.9); if (b1 && b2) cq_phi(θ);` — **probe `p20`,
  MEASURED `condition predates a non-diagonal gate`**.

**Scope note, honestly — CORRECTED by Rule-13 round-1 finding F-P1-1; the reason that shipped here was
measurably FALSE and it was load-bearing.** The conclusion stands and the reason does not:

> At the KICKBACK at most ONE φ leaf can ever satisfy the in-`Pred` requirement, **because rung 0 is
> `preppedRailPhiRegionIdx`, which requires `R.Merge == P`, and a `ControlRegion` has exactly ONE
> `Merge` FIELD.** A second φ in the same merge block matches no region, returns `kNoParent`, and
> declines the whole tree — whatever block it lives in. So the per-leaf `RailPhiLeaves` loop is
> effectively single-leaf there today; the LIST in `PrepRegionIdxs` is exercised by the SELECT
> (`control_swap_accept_select_mergephi_two_tree_leaves.ll`), where block position is not constrained.

**What was wrong.** The reason given was *"because two distinct diamonds have two distinct merge
blocks"*. `-O1` **FUSES** two same-condition preps into **ONE** diamond whose ONE merge block carries
**TWO** prep φs — bd `b6ap`'s own construct — and **both are in the kickback's `Pred`**. Measured,
review probe `review_r1_probes/r07_two_phi_fused.c`:

```c
if (b0) { b1 = cq_theta(b1, 0.5); b2 = cq_theta(b2, 0.9); }
if (b1 && b2) cq_phi(0.3);
```
```
r07_two_phi_fused.s1.ll:
  br i1 %1, label %2, label %5            ; ONE diamond
5:  %6 = phi i1 [ %3, %2 ], [ false, %0 ] ; TWO prep phis, ONE block
    %7 = phi i1 [ %4, %2 ], [ false, %0 ]
    br i1 %8, …                           ; the kickback's Pred IS block %5
```

Today an even earlier fence absorbs the shape — `soleMergePhi` refuses a 2-φ merge, the region is never
recovered, and `r07` declines `nested control flow` **identically on both binaries**.

**Why the wrong reason mattered (L7 exactly).** It is what licensed two live design decisions — (a) *"the
kickback records NOTHING in `PrepRegionIdxs`"* and (b) *"the per-leaf `RailPhiLeaves` loop is effectively
single-leaf there"*. Both are correct, but a future agent re-checking them would check the STATED reason,
find "two diamonds, two merge blocks" trivially true, and conclude the premise still holds after
`soleMergePhi` or `MergePhiPeel`'s entry gate had been widened out from under it.

⚠ **RETIREMENT TRIGGER (now also in `ArmClassify.cpp` step 5c):** re-derive this the day `soleMergePhi`
admits a multi-φ merge, or `MergePhiPeel`'s entry gate peels an arm-defined incoming. **Two φ leaves in
one `Pred` is a MEASURED shape (`review_r1_probes/r07`), not a hypothetical** — the only thing between it
and a two-leaf accept is which φ happens to be the region's `Merge`.

**The fix, named so it is not bought by deleting the fence:** give the positional prong a real
CFG-bounded scan — every block on a path from the φ's block to `Pred`, visited-set bounded — instead of
the single-block window it has. That is a NEW WALK; it needs its own Rule-12 probe family and a Rule-13
round, and it must not be obtained by simply dropping the in-`Pred` conjunct. Pinned meanwhile by
`control_phase_kickback_reject_mergephi_cross_block.ll`, whose header carries the trigger.

**Why it is not in this increment (Rule 17, stated plainly):** it is neither bead's shape. bd `3qps`'s
customer is `if (b1) cq_phi(θ)` and bd `4aiu`'s is `(b1 && q == 5)`; both land. The control
`trackP/probes/p22.c` confirms the Grover-shaped `if (b0 && b1) cq_phi(θ)` over two UNCONDITIONALLY
prepped `_Bool`s has lowered since bd 3qlq.4 and is untouched, and `p23` shows the mixed φ ∧ rail tree
lowering now. The declined shape is the narrower "two CONDITIONALLY prepped bools conjoined".

### 9.2 Not widened, deliberately, each with a live decline fixture

* the depth-2 PHASE NEST (`classifyPhaseKickbackNest`) — `AllowRailPhi` stays false
  (`…_reject_mergephi_nest.ll`);
* the Ry-stem ANGLE select and `Specialization`'s forward-only copy — unchanged, measured identical on
  both binaries (`d_angle`, `d_angle_ry`: `rotation angle`);
* `AllowLogicalSelect` for the 4.4 DATA select stays FALSE (bd `xqgx` (3)), so `(b1 && q > 3) ? A : B`
  from plain C still declines on the logical-select NODE, not on the φ. The two flags are orthogonal;
  this increment moved only the φ one.

### 9.3 Still owned by their existing beads

`control_phase_kickback_reject_mergephi_chained_arm.ll` stays a DECLINE until bd `drbq.7`; the in-place-ARM
φ family stays declined until bd `3d8q` lands (⚠ **do not** "fix" either by narrowing the φ's rung-(iii)
seed to the arm theta alone — that cone is the only thing refusing the `3d8q` class, so narrowing it first
converts an over-decline into an OVER-ACCEPT). `control_phase_kickback_reject_mergephi_value_arm.ll` moves
when bd `fg9k` lands.

⚠ **WHICH SPELLING THAT WARNING IS ABOUT — round-1 finding, and the sentence above was too general.** For
the in-place-ARM φ shape a reviewer could actually BUILD (`review_r1_probes/r16_inplace_arm_phi.c`: a
second in-place Ry arm conditioned on a prep's merge φ), **Track P's rung-(iii) cone is not what refuses
it**. That region carries no `cq_phi`, so `classifyPhaseKickback` returns `NotApplicable` and the **ARM
classifier** declines it (`control flow`, byte-identical on both binaries). The warning is therefore about
the shapes that DO reach step 5c — a `cq_phi` region whose φ leaf's wire carries a chained arm theta
(`…_reject_mergephi_chained_arm.ll`, bd `drbq.7`) — and it should be read as scoped to those.

⚠ **AND THE FORWARD-LOOKING HALF, which this record did not carry and now does — a RETIREMENT TRIGGER for
bd `3d8q` (also written into `ArmClassify.cpp` step 5c).** Rung 0 admits a φ iff some region is committed
as `ClassArm`/`ClassArmFalse == InPlaceRotation` with a non-empty `Shadow`. **If `3d8q` lands and flips
the in-place-ARM φ to an ACCEPT, that region enters the plan with exactly that verdict — i.e. it starts
matching Track P's rung 0** — and step 5c's ladder (rungs (i)/(ii)/(iii) plus step 6's wire disposition)
becomes the SOLE fence in front of a NEW population. Re-derive the ladder against that population as part
of `3d8q`; this increment's Rule-13 clearance does not reach it.

### 9.4 A record CORRECTED rather than confirmed

bd `boi6`'s `RegionFlatten` φ guard was documented as "no subject today, added so the first widening which
gives a φ-conditioned region a flatten of its own cannot re-open the L9 hole in silence". This IS that
widening, the trigger was followed, and **the counterfactual came back NEGATIVE**: with the conjunct
reverted the three φ accepts lower to byte-identical IR, exit 0, clean under `libgmalloc`. The guard is
kept; the record now says it still has no subject rather than claiming this increment gave it one
(Rule 11 — a retirement trigger is a place to LOOK, never evidence that the thing triggered).

---

## 10. Targeted byte-compares — what did NOT move

Cheaper and sharper than the corpus for the families the brief named, and run on both binaries over the
SAME input (a sha over the full `cq-opt` output, so a decline's text moves it too):

| family | files | differ |
|---|---|---|
| `ir-pass/test/control_peel_*.ll` + `control_inplace_ry_*.ll` | **288** | **0** |
| `ir-pass/test/control_swap_*select*.ll` (every 4.4 select fixture, Track M's included) | **149** | **2** — and both are this increment's intended bd `4aiu` accepts (`…mergephi_tree_leaf.ll`, the flipped one, and `…mergephi_two_tree_leaves.ll`, the new one). **Every other select fixture is byte-identical.** |

e2e, run individually (PROTOCOL allows single slices in the implementer's loop; `^e2e-` as a layer is NOT
an implementer gate and was not run):

```
ran: ctest -R 'e2e-slice-control-phase-mergephi'                                   4/4 Passed
ran: ctest -R 'e2e-slice-control-cascade|…-stateprep-bool|…-under-int-compare-fused' 9/9 Passed
```

That 9 covers every "must stay byte-identical" slice the brief named: the cascade family (`…two_bools`
29 lines, `…_base` = `va` 19, `…_uncond` 28, `…_int` 28, the two in-loop ones) and
`slice_control_stateprep_bool_under_int_compare_fused` (22).

---

## 11. Gate lines — `ran:` / `cited:` (Rule 19: only what was executed)

```
ran: build (BOTH targets, cmake --build build -j8)          @ f7b65d8c (baseline = ORACLE, bit-identical)
ran: build (BOTH targets)                                   @ da71bba0 (first implementation)
ran: ctest -R ir-pass-lit                                   @ da71bba0  -> 1 FAILED (the bd boi6 discriminator)
ran: build (BOTH targets)                                   @ 2c5c8feb (string-partition fix)
ran: ctest -R ir-pass-lit                                   @ 2c5c8feb  -> 1/1 Passed, 262.70 s
ran: build (COUNTERFACTUAL, RegionFlatten guard reverted)   @ b0eec07e  -> guard NEGATIVE
ran: build (source restored)                                @ 2c5c8feb (hash returns — bit-exact revert)
ran: lit --filter per fixture, 19 fixtures                  @ 2c5c8feb  -> all green; mergephi family 38/38
ran: ctest -R '^e2e-slice-control-phase-mergephi'           @ 2c5c8feb  -> 4/4 Passed, STRICT 2b
ran: ctest -R '<the must-not-move slices>'                  @ 2c5c8feb  -> 9/9 Passed
ran: vacuity_p.py over 12 accepts                           @ 2c5c8feb  -> 85 patterns, 0 path collisions
ran: inject_p.py, 11 mutations x 12 accepts                 @ 2c5c8feb  -> 97 applied, 0 MISSED, 35 N/A
ran: inject harness CONTROL (unmutated IR, all prefixes)    @ 2c5c8feb  -> 69 pairs, 0 failures
ran: targeted byte-compare, 288 peel/inplace_ry fixtures    ORACLE vs 2c5c8feb -> 0 differ
ran: targeted byte-compare, 149 select fixtures             ORACLE vs 2c5c8feb -> 2 differ (both intended)
ran: corpus sweep ORACLE-vs-SUBJECT                         @ 2c5c8feb  -> see below
NOT RUN (not an implementer gate, PROTOCOL matrix): ctest -j6 -R '^e2e-', the full ctest,
NOT RUN: cq-opt-equivalence-full
```

⚠ **The box was under heavy concurrent agent load throughout** (`load averages: 395 / 276 / 173` at the
worst, `128` at the best). CLAUDE.md: contention causes false FAILURES, never false passes — so the green
results stand, and the TIMINGS are not comparable with any figure taken on a quiet box.

⚠ **`ir-pass-lit` ran at `2c5c8feb` with 1945 fixtures on disk; one more
(`control_phase_kickback_mergephi_phi_use_empty.ll`, and this record's own edits to two headers) landed
afterwards.** Fixtures do not change the binary, and that one was run individually — but the hand-off
`ir-pass-lit` line below is the one taken AFTER every fixture was in place. ⚠ **SUPERSEDED by §13.4**:
the round-1 fix added a 19th fixture and re-ran the layer on the SAME (bit-identical) binary —
`ir-pass-lit` 1/1 Passed in 56.94 s, `lit ir-pass/test` **1947 discovered / 1946 passed / 1 XFAIL**.
Cite that line, not this one.

---

## 12. The corpus sweep — and the SECOND finding, which only it could make

`probes/impl/corpus_p.sh` runs every corpus the PROTOCOL names (`ir-pass/test/*.ll`, every session's
`probes/` and `review_*_probes/`, this session's five track dirs) through BOTH binaries on the SAME
stage-1 file. A row is `<path>|<oracle>|<subject>`, where a verdict is `A:<md5 of the lowered IR>` or
**`D:<sha1 of the FULL stderr>:<message>`**.

⚠ **THE FULL-STDERR HASH IS THE WHOLE POINT, and PROTOCOL S3 says why**: the shared `corpus.sh`'s tag
regex renders the whole `cq_measure_<sfx>` decline family as an empty `D:`, so a decline→decline change
inside it is INVISIBLE. Hashing the stream closes that — and it is what produced finding F-P2.

### F-P1 (expected) — one fixture mover, attributable by string

`ir-pass/test/control_swap_reject_select_mergephi_tree_leaf.ll`: `D:…control flow` → `A:1fe84cf5`. That is
the bd `4aiu` widening on the file the increment deliberately flipped (`git mv`'d in the worktree; the
ORACLE checkout still holds the old name, which is why it shows here as a mover rather than a rename).
**No other `ir-pass/test` row moved** across 1434 rows swept, including all 19 sibling `mergephi` rows —
same md5, same stderr hash.

### F-P2 (UNEXPECTED, and it is a REGRESSION the sweep caught) — the φ declines lost their `!dbg`

`session-2026-09-14-orchestrator/trackL/probes/p1.c` — **bd `boi6.a`'s own probe**, the loop-carried
`_Bool` header φ — came back as a mover with **the SAME message text and DIFFERENT stderr hashes**
(`cb18646d` vs `90c92e8f`). Measured:

```
ORACLE: error: …/trackL/probes/p1.c:10:13: in function main i32 (): cq controlled lowering: branch phase on a bare i1 condition …
SUBJ  : error: <unknown>:0:0:               in function main i32 (): cq controlled lowering: branch phase on a bare i1 condition …
```

**The source location was gone.** CLAUDE.md Rule 1: *"Diagnostics carry the offending instruction's `!dbg`
so they are source-located"* — a message that points at `<unknown>:0:0` is not a usable diagnostic. The
cause: step 5c anchored on `declAnchor(Region)`, which returns `R.Condition`, **which for this construct
IS THE φ — and a merge φ carries no `!dbg`**. Before the increment the same programs were refused by
`collectCondTree`, anchored on `BI`.

**Fix:** one local anchor, `PhiAnchor`, used by every decline in this classifier that can now see a φ
condition — step 5c's three and the step-6 wire disposition. It is `BI` exactly when the condition IS a
merge φ (`!IsTree && !RailPhiLeaves.empty()`) and `declAnchor(Region)` otherwise, so **every pre-existing
compare/rail shape's message is byte-identical**. Verified: `trackL/probes/p1.c`'s stderr is now
BYTE-IDENTICAL to the ORACLE's; `p08` is located at `p08.c:7:9`, `p12` at `p12.c:6:9`, `p20` at
`p20.c:10:12`; the hand-written `.ll` probes with no debug info stay `<unknown>:0:0`, correctly.

⚠ **THE LESSON, and it is the reusable half.** A message-only comparison would have called this row a
non-mover. Two agents' worth of fixtures, a green 1946-fixture `ir-pass-lit`, a 0-MISSED injection matrix
and a byte-identical 288-fixture family ALL passed with the regression in place, because **not one of
them looks at a diagnostic's location**. Only the full-stderr byte-compare over a DECLINE row could see
it. That is PROTOCOL S3's instruction earning its keep on the first increment that used it.

⚠ **THE STRUCTURAL FORM OF THAT LESSON, which this record half-learned and round 1 (F-P1-2) made
explicit — state it plainly because it generalises past this increment: NO HAND-WRITTEN `.ll` FIXTURE IN
THIS TREE CAN EVER PIN A DIAGNOSTIC'S LOCATION.** `ir-pass/test/*.ll` carries no debug info, so every
decline in all 1947 of them reports `<unknown>:0:0` whether the anchor is right or wrong. That is not a
gap in coverage that more fixtures close; it is a property of the instrument. **The only instrument that
can see a location is a `-g`-compiled `.c` probe whose FULL STDERR is byte-compared against the oracle's.**
Two consequences carried forward: (1) a decline-location claim measured on `.ll` probes is not evidence —
row 14's *"identical on both binaries (`d_angle`, `d_angle_ry`)"* was exactly that, and was re-measured
from C as `r12`; (2) Track P's own `probes/run.sh` already compiles with `-g`, so the discipline is
"one `-g` `.c` probe per decline string", not "one more fixture".

⚠ **AND THE PREMISE HAS TWO HALVES.** *"A merge φ carries no `!dbg`"* is only half the failure mode: `-O1`
also stamps merge φs with a `!DILocation(line: 0, …)`, which yields **`file.c:0:0`** — a real file, line
zero, equally unusable. `PhiAnchor` covers both because it never reads the φ's location at all; a repair
that tested `Cond->getDebugLoc()` for null would have fixed only half the class. (Now recorded at the
`PhiAnchor` definition in `ArmClassify.cpp`.)

**THE THREE RESIDUAL φ-ANCHORED SITES — all measured with `-g`, all IDENTICAL on both binaries, so none
is this increment's regression, and all three are OUTSIDE `classifyPhaseKickback`** (inside it the repair
is COMPLETE — round 1 enumerated all 24 `diagnoseUnderControl` sites in the function and found every
`declAnchor`-anchored one vacuous for a φ root). Filed, not fixed here:

| probe | shape | message | location |
|---|---|---|---|
| `r12` | `if (b1) cq_phi(.3); else cq_phi(.7);` on a prep φ — `-O1` folds it to a `select` on the ANGLE with **no `!dbg`**; `classifyAngleSelect` anchors there | `rotation angle` | **`<unknown>:0:0`** |
| `r16` | the in-place-ARM φ (Track M's pinned F-M3) — refused by `classifyArms`, anchored on a line-0 φ | `control flow` | **`r16_inplace_arm_phi.c:0:0`** |
| `r22` | a kickback and a data select `-O1`-fused on ONE prep φ | `control flow` | **`…c:0:0`** |

**Newly-populated but unreached:** `lowerControlRegions`' `declineRegion` anchors on
`dyn_cast_or_null<Instruction>(A.Condition)`. Before this increment the only region kind whose `Condition`
could be a φ was `SelectRegion`, which the alias pre-flight cannot see (null block fields); a φ-conditioned
**`PhaseKickback` has real block fields**, so if `sequentialChainAlias` ever refuses one the module
declines at line 0. **Reachability is unproven in both directions** — round 1 could not construct it and
does not claim it is unreachable. Conversely `emitPhaseKickbackRegion`'s `anchor()` is SAFE, and the H-1
hardening is what makes it safe: it reads `CondV = BI->getCondition()`, which in the drift case is the
live RAUW'd theta call (with a real `!dbg`), never the freed φ.

⚠ **AND THE COST IS REAL: the sweep that found it was measuring the PRE-FIX binary**, so its rows are
recorded as `corpus_PARTIAL_2c5c8feb…` / `corpus_probes_PARTIAL_2c5c8feb…` — 1434 and 269 rows, stopped
deliberately rather than completed, because CLAUDE.md forbids relinking under a running measurement and
the box was saturated by five concurrent track agents (`load averages: 444`). The post-fix sweep is the
one to cite.

### 12.1 The POST-FIX sweep — 362 probes, 18 movers, **18 attributable, 0 unattributable**

At `283e3b3322a9a94c`, over every probe in this session's five track corpora plus `session-boi6`,
`session-r903` and `session-l4x4`, comparing **exit code + the FULL stderr bytes on declines + the lowered
IR on accepts** (`probes/corpus_probes_283e3b3322a9a94c.txt`, recipe in `/tmp`-free form at
`probes/impl/corpus_probes_only.sh`):

```
DONE 362 probes compared, 18 mover(s)
```

**16 are Track P's own probes** — the accepts `p01 p03 p04 p05 p06 p07 p13 p15 p21 p23 p25` and the
string-moves `p08 p09 p12 p19 p20` — every one in the §7 table and the probe README.

**The other 2 are bd `boi6`'s corpus, and they are the best independent confirmation in this record**
because nobody wrote them for this increment:

| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `session-boi6/probes/p14.c` | `bool b = 0; if (q > 3) b = cq_theta((bool)0, .9); if (b) cq_phi(.3);` — **bd `3qps`'s customer in its original `boi6` spelling** | `branch phase on a bare i1 condition` | **ACCEPT** |
| `session-boi6/probes/p5.c` | the CHAINED arm theta (`b = cq_theta(b, .9)` on a live rail) — **bd `drbq.7`'s shape**, the one bd `3qps` was carved away from | `branch phase on a bare i1 condition` | `condition predates a non-diagonal gate` — **same source location, disposition unchanged** |

That pair is the increment's thesis measured on somebody else's corpus: the shape whose wire is CLEAN
lowers, the shape whose wire is DIRTY still declines, and the discriminator between them is what the arm
theta's arg-0 is.

⚠ **`trackL/probes/p1.c` is NOT in this list** — F-P2 is closed, byte for byte.

⚠ **WHAT WAS NOT COMPLETED, precisely.** The `ir-pass/test/*.ll` half of the sweep did not finish at the
post-fix binary: the box was at `load averages: 574` from five concurrent track agents and the sweep was
running at ~3 rows/minute. It ran to **1434 of ~1930 rows at the PRE-fix binary** (finding F-P1 and
nothing else), and the post-fix run was stopped. Two things stand in its place and neither is a
substitute-by-assertion: (a) **`ctest -R ir-pass-lit` is green over all 1946 fixtures at the post-fix
binary**, and it is strictly stronger for that corpus — every fixture has its own RUN line and CHECKs,
where a corpus row has only a verdict and an md5; (b) the targeted byte-compares of §10 (288 + 149
fixtures, 0 and 2 differ). ⚠ **What neither covers is a diagnostic's LOCATION** — which is exactly what
F-P2 was — so the **merge-and-gate agent's corpus sweep on the merged binary (PROTOCOL matrix) must be run
and read, and the `ir-pass/test` half of it is the part Track P did not complete.**

---

## 13. Rule-13 ROUND 1 — the six items and what was done with each

`REVIEW_P_R1.md` (independent reviewer, 2026-09-14, 25 probes in `trackP/review_r1_probes/`) returned
**CLEAR-WITH-ITEMS: no over-ACCEPT and no silent miscompile.** All six items are documentation,
record-accuracy, hygiene or scope — **no predicate changed, and the binary is BIT-IDENTICAL across the
fix** (`283e3b3322a9a94c206eb94471e519e5c9e4ffd60c0917743519ae895a0b2daf` / `fa563f69…` before and after,
re-measured after `cmake --build build -j8`). Everything below is therefore a fact about the SAME two
binaries the review's verdicts are about.

| item | severity | disposition |
|---|---|---|
| **F-P1-1** — §9.1's "one φ leaf in `Pred`" reason is FALSE (`r07`: `-O1` fuses two preps into ONE diamond with TWO φs, both in `Pred`) | documentation, **load-bearing** | **FIXED.** §9.1 rewritten with the true invariant (`preppedRailPhiRegionIdx` demands `R.Merge == P`; a `ControlRegion` has ONE `Merge` field) + the retirement trigger; the same argument added at `ArmClassify.cpp` step 5c |
| **F-P1-3** — §3's table is not a complete enumeration; four leaf-enumerating sites missing, one of which (step 6's `TreeSet` fence) changes the ACCEPT SHAPE | documentation + 1 unpinned accept | **FIXED.** Rows **24–27** added (measured by re-grep, 62 non-comment reader lines); the `TreeSet` φ/rail exemption is now argued in `ArmClassify.cpp` at step 5b's header AND at the fence itself; **`r08` is COMMITTED as `control_phase_kickback_mergephi_tree_leaf_data_use.ll`** |
| **F-P1-2** — the `PhiAnchor` repair is complete inside `classifyPhaseKickback` and incomplete outside; a φ can also carry a LINE-0 `!dbg`; `.ll` fixtures cannot pin a location | hygiene (Rule 1) | **PART FIXED, PART FILED.** The line-0 half of the premise and the "no `.ll` fixture can pin a location" lesson are now in source (`PhiAnchor`) and in §12. The three residual sites are **outside this classifier, identical on both binaries, pre-existing** → FILED (below) |
| **F-P1-5** — `reverifyRailCondReads` silently skips a LIVE `PHINode` under a nulled-handle justification; row 19's "over-recording only ever declines more" is false for it | defence in depth | **FIXED as an EXPLICIT third case** (the brief's second option). `TaintPropagation.h`'s `RailCondReads` block now names all three cases and the retirement trigger; `ArmClassify.cpp`'s `continue` points at it; `CondTreeEmit.cpp`'s justification is replaced by the true one (shape ≡ membership at that site); row 19 corrected. **Not made LOUD, and the reason is stated rather than assumed** — see below |
| **F-P1-4** — row 20's hazard narrative is wrong (`FlagIsRail`'s `!IsTree` arm never reads `Net.RootIsRail`) | documentation | **FIXED.** Row 20 rewritten with the reviewer's stronger ground (only the in-walk `FlagOf[V] = V` has a φ subject; the `AllowRailPhi=true` call site sits inside `if (IsTree)` with `CopyRailRoot=false`) and Rule 7 restated as MEASURED (0 `cqrt_x` across 10 φ PHASE accepts). Same correction added at `CondTreeEmit.cpp` and at `SwapRouteEmit.cpp`'s `FlagIsRail` |
| **F-P1-6** — the in-loop φ kickback declines where the in-loop φ SELECT accepts | over-decline | **FILED, not fixed** (the brief's instruction). Write-up below |

### 13.1 Why F-P1-5 was closed as an explicit third case rather than a LOUD decline

Both were offered. The loud form was rejected on a **Rule-12 ground, not a convenience one**: the case is
unreachable from any input (rung 0 admits a φ only as some `BranchRegion`'s committed `InPlaceRotation`
`Merge`; that region's `emitInPlaceRotationRegion` always runs, every `return` in it being preceded by a
`diagnoseUnderControl` which EXITS — bd `br4a`; M-β then RAUWs the φ and the `WeakTrackingVH` follows), so
**no fixture can reach the new string**, and an unmirrored decline string is itself a defect class this
project names. A loud guard would also have moved the binary out from under round 1's clearance for zero
reachable benefit. What is shipped instead is the thing that actually decays: a written third case with
the M-β premise named as its **retirement trigger** — *the day any emitter can record a non-`CallInst`
control read whose value is not subsequently RAUW'd to a `cq_theta_*` call, this skip is a silent hole and
must become loud.* **Filed for the orchestrator as the follow-on** (see 13.2, item 3).

### 13.2 Filed for the orchestrator — three items, none of them fixed here

**(1) F-P1-6 — OVER-DECLINE: the in-loop φ kickback, where the in-loop φ SELECT accepts.**
Probe `review_r1_probes/r21_inloop_phi_kickback.c`: the prep is **outside** a bounded loop and
`if (b1) cq_phi(0.3);` is **inside** it.

```
SUBJECT : r21_inloop_phi_kickback.c:10:13 … condition predates a non-diagonal gate
ORACLE  : r21_inloop_phi_kickback.c:10:13 … branch phase on a bare i1 condition
```

String moves, **disposition does not**. Its SELECT twin is a **shipped accept**
(`control_swap_accept_select_mergephi_inloop_outside_prep.ll`), so the asymmetry is between two consumers
of the same leaf grammar. Same `condWireDisposition` cross-block family as §9.1's named over-decline, and
**it is the shape a rolled Grover phase kickback on a bool-controlled prep would take** — which is why it
is worth a bead of its own rather than a line inside §9.1. Owner ruling 2026-09-11 applies: an
over-decline is a defect to remove, not a margin. ⚠ The fix is **not** dropping the in-`Pred` conjunct
(§9.1 says why); it is the CFG-bounded scan, with its own Rule-12 probe family and Rule-13 round.

**(2) The three residual φ-anchored diagnostic sites** (`r12` `rotation angle` at `<unknown>:0:0`;
`r16` and `r22` `control flow` at `file.c:0:0`), all pre-existing and identical on both binaries, all
outside `classifyPhaseKickback`. Plus the **newly-populated, unreached** `lowerControlRegions`
`declineRegion` anchor — reachability unproven in both directions. Detail in §12.

**(3) The LOUD form of F-P1-5**, gated on a reachable input existing — see 13.1.

**Also recorded, pre-existing and identical on both binaries** (not a filing, a fact the F-M1 cycle
argument should be read against): `r22` — a kickback and a data select on ONE prep φ **DECLINES**, because
`-O1` fuses them into a single region carrying both a phase gate and a value merge φ, and `MergePhiPeel`'s
≥2-φ entry gate does not fire on a merge with exactly one φ. The three-region chain (kickback → prep →
select) is reachable only in the spellings `-O1` declines to fuse.

### 13.3 What round 1 verified independently, and what it did NOT examine

**Verified with its own witnesses** (not taken on this record's word): row 9 is load-bearing — probe `r06`
shows that without the `RailPhiLeaves` → `Prov` seed the kickback ACCEPTS riding a register a chained Ry
moved; the flag orthogonality holds byte-identically (`r13`); **no taint is grown**
(`grep -c "Tainted.insert\|adjudicateTaintDelta"` over the source diff → **0**, unlike `MergePhiPeel`),
and round 2 cannot introduce a prep region (`TaintPropagation.cpp:1653`); Rule 6 is clean under STRICT
stage 2b on every probe.

**Not examined — carried into round 2, which the reviewer calls WARRANTED:** the loop layer × φ condition
(`staleRailRecordRead`, `collapseRailPhisIn`, `invariantRegisterRoots` — touched only through `r21`, which
declined; *the largest unexamined surface*); the emitter side (`emitCondNetwork`/`stripCondNetwork` with
an interior φ) under INJECTION rather than reading; `classifyPhaseKickbackNest` with a φ from C (`-O1`
flattens — row 13 rests on the hand-IR fixture, and round 1 says so); the four e2e slices, their goldens,
`inject_p.py` and `vacuity_p.py` (this record's 0-MISSED matrix is unverified by the reviewer);
`-O2`/`-O3`, multi-function modules, and any width other than `i1`/`i32`; and **bd `3d8q` as landed**,
against step 5c's rung 0 (the trigger now written into §9.3 and into the source).

### 13.4 Gate lines for the round-1 fix — `ran:` / `cited:`

```
ran:   cmake --build build -j8 (BOTH targets)          @ fix tip -> cq-opt 283e3b33…, libCQPass fa563f69…
                                                          BIT-IDENTICAL to 98951fa1 (comments + 1 fixture only)
ran:   cq-opt on the new fixture's module, SUBJECT     -> exit 0, 21-gate stream == review probe r08's trace
ran:   cq-opt on the same module, frozen ORACLE        -> exit 1, `control flow` (red-green, Rule 12)
ran:   tools/free_pairing_check.py on that lowered IR  -> STRICT: 4 mints / 3 left allocated,
                                                          3 free sites: 3 verified, 0 violation(s), 0 unproven
ran:   lit ir-pass/test --filter 'mergephi_tree_leaf_data_use' -> 1/1 PASS (Total Discovered 1947)
ran:   ctest --test-dir build -R ir-pass-lit           @ fix tip -> 1/1 Passed, 56.94 s
                                                          (quiet box: load averages 4.47 / 16.54 / 52.55)
ran:   lit ir-pass/test (full, for the counts)         @ fix tip -> Total Discovered 1947;
                                                          1946 Passed + 1 Expectedly Failed, 91.55 s
cited: REVIEW_P_R1.md §0 binary identity (both binaries) — re-measured here and unchanged
cited: REVIEW_P_R1.md §5 duplicate-body scan (1946 fixtures, 9 pre-existing groups, 0 mergephi)
cited: REVIEW_P_R1.md §1/§2/§4 — every verdict in §13.3 above
NOT RUN (forbidden by the fix brief, and no subset can substitute): corpus sweep, full ctest,
NOT RUN: '^e2e-', cq-opt-equivalence, the loop twin matrix.
```
