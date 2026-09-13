# SCOPE — Track M: the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT (and the VALUE diamond) — bd `boi6` (D-B), probe `p20`

Session 2026-09-13, **READ-ONLY**. Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/`, `tools/`
was touched; nothing was built; no suite was run. Every verdict is measured against the **frozen
ORACLE** (`build/ir-pass/cq-opt` sha256 `fbbe0820ef4b176a…`, `libCQPass.so` `40e9c7a51e8120bb…`,
`e96f89c`, hash verified before each sweep by `probes/run.sh`). Repo `main` **`01c89b5`**; every line
number below was re-grepped at that commit (boi6's numbers are from `0c7380c`, l4x4's from the same —
several have moved).

Companions: `../probes/README.md` (§0 of the orchestrator prompt — extended, not re-measured),
`../../session-boi6/SCOPE_boi6.md` (D-A/D-B split, H-1…H-10), `../../session-l4x4/SCOPE_l4x4.md`
(the rail ladder this mirrors), `../PROTOCOL.md` (the "scoping" row: pipeline only, no gates).

---

## 0. HEADLINE — three measurements change the shape of the increment

### 0.1 The verdict table

Full 27-row table with the exact commands in `probes/README.md`. The rows that decide the scope:

| probe | shape | ORACLE verdict |
|---|---|---|
| `m01` | the owner's line 99, `if (b1) a -= 3;` | DECLINE `control flow` @ `%7 = select i1 %5, i32 %6, i32 %cq.peel.mux` |
| **`m09`** | **the same with `a -= 1`** | **ACCEPT**, 23 lines, STRICT 2b clean |
| **`m03`** | **`a += 1`** | **ACCEPT**, 23 lines |
| **`m07`** | **TWO selects, `a -= 3; a += 2;`** | **ACCEPT**, 23 lines |
| **`m11`** | **`int b1`, `bool b0`, + line 99** | **ACCEPT**, 28 lines |
| **`m12`** | **`int b0`/`int b1` + line 99** | **ACCEPT**, 31 lines |
| **`m18` (T1)** | hand IR = the module AFTER `emitInPlaceRotationRegion`'s M-β | **ACCEPT, 29 lines — THE TARGET STREAM** |
| `m17` (T1 in C) | the `b1` prep made UNCONDITIONAL | ACCEPT, 28 lines |
| `m20` (T2) | the `p5` shape at the select (φ over ONE wire, CHAINED arm theta) | DECLINE `control flow` @ the select — **the LEAF GRAMMAR, not the wire fence** |
| `m26` | `int b1` twin of the PHASE consumer `if (b1) cq_phi(.3)` | **ACCEPT**, 25 lines |
| `m08` | the `_Bool` PHASE consumer | DECLINE `branch phase on a bare i1 condition` @ the `br` |
| `m27` | the VALUE DIAMOND (arm writes memory, no if-conversion) | DECLINE `control flow` @ the `br` |
| `m05` | `cq_measure(b1)` BEFORE the select | DECLINE `control flow` @ the select (the grammar pre-empts rung (ii)) |
| `m21` | a tainted `xor i1` select condition, no region | DECLINE `control flow` @ the select |

### 0.2 The merge φ is ALREADY a quantum register to this compiler — only the `select` is refused

`m09` vs `m01` is the whole over-decline, on one binary: `if (b1) a -= 1;` **accepts** and
`if (b1) a -= 3;` **declines**. The reason is `-O1`, not semantics — a **±1** delta folds to
`add(a, sext/zext b1)`, i.e. straight-line tainted ARITHMETIC on the prep's merge φ with no control
region at all, while any other delta leaves a `select`. `m03`'s trace shows the φ being consumed as a
register today:

```
cqrt_ry_i1_controlled(h0, h1, -0x1p-1)        <- the prep (M-β's gate)
… the peeled a-mux merge …
cq_template_zext_i1_to_i32(h1) -> h6          <- THE MERGE φ, read as the handle h1
cq_template_add_i32(h3, h6) -> h7
cq_template_zext_i1_to_i32_unc(h6, h1) ; cqrt_free(h6)
```

So nothing about this φ is unproven as a *register*; the gap is a **LEAF-GRAMMAR gap at one gate**
(`collectCondTree`), exactly as `../probes/README.md` isolated it. And `m11`/`m12` show the owner has
an **`int` workaround** for line 99 today (which the owner has refused in as many words: *"WE DO NOT
WANT TO WRITE `int b1`"*).

### 0.3 The WIRE FENCE IS NOT THE SECOND BLOCKER for this shape — boi6 §0.3 does not transfer

`SCOPE_boi6.md` §0.3 measured that admitting the φ as a rail leaf "would buy `p5` nothing" because
`p5`'s `int` twin `p22` declines `condition predates a non-diagonal gate`. **That is true of `p5` and
false of the owner's file**, and the discriminator is what the arm theta's arg-0 is:

* `p5`/`m20`: the arm theta is **CHAINED** (`%armv`'s arg-0 IS `%seed`) ⇒ an in-place, non-diagonal
  Ry sits on the condition's own wire ⇒ `findNonDiagonalWireGate` answers dirty.
* the owner's file: the arm theta is a **SOURCE** (`cq_theta_i1(i1 false, .5)`), and the φ's other
  incoming is the constant seed. `condProvenance` (`ArmClassify.cpp:280`) gives `{φ, source theta}`;
  `walkNonDiagonalWireGates`' backward closure stops at a source theta's classical arg-0 and marks
  the producing theta **ON-ANCESTRY EXEMPT** (`WireWalk.cpp:380-405` comment), so the wire is CLEAN.

MEASURED, not argued: `m11`, `m12` and `m26` all ACCEPT, and their conditions are COMPAREs over
exactly that φ, so gate 2c and the kickback's `railCondWireDisposition` have both already answered
CLEAN on this wire. The same is therefore true of the rail spelling — including for the PHASE
consumer (`m08`), whose `int` twin `m26` lowers. **The phase consumer's decline here is the leaf
grammar at `ArmClassify`, not `drbq.7`'s wire fence.** (It stays out of Track M's scope by the
orchestrator's split, but the filing reason must be corrected: it is a leaf-grammar over-decline, and
`p5` remains `drbq.7`'s.)

### 0.4 T1 — the target stream, READ OFF THE ORACLE

`probes/m18.ll` is `owner.main.O1.ll` rewritten as the module `classifySelectRegion` would see it if
the prep region had already emitted: the a-mux peeled to `%cq.peel.mux`, the `b1` theta hoisted into
the entry block, the cancelling clone chained onto it, and `%6` RAUW'd to that clone
(`SwapRouteEmit.cpp:1105`, `MergePhi->replaceAllUsesWith(Gates.back().first)`). **The ORACLE ACCEPTS
it**, 29 trace lines, STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2
verified, 0 violation(s), 0 unproven`. The select half (`probes/m18.trace` lines 17–26) is the
payload:

```
17  cq_template_add_i32_hl(h2, -3) -> h6      ; the arm chain, HOISTED, lowered by lowerOps
18  cqrt_alloc_i1(0) -> h7                    ; the CopyRailRoot ancilla
19  cqrt_cnot(h5, h7)                         ; the rail-root CNOT copy  (h5 = the prep rail)
20  cqrt_alloc_i32(0) -> h8                   ; the fresh |0> out rail
21  cqrt_copy_i32_controlled(h7, h6, h8)
22  cqrt_x(h7)
23  cqrt_copy_i32_controlled(h7, h2, h8)
24  cqrt_x(h7)
25  cqrt_cnot(h5, h7)
26  cqrt_free(h7)                             ; x ⊕ x = 0 on every branch ⇒ proven-|0> free
```

**THE TARGET STREAM FOR THE OWNER'S FILE** is therefore `../probes/va.trace` lines 1–16 (unchanged —
`va` is the discriminator and must stay byte-identical), then lines 17–26 above with `h5 → h1` (the
prep rail) and `h2 → h3` (the a-mux `out`), then `measure_i1(h0)`, `measure_i1(h1)`,
`measure_i32(h8)`. **29 lines.** Two corrections to the brief's prediction, both measured:

* the hoisted `cq_template_add_i32_hl` is **NOT `_unc`'d and its rail is NOT freed** — it is the
  Rule-6 "value arm's chain-final rail left allocated" case (2b counts it among the 6 left allocated);
* `h1` (the prep rail) is read **only** as a control — never `cqrt_x`-bracketed, never freed; both
  `cqrt_x` are on the ancilla `h7`. `m19` (the un-negated prep) is the same stream minus the
  cancelling gate, 28 lines.

---

## 1. Every site, `file:line` at `01c89b5`, predicate verbatim

This table **updates** `SCOPE_boi6.md` §1 (whose numbers are `0c7380c`) for the SELECT/VALUE consumers.

| # | site | line @ `01c89b5` | today, verbatim | what the φ needs |
|---|---|---|---|---|
| 1 | `isCondRailLeaf` | `SelectClassify.cpp:543-549` | `dyn_cast_or_null<CallInst>(V)`; `!CI \|\| !CI->getType()->isIntegerTy(1)` → false; `F->getName() == "cq_theta_i1"` | **DO NOT WIDEN** (H-3). A new predicate. |
| 2 | `CondTree::RailLeaves` | `SelectClassify.h:88` | `llvm::SmallVector<llvm::CallInst *, 2> RailLeaves;` | **the TYPE is the enforcement — DO NOT RETYPE.** A new `RailPhiLeaves` field; the `SelectClassify.h:78` obligation ("⚠ EVERY CONSUMER THAT READS `Leaves` MUST DECIDE ON `RailLeaves` EXPLICITLY") then re-arms. |
| 3 | `collectCondTree` | `SelectClassify.cpp:551`; decl `SelectClassify.h:151` (`bool AllowLogicalSelect = false`) | rail test at `:568` **before** the `CmpInst` test at `:572` | a φ leaf behind a new `AllowRailPhi` flag — the `AllowLogicalSelect` precedent verbatim (one grammar, per-consumer verdicts). Default **false**. |
| 4 | **GATE 2 — the firing site** | `SelectClassify.cpp:781-782` | `if (!collectCondTree(Sel->getCondition(), Tree)) return diagnoseUnderControl(Sel, "control flow");` | every `m01`-class probe dies here. |
| 5 | the r9e5 **rail ladder** at the select | `SelectClassify.cpp:843-850` | `for (CallInst *Rail : Tree.RailLeaves) { if (!taint.Tainted.count(Rail)) … "control flow"; if (railMeasuredBeforeReadPoint(Rail, Sel, taint, DT)) … "condition measured before the control route"; }` — rung (i) + rung (ii), **read point = `Sel`** | a φ arm: rung 0 (claimable) + (i) + (ii) over the φ's **provenance closure**, not over the arm theta alone (H-2). |
| 6 | rung (iii), the wire — **gate 2c** | `SelectClassify.cpp:956-975` | `condProvenance(Rail, taint, RailProv)` per rail; then position-free `findNonDiagonalWireGate(RailSeeds, CrossValueRouting=true, EmitPoint=nullptr, DT=nullptr)` **AND** (`!DT \|\|` the same with `EmitPoint=Sel, DT`) ⇒ `"condition predates a non-diagonal gate"` | **ALREADY RIGHT for a φ** — `condProvenance` (`ArmClassify.cpp:280`) walks a φ's operands and stops at each theta, which is exactly the wire. MEASURED clean for this shape (§0.3). |
| 7 | `RailLadderProven` (set) | `SelectClassify.cpp:1115` | `R.RailLadderProven = !Tree.RailLeaves.empty();` | must become `… \|\| !Tree.RailPhiLeaves.empty()`, else the emitter backstop refuses the accept we just created. |
| 8 | `SelectMergeEmit` backstop | `SelectMergeEmit.cpp:130` | `if (!Tree.RailLeaves.empty() && !R.RailLadderProven) { … }` | the r9e5 round-1 tripwire; a φ tree must be refused here if it arrives unproven. |
| 9 | **`SelectMergeEmit`'s condition source** | `SelectMergeEmit.cpp:96` and `:215` | `if (!Sel \|\| !R.Condition \|\| !collectCondTree(R.Condition, Tree))` … `emitCondNetwork(R.Condition, Tree, …, /*Before=*/Sel, …)` | `ControlRegion::Condition` is a **RAW `Value *`** (`ControlPlan.h:115`). After the prep region's M-β + `flattenRegion` the φ is **ERASED**, so this is a DANGLING POINTER — **H-1**. Re-derive from `cast<SelectInst>(R.Merge)->getCondition()` (which M-β has already rewritten to the theta CALL). |
| 10 | `CondTreeEmit::emitCondNetwork` | `CondTreeEmit.cpp:137` `const bool CopyRoot = CopyRailRoot && isCondRailLeaf(Root);` · `:197-198` `if (isCondRailLeaf(V)) { FlagOf[V] = V; … }` · `:226` `Out.RootIsRail = isCondRailLeaf(Root);` · `:248` `markRailCondRead(taint, Rail, Cn);` | the 4.4 select asks with `CopyRailRoot=true` (`SelectMergeEmit.cpp:217`) | **NO CHANGE NEEDED under spelling (a)** — by emit time the condition IS a `cq_theta_i1` call (site 9), so this file never sees a φ. That is the single biggest cost saving versus `SCOPE_boi6.md` §6. |
| 11 | `markRailCondRead` | `ArmClassify.cpp:2383`, `Value *Rail` — already type-general | the 4.4 select's record is made at `CondTreeEmit.cpp:248` | records a φ fine; the READER is the question — site 12. |
| 12 | `reverifyRailCondReads` | `ArmClassify.cpp:2485`; the cast at **`:2504`** `auto *Rail = dyn_cast_or_null<CallInst>(E.first);` | a `PHINode` record is silently skipped | **FOR A FLAT MERGE φ THIS IS ALREADY SOUND, and the reason is worth writing down.** `RailCondReads` is `pair<WeakTrackingVH, WeakTrackingVH>` (`TaintPropagation.h:339-342`) and a `WeakTrackingVH` **FOLLOWS A RAUW**; M-β RAUWs the φ to the hoisted theta CALL *during* `lowerControlRegions` (pipeline `:456`), i.e. **before** `reverifyRailCondReads` at `CQLoweringPass.cpp:510`. So `E.first` is a `CallInst` by the time the reader looks, the cast succeeds, and rungs (ii)/(iii) are re-asked on the right register. ⚠ This is the EXACT case the header's own RETIREMENT TRIGGER (`TaintPropagation.h:334-338`) contemplates and declares benign-or-over-declining — cite it, and re-derive it if the RAUW target ever stops being a theta. boi6's **H-1 is an IN-LOOP hazard** (the collapse at `:473` retargets the record to the root mint); it has **no subject** in a flat region. |
| 13 | `RegionFlatten` "never erase a user's rail" | `RegionFlatten.cpp:96` `if (Cond && Cond->use_empty() && !isCondRailLeaf(Cond))`, `:189`, `:193` | `isCondRailLeaf`-keyed | **H-7**: the select's condition φ is erased by the PREP region's flatten (not the select's), so this guard has no subject for the φ; but the new predicate must be added anyway, or the first widening that makes a φ-conditioned region own its own flatten re-opens a block-lifetime hole. |
| 14 | `classifyArms`' rail ternary | `ArmClassify.cpp:3160` `const bool RailCond = isCondRailLeaf(Region.Condition);` · `:3325` `declineArm(declAnchor(Region), kBareRailCondReason);` · `:3154` comment "EQ-FOLD and VALUE classes keep `kBareRailCondReason` (bd `fg9k` …)" | a φ condition at a `br` takes **`control flow`** — MEASURED (`m27`, and boi6 `p32`) | **H-8, decide ONCE**: if the new predicate is wired into this ternary the string for `m27`/`p32` changes from `control flow` to `bare i1 register condition`. Recommendation in §3. |
| 15 | `InPlaceRotation`/prep accept — the ONE OWNER of "what this merge φ becomes" | `ArmClassify.cpp:4428` `Region.ClassArm = ArmClass::InPlaceRotation;` (`:4431` for the false arm), `Region.Shadow.assign(1, T);`, `:4445` `if (RailCond) Region.RailLadderProven = true;` | `ArmClass` is `{Phase, Value, InPlaceRotation}` (`ControlPlan.h:75`); **there is no `StatePrep` field** — the prep and the in-place arm share `InPlaceRotation` and `emitInPlaceRotationRegion` | `Region.Shadow.front()` is the `CallInst` M-β will leave (modulo the clone), available at CLASSIFICATION time. This is the field spelling (a) must CALL, never re-derive. |
| 16 | M-β, the RAUW | `SwapRouteEmit.cpp:1105` `MergePhi->replaceAllUsesWith(Gates.back().first);` · `:940` `G.first = TNeg;  // M-β's RAUW target is the LAST gate in the stream.` · emitter entry `:667`, backstop `:689` `if (RailCond && !R.RailLadderProven)` | for a NEGATED rail arm the target is the chained clone `TNeg`; for an un-negated one the hoisted `T` | both are `cq_theta_i1` CALLs ⇒ `isCondRailLeaf` true ⇒ site 10 needs nothing. |
| 17 | `lowerControlRegions`' precedence graph | `SwapRouteEmit.cpp:2494` `auto reorderable = [](const ControlRegion &R) { return R.Kind == BranchRegion \|\| R.Kind == PhaseKickback; }` · the alias loop `:2536-2557` over `doomedBlocks(B)` · Kahn `:2560-2578`, "Ties break on plan index" | a `SelectRegion` sets **no** block fields (`SelectClassify.cpp:1108-1115`; the comment at `:1106` says so: "The block/depth fields stay null … which makes it inert to the cross-region pre-flight"), so it **never aliases** and acquires **no** edge | ⇒ Kahn emits in **PLAN INDEX** order, and plan index is push order is **block order** (site 18) ⇒ the prep BranchRegion (in `Pred`) is emitted BEFORE the SelectRegion (in its merge block). **Kahn already gives the order**, and stream position is independent of it anyway (each emitter inserts positionally into its own block). The order is what makes site 9 mandatory, not optional. |
| 18 | `detectControlRegions`' block order | `ControlDetect.cpp:725-880`: per `BasicBlock &BB`, the TERMINATOR first (`handleBranchRegion` at `:791`), then `for (Instruction &I : BB) if (auto *Sel = …) classifySelectRegion(…, plan)` at `:870` | `%0` precedes `%4` ⇒ the `br` region is pushed before the merge block's selects are classified | so **at select-classification time `plan.Regions` ALREADY holds the prep region's verdict.** Proof by construction, plus the measured ordering in `../probes/README.md` (the two `collectCondTree` calls in that round: `true` for the peeled a-mux, then `false` for `%8`). `classifySelectRegion` already takes `ControlPlan &plan` (`SelectClassify.cpp:742`) — **no signature change**. |
| 19 | `soleMergePhi` | `ControlDetect.cpp:240` | a 2-incoming merge φ | why the peel is a precondition: the fused diamond's a-mux φ must be peeled (`MergePhiPeel.cpp:189`, `isCondRailLeaf`-keyed P7b) for the prep φ to be `soleMergePhi`. |
| 20 | `Specialization.cpp:296` | `if (!collectCondTree(SI->getCondition(), Tree) \|\| !Tree.RailLeaves.empty())` ⇒ skip | rail-carrying trees are skipped | must also skip a **φ-carrying** tree. One line. |
| 21 | `classifyAngleSelect` / the nest | `ArmClassify.cpp:6763-6781` (`Tree.Leaves.size() + Tree.RailLeaves.size() != 1`, `:6775` `Tree.RailLeaves.front()`, `:6781` `diagnoseUnderControl(Sel, kBareRailCondReason)`), nest `:5807-5811` | rail-keyed | must keep DECLINING a φ until separately scoped (§4). |
| 22 | `declineClassicalMuxes` | `TaintPropagation.cpp:1253`, the select clause at **`:1286-1292`** | `if (taint.Tainted.count(Sel->getCondition())) continue;  // Tainted condition → ControlDetect's, never ours` | **THE MEASURED KILLER FOR SPELLING (b)** — see §2. |
| 23 | `lowerRotations`' RAUW | `RotationLowering.cpp:456` `Theta->replaceAllUsesWith(Handle);` | the handle is ALWAYS `i32`; the cross-type RAUW "is laundered ONLY by ERASURE of the tainted user" (`TaintPropagation.cpp:818-825`) | a surviving `select i1 %theta, …` becomes `select i1 <i32>` ⇒ `report_fatal_error("Broken module found")`. §2. |
| 24 | the pipeline slots | `CQLoweringPass.cpp:451` peel → `:452` `adjudicateTaintDelta` → `:455` detect → `:456` lower → `:473` collapse → `:489` `repropagateControlMerges` → `:510` `reverifyRailCondReads` → `:579` `deleteGlobalPhases` → `:622` `declineClassicalMuxes` → `:645` `lowerRotations` | round 2 of detection is inside `:489` | `TaintPropagation.cpp:1653` `if (taint.UntaintedMergeRails.empty()) return;` — **round 2 is a NO-OP for this program** (only the 6.5 classical-call arm and the 4.5 switch data-mux populate that set). |

**Sites verified to need NO change** (by reading): `condProvenance` (`ArmClassify.cpp:280` — already
walks φ operands), `findNonDiagonalWireGate`/`walkNonDiagonalWireGates` (`WireWalk.cpp:567`/`:380` —
the on-ancestry exemption already handles a source-theta φ wire), `emitKickbackGroup`
(`SwapRouteEmit.cpp:1731` — a φ is just another `Value *` control), `railCondWireDisposition`
(`ArmClassify.cpp:2057` — not on the select path; the select has its own gate 2c), `condCmpMeasured
BeforeReadPoint`, the whole `SelectMergeEmit` body below `:130`.

---

## 2. The two candidate spellings — measured feasibility, and ONE recommendation

### 2.1 (a) LEAF ADMISSION BY CALLING THE ONE OWNER — feasible, and cheaper than boi6 priced it

**The predicate, in the one spelling.** A select-condition `PHINode` `P` is admitted iff there exists
`R ∈ plan.Regions` with

```
R.Kind == ControlRegion::BranchRegion
&& R.Merge == P                                                  // ControlPlan.h:261, the field
&& (R.ClassArm == ArmClass::InPlaceRotation || R.ClassArmFalse == ArmClass::InPlaceRotation)
&& R.RailLadderProven                                            // ControlPlan.h:519
&& !R.Shadow.empty()                                             // the hoisted theta (or ShadowFalse)
```

Nothing is re-derived: `R.Merge`/`R.ClassArm`/`R.Shadow` are `classifyArms`' own committed verdict
(`ArmClassify.cpp:4428-4445`), which is precisely the Rule-14 discipline the drbq Inc-3 (b′) defect
taught (*"ask by CALLING the one owner … never by re-deriving its answer"*). `plan` is already a
parameter of `classifySelectRegion` (`SelectClassify.cpp:742`), and by block order (site 18) the
region is already in it.

**Is the rail available at classification time?** Yes — and this is the question the brief flagged.
The gate M-β will leave is **minted at emission**, but it is a **clone of `R.Shadow.front()`**, which
is a live `CallInst` in round 1 (`ArmClassify.cpp:4429`, `Region.Shadow.assign(1, T)`), chained onto
it, on the **same wire**. So:

* **rung (i)** `taint.Tainted.count(P)` — true by construction, re-asked as defence in depth;
* **rung (ii)** `railMeasuredBeforeReadPoint(…, Sel, taint, DT)` must be asked over the **φ's own
  provenance closure** `condProvenance(P) = {P, T}`, **not** over `T` alone. MEASURED why: in `m05`
  the user's `cq_measure` names the **φ** (`cq_measure_i1(%6)`), and `railWireNamesBackward`
  (`ArmClassify.cpp:2122`) stops at the first non-call, so a closure seeded only from `T` is `{T}`
  and the measure is **INVISIBLE** — an OVER-ACCEPT. This is boi6's **H-4 one construct over**, and
  it is the hazard to probe first (H-2 below);
* **rung (iii)** gate 2c at `SelectClassify.cpp:956` is **already correct** for a φ and already
  answers CLEAN for this shape (§0.3, `m11`/`m12`/`m26`).

**The emitter needs essentially nothing.** By emit time M-β has RAUW'd the φ to a `cq_theta_i1` CALL,
so `CondTreeEmit`'s existing `CopyRailRoot` path fires unchanged and the emitted stream is the r9e5
one **byte for byte** — which is why `m18` ACCEPTS ON THE ORACLE with the target stream and no
compiler change at all. The single required emitter edit is site 9: `SelectMergeEmit.cpp:96`/`:215`
must read the condition off `cast<SelectInst>(R.Merge)->getCondition()` instead of the raw
`R.Condition`, because the prep's `flattenRegion` has by then **erased the φ** (`ControlPlan.h:115`
is a raw `Value *`; `ControlPlan.h:306-331`'s `RoutedBase` scar is the same defect one field over).
Make it a checked fact, not a reading of the call graph: if the re-read condition is **not** a rail
leaf at emit time, **decline loudly** (the `RailLadderProven` precedent at `SwapRouteEmit.cpp:689`).

**What (a) costs.** `SelectClassify.{h,cpp}` (new `RailPhiLeaves` + `AllowRailPhi` + the rung-0/(i)/(ii)
arm + the `RailLadderProven` update + the header note), `SelectMergeEmit.cpp` (the condition re-read +
the backstop), `Specialization.cpp` (one line), `RegionFlatten.cpp` (the predicate, defence in depth),
`ArmClassify.cpp` (H-8's ternary, iff the owner wants the string changed). **≈90–150 production
lines**, most of it rationale; **0 new frozen symbols**; **no `CondTreeEmit` change**; no new emitter.

### 2.2 (b) DEFERRAL — MEASURED UNSOUND as stated, and it needs a third path Rule 1 forbids

Three independent measurements, each fatal on its own:

* **(b1) Nothing re-runs detection for this shape.** `repropagateControlMerges`'s round 2 is gated by
  `TaintPropagation.cpp:1653` `if (taint.UntaintedMergeRails.empty()) return;`, and that set is
  populated only by the 6.5 classical-call arm and the 4.5 switch data-mux — neither is in the owner's
  program. So a deferred select is never reconsidered. (Read, not probed: producing the non-empty case
  requires editing the pass.) This is `SCOPE_boi6.md` §2.2's own note, re-grepped to `:1653`.
* **(b2) Rule 1's "no third path" is VIOLATED, and the failure mode is a CRASH, not a decline.**
  `declineClassicalMuxes` (`TaintPropagation.cpp:1286-1292`) reads, verbatim:
  `if (taint.Tainted.count(Sel->getCondition())) continue;  // Tainted condition → ControlDetect's,
  never ours`. So a deferred-and-never-claimed **tainted-condition** select is declined by **nothing**.
  It then reaches `lowerRotations` (`CQLoweringPass.cpp:645`), whose `Theta->replaceAllUsesWith(Handle)`
  (`RotationLowering.cpp:456`) is `i32`-typed and "laundered ONLY by ERASURE of the tainted user"
  (`TaintPropagation.cpp:818-825`) — leaving `select i1 <i32 handle>, …` and the in-process verifier's
  `report_fatal_error("Broken module found")`: **a crash on valid input**, which that same comment
  block already names as the thing to convert into a clean decline. (b) therefore requires a NEW
  backstop before it is even safe to try.
* **(b3) L1: five stages sit in the window.** Between round 1 (`:456`) and any deferred re-detect, the
  stages that compute over the un-lowered select are `collapseFlattenedLoopRails` (`:473`),
  `repropagateControlMerges` (`:489`), `reverifyRailCondReads` (`:510`), `deleteGlobalPhases` (`:579`)
  and `declineClassicalMuxes` (`:622`). Each owes the L1 question *"do you compute something a later
  stage consumes over a premise round 2 falsifies — and do you GROW the taint set?"*, and `deleteGlobal
  Phases` is the stage that has **already** produced this exact defect once (CLAUDE.md L1, species
  "a STAGE": a branch phase deleted before its region existed, the angle then lowered as quantum fp
  DATA). `RegionFlatten` also erases the prep's merge block while the select lives in it, which is
  L9's block-lifetime scar.

### 2.3 RECOMMENDATION — **(a)**, decisively

**Reason, in one sentence:** (a) is a **pure-analysis widening at one gate** whose emitted stream is
already proven by the ORACLE itself (`m18` ACCEPTS with the target stream, using the Rule-13-cleared
r9e5 emitter unchanged), while (b) is a **pipeline-ordering change** that today ends in a broken
module rather than a loud decline, needs a second detection round that does not run, and puts five
L1-owing stages in its window. (a) also keeps the Rule-1 invariant trivially: the select is
adjudicated in the same round it is seen, so "no third path" is preserved by construction rather than
by a new backstop.

Secondary reasons worth the orchestrator's attention: (a) touches **two** files' logic (the classifier
and one emitter line) against (b)'s four-plus; (a) reuses `R.Merge`/`R.ClassArm`/`R.Shadow` rather
than inventing a deferral record in `TaintPropagation.h` (the shared-hotspot conflict the
orchestrator's §2 table predicts with Track R); and (a)'s round-2 obligation is **already
discharged** by the `WeakTrackingVH` + M-β interaction (site 12), which (b) would have to re-derive
from scratch.

---

## 3. Hazards, in reviewer order

**H-1 — `SelectMergeEmit` reads a RAW `Value *` condition that the PREP region's flatten has already
FREED. Use-after-free on the accept path.** `ControlRegion::Condition` is `llvm::Value *`
(`ControlPlan.h:115`), not a `WeakTrackingVH`; `SelectMergeEmit.cpp:96` and `:215` dereference it.
Site 17/18 prove the prep region emits FIRST, and `emitInPlaceRotationRegion` ends in
`MergePhi->replaceAllUsesWith(Gates.back().first)` (`:1105`) followed by `flattenRegion`, which erases
the merge block and the φ with it. The φ the select region recorded is then freed memory. **Fix:**
re-derive from `cast<SelectInst>(R.Merge)->getCondition()` — correct by construction (M-β rewrote the
select's own operand) and Rule-14-clean (the select owns its condition), plus a LOUD decline if the
re-read value is not a rail leaf. ⚠ Do **not** "fix" it by making `Condition` a `WeakTrackingVH`: that
would silently follow the RAUW and hide the ordering premise instead of checking it.
*Probe first.* Cost: ~10 lines.

**H-2 — rung (ii) asked over the arm theta instead of the φ's closure is an OVER-ACCEPT, and `m05`
is the program.** `railWireNamesBackward` (`ArmClassify.cpp:2122`) `break`s at the first non-call, so
a closure seeded from `R.Shadow.front()` is a ONE-element set and a `cq_measure` naming the **φ**
(measured: `m05`'s `cq_measure_i1(%6)`) is invisible. This is boi6 **H-4** at the select. **Fix:** seed
rung (ii) from `condProvenance(P)` (`ArmClassify.cpp:280`), which is also exactly what rung (iii)
already uses — one closure, two rungs, per L2 (*"when you widen a set, ask what OTHER set was computed
over the same closure"*). Red-green: `m05` must flip from `control flow` to
`condition measured before the control route`.

**H-3 — the grammar's TYPE is the enforcement.** `CondTree::RailLeaves` is
`SmallVector<CallInst *, 2>` (`SelectClassify.h:88`) and `grep -n RailLeaves ir-pass/src
ir-pass/include` reports **25 uses across 6 files** at `01c89b5` (`Specialization.cpp`,
`SelectMergeEmit.cpp`, `ArmClassify.cpp`, `SelectClassify.cpp`, `SwapRouteEmit.cpp`,
`SelectClassify.h` — unchanged from boi6's measurement at `0c7380c`).
Retyping the element to `Instruction *` hands a φ, with no code change and no review, to the depth-2
nest (`ArmClassify.cpp:5807-5811`), the Rz angle select (`:6775`), the kickback (`:5277`, `:5397`),
`Specialization.cpp:296` and `SwapRouteEmit.cpp:1775`/`:2181`. **New field, new flag.** Re-arm the
`SelectClassify.h:78` obligation note for `RailPhiLeaves`.

**H-4 — the round-2 window. Say which records exist and which have NO SUBJECT, and why.**
* `markRailCondRead` — **LIVE and required**: the select's `cqrt_cnot(rail, bf)` is a control read of
  the user's register, recorded at `CondTreeEmit.cpp:248`. Under (a) the record is written with the
  φ *or* with the already-RAUW'd theta depending on emit order; either way `WeakTrackingVH` +
  M-β make `E.first` a `CallInst` before `reverifyRailCondReads` (`CQLoweringPass.cpp:510`) reads it,
  so `ArmClassify.cpp:2504`'s cast succeeds and rungs (ii)/(iii) ARE re-asked (site 12). **Pin this
  with a fixture**, because it is an emergent property of two other files' slots, not a stated
  contract — and write the retirement trigger (`TaintPropagation.h:334-338` is the one to cite).
* `!cq.branchphase` — **NO SUBJECT**: nothing diagonal is emitted on the user's register here; the
  select's stream is CNOT/X/copy_controlled on an ancilla and a fresh `|0⟩` out rail.
* `taint.CmpCondReads` — **NO SUBJECT**: there is no minted compare flag; the rail IS the flag.
* `adjudicateTaintDelta` — **NO SUBJECT** for (a): the widening manufactures no new tainted value
  (unlike `MergePhiPeel`, `CQLoweringPass.cpp:452`); it only admits an existing one as a leaf.

**H-5 — the state vector, because the control is a PREPPED register and the reviewer must check it.**
On the `b0 = 1` branch `b1 = |0⟩`; on `b0 = 0` branch `b1 = Ry(.5)|0⟩` (the `ry_i1` + the cancelling
`ry_i1_controlled`, `../probes/va.trace` lines 4–5). Write the joint state as
`Σ_{x} α_x |x⟩_{b0} ⊗ |β(x)⟩_{b1}` with `β(1) = 0`, `β(0) = Ry(.5)|0⟩`. The CNOT copy
`cqrt_cnot(h1, h7)` on the `|0⟩` ancilla gives `Σ_y γ_y |y⟩_{b1}|y⟩_{bf}` — **basis-faithful on both
branches** (a CNOT copies a basis label, and `b1` is being read as a basis label, not as a phase:
this is the Rule-7 value/permutation arm, never the phase arm). The two X-bracketed
`cqrt_copy_i32_controlled` write `out = (y ? a−3 : a)`; the un-copy `cqrt_cnot(h1, h7)` returns
`bf = y ⊕ y = 0` **on every branch**, which is what makes `cqrt_free(h7)` a proven-`|0⟩` free (Rule 6)
and what 2b reports as `2 verified, 0 violation(s), 0 unproven` on `m18`. `h1` is left allocated and
entangled — the accepted Rule-6 leak, identical to `va`'s.

**H-6 — the 3d8q class gets a new customer population.** The select's CNOT reads the M-β name and the
user's `cq_measure(b1)` reads the same name — one register, fine. But **TWO preps of `b1`**
(`m15`: `b1 = cq_theta(b1, 0.25)` after the select) are two siblings on one rail and MUST decline.
Today `m15` declines `control flow` at the select (the grammar pre-empts); after (a), the fence that
must catch it is rung (iii)/gate 2c (`SelectClassify.cpp:956`) seeing the second theta as an
**off-ancestry** non-diagonal gate on the rail's wire — **verify this by probe, do not assume**, since
`declineStaleRecordOps` sweeps **PURE ops only** (bd `3d8q`) and a `cq_theta`/`cq_measure` reader of a
stale name is asked by nothing. If rung (iii) does not catch `m15`, (a) must not land.

**H-7 — `RegionFlatten`'s rail guard (`RegionFlatten.cpp:96`/`:189`/`:193`) is `isCondRailLeaf`-keyed**
and has no subject for a φ under (a) (the prep's own flatten owns the φ's erasure). Add the predicate
anyway; boi6's H-7 argument transfers verbatim.

**H-8 — WHICH STRING a φ takes at every NON-select consumer: decide ONCE.** MEASURED today: a φ
condition takes `control flow` at a `br` (`m27`, boi6 `p32`), `control flow` at the select (`m01`),
`branch phase on a bare i1 condition` at the kickback (`m08`), the loop-layer string in a loop (`m30`).
**Recommendation: leave every non-select consumer's string UNCHANGED** (do not wire the new predicate
into `ArmClassify.cpp:3160`/`:3325`). Reason: the `kBareRailCondReason` string is the 1b
**discriminator** (`SelectClassify.h:104-111`), and re-pointing it at a φ would make three shipped
fixtures change string without changing disposition while claiming a rail capability that does not
exist for a φ at those consumers. Record the decision in the header note and in each affected
fixture's retirement trigger (L8 — they work).

**H-9 — `cq_invert` is Phase 8 and UNIMPLEMENTED.** `m13` declines at the select before
`__cq_invert_begin/_end` matter; after (a) the select would accept and the `cq_invert` brackets go to
a path that does not exist. Scope a decline probe for it explicitly rather than discovering it at
link time.

**H-10 — the VALUE DIAMOND consumer is plain-C reachable, and it is NOT free.** `m27` proves plain C
reaches `classifyArms` with a merge-φ condition (a memory-writing arm defeats if-conversion). It is a
separate accept (bd `fg9k`'s shape on a φ) with its own arm classes and its own P10
`armWritesMemory` refusal; `m27` itself must keep declining. **Scope the VALUE-diamond consumer as
hand-IR-pinned only this increment** — admit at the same site, pin the accept by hand IR, and keep the
plain-C memory-writing form declining.

---

## 4. The decline partition after the widening

| shape | probe | expected string | fence that must own it |
|---|---|---|---|
| a φ over TWO DISTINCT rails | `m29` | `control flow` | the predicate (no single region's `Merge` is that φ) |
| a φ whose region is a **VALUE** region's merge | hand IR | `control flow` | `R.ClassArm != InPlaceRotation` |
| a φ that is a 6.5/4.5 `%out` rail | hand IR | `control flow` | same; the `%out` is a `cqrt_alloc` handle, never a theta |
| a φ whose region was **not claimed at all** | `m20` (T2, the `p5` shape — its region declines) | `control flow` | the predicate (no matching `plan.Regions` entry) |
| a φ in a LOOP | `m30` | `cq loop lowering: loop-carried tainted value crosses iterations` | the loop layer, BEFORE detection (`CQLoweringPass.cpp:~364`) — loop layer first, bd `boi6.a`/`wx8g` |
| a COMPOUND tree with a φ leaf | `m31` | `control flow` | rung 0 asked per φ leaf; over-decline is safe |
| the φ read as a condition BEFORE its region is claimed | — | cannot occur | **PROVEN by block order** (site 18): the `br` is in `Pred`, the select in the merge block, and the driver handles each block's terminator before that block's selects. Pin it with an assertion-free LOUD decline anyway (the predicate simply finds no region). |
| `cq_measure` of the rail before the select | `m05` | `condition measured before the control route` | rung (ii) over `condProvenance(P)` — **H-2** |
| a SIBLING/second theta on the rail | `m15` | `condition predates a non-diagonal gate` | rung (iii)/gate 2c — **H-6, verify** |
| the PHASE consumer (`cq_phi`) on a φ | `m08` | `branch phase on a bare i1 condition` (unchanged) | `classifyPhaseKickback` step 5 — out of Track M's scope, but file it as a **leaf-grammar** over-decline, NOT as `drbq.7`'s wire fence (§0.3) |
| the VALUE DIAMOND from plain C | `m27` | `control flow` | H-10 |
| the Ry-stem angle select / depth-2 nest on a φ | — | `bare i1 register condition` / unchanged | sites 21 — must keep declining |
| a `trunc`/`zext`/argument `i1` condition | shipped fixtures | `branch phase on a bare i1 condition` (bd `r903`) | unchanged |

---

## 5. Fixtures, slices, witnesses, cost

**ACCEPT fixtures (~8), every one with whole-file negatives in their OWN prefixes** (the Rule-12(a)
windowing lesson): `NOX-NOT: cqrt_x(i32 %h` on the **user register** (the non-negotiable — the two
`cqrt_x` are on the ancilla), `NOROUTE-NOT: cqrt_cswap`, `NOFREE-NOT: cqrt_free(i32 %h1`, and
`FCNT`/`XCNT`/`CNOTCNT`/`ACNT` exact counts **derived from the pass output**:
`control_swap_accept_select_mergephi_rail{,_negated,_prep_true_edge,_int_amux}.ll`,
`control_swap_accept_select_mergephi_rail_two_selects.ll`, plus the **T1 pins**
`control_swap_accept_select_rail_after_prep{,_negated}.ll` (= `m18`/`m19` — RED on nothing today,
green on the ORACLE, and **that is the point**: they are the discriminator that the emitter is
unchanged). ⚠ `va` as a fixture-level byte-identity pin is mandatory.

**DECLINE fixtures (~12)**, one per §4 row, each RED on the ORACLE for the right reason:
`control_swap_reject_select_mergephi_{two_rails,value_region,out_rail,unclaimed,tree_leaf,measure_before,sibling_theta,inloop,invert}.ll`.
⚠ Rule-12(b): a `DS_Error` decline writes 0 bytes to stdout, so the property is pinned by the `not`
on the RUN line — do not add vacuous IR-text `CHECK-NOT`s and call them coverage.

**e2e (STRICT stage 2b), 3 slices + 1 twin gate:**
* `slice_control_cascade_two_bools.c` = the owner's file (`m01`), golden = **the 29-line T1 stream of
  §0.4** — `va.trace` lines 1–16 + `m18.trace` lines 17–26 renumbered + 3 measures;
* `slice_control_cascade_two_bools_uncond.c` = `m17` (28 lines) — the plain-C twin whose condition is
  already a theta CALL, i.e. the *existing* compiler's proof of the select half;
* `slice_control_cascade_two_bools_int.c` = `m11` (28 lines) — the `int` spelling the owner refuses,
  pinned so the widening cannot change it;
* **twin gate**: `m17`'s select-merge block must be **byte-identical** to the owner slice's
  select-merge block (the l4x4/3qlq `*-twin-identical` pattern: the widening adds an ACCEPT, it does
  not add a STREAM).

**Injection matrix** over every new accept (Rule 12): an injected `cqrt_x` on the **user register**;
an extra `cqrt_free` (on `h1`); an extra uncontrolled `cqrt_ry` on the rail; a `cqrt_cswap`; a rail
handle in a classical immediate slot; **the CNOT copy pair unbalanced** (one `cqrt_cnot` removed);
**the two `copy_i32_controlled` swapped** (polarity). Each must redden ≥1 prefix in EVERY accept.
Expect the first run to read MISSED — budget the second pass (the r9e5/eqpx lesson, and bd `f8eu`'s
57-missed-over-17-fixtures precedent).

**Cost**

| | |
|---|---|
| production lines | **~90–150** across 5 files: `SelectClassify.{h,cpp}` ~70 (field, flag, rung-0/(i)/(ii) arm, `RailLadderProven`, the header note), `SelectMergeEmit.cpp` ~15 (H-1's condition re-read + the loud backstop), `Specialization.cpp` 1, `RegionFlatten.cpp` ~6, `ArmClassify.cpp` 0 (H-8 says leave the ternaries alone) |
| new frozen symbols | **0** — the emitted stream is the existing r9e5 one (`m18`, measured) |
| `CondTreeEmit.cpp` | **0 lines** — by emit time the condition is a `cq_theta_i1` CALL |
| fixtures | ~20 (`ir-pass-lit` 1893 → ~1913; re-measure with `ls ir-pass/test/*.ll \| wc -l`) |
| goldens / ctest | +3 goldens (355 → 358), +4 ctest entries (403 → 407: 3 slices + 1 twin gate) |
| instruments | none new (`loop_twin_matrix` has no subject — this is FLAT; Track L owns the loop axis) |
| adversarial rounds | **2 minimum, budget 3.** The measured hit rate in this family is 8-over-6 on one function (3qlq C-1) and 4-consecutive-losses (drbq F2). |
| probe FIRST | **H-1** (use-after-free), then **H-2** (`m05`), then **H-6** (`m15`) |

The only item that can change the cost by more than a factor is **H-6**: if rung (iii) does not refuse
the two-prep shape, the increment needs a 3d8q-class fence of its own and that is a different bead.

---

## 6. Recommendation to the orchestrator

1. **Build spelling (a).** §2.3. It is a one-gate analysis widening whose stream the ORACLE already
   prints (`m18`, 29 lines). (b) ends in `report_fatal_error("Broken module found")` today because
   `declineClassicalMuxes` explicitly disowns a tainted-condition select (`TaintPropagation.cpp:1286`).
2. **Correct the record on boi6 §0.3 before the implementer reads it.** The wire fence is NOT the
   second blocker for the owner's file: `m11`/`m12`/`m26` accept on the ORACLE with a COMPARE over the
   same φ. `p5`/`m20` (a CHAINED arm theta) remains `drbq.7`'s; the owner's prep φ (a SOURCE theta
   plus a constant seed) is clean. The PHASE consumer `m08` is therefore **also** a leaf-grammar
   over-decline, not a physics or wire wall — file it that way.
3. **File the ±1 asymmetry as the headline over-decline** (owner ruling 2026-09-11: an over-decline of
   a valid circuit is a defect). `if (b1) a -= 1;` compiles and `if (b1) a -= 3;` does not, on one
   binary, because InstCombine keeps a `select` for every delta but ±1. That one sentence is the
   clearest statement of the defect the owner's file hit, and `m09` is its witness.
4. **Pin `m17`/`m18`/`m19` FIRST**, before any pass edit. They are accepts on the ORACLE that no
   fixture and no slice covers, and they are the discriminator that (a) adds an ACCEPT without adding
   a STREAM (H-4's emergent round-2 property is pinned by them too).
5. **Do not widen `isCondRailLeaf` and do not retype `RailLeaves`** (H-3: 25 uses across 6 files at `01c89b5`). New field, new flag, and re-arm the `SelectClassify.h:78` obligation.
6. **Answer H-8 once** (which string a φ takes at the non-select consumers) and write it into the
   header plus each affected fixture's retirement trigger. Recommendation: change nothing.
