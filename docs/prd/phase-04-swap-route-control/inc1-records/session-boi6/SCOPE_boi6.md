# SCOPE — bd `test_C_libtooling-boi6`, sub-increment 1b-D: the loop-CARRIED `_Bool` (header-phi rail leaf) and the region-merge-phi rail

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11, measured on **`main` `0c7380c`** with the tree's
own `build/ir-pass/cq-opt` (`git status --porcelain` clean at the start; the build is the one that
landed `d33a34a`). Every number below is MEASURED, with the command in `probes/README.md`.

**READ-ONLY.** Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/` or `tools/` was touched.
Scratch lives in `…/scratchpad/boi6/`; all 30 probes plus four traces and the runner are
transcribed into `probes/`.

Companions: `session-r9e5/SCOPE_B2.md` (the style model and the sibling scoping), PRD
`retire-swap-route-PRD.md` §13 (Inc 1b, the rail ladder) and §14 (1b-B.1, the round-2
re-verification). Line numbers are as of `0c7380c`.

---

## 0. HEADLINE — measure first, and the measurement splits the bead in two

### 0.1 The verdict table (`main` `0c7380c`)

Full table in `probes/README.md`; the rows that decide the scope:

| probe | shape | `-O1` IR | verdict on `main` |
|---|---|---|---|
| **`p1`** | **the bd's own shape** — `for (i<3) { if (b) cq_phi(.7); b = cq_theta(b,.2); }` | header `phi i1 [%1,%0],[%10,%9]`; condition = the **φ** | DECLINE `branch phase on a bare i1 condition` @ `br i1 %7` (`ArmClassify.cpp:4086`) |
| **`p2`** | the SAME loop with the theta **before** the region | condition = the in-body `cq_theta_i1` | **ACCEPT — rolled** |
| `p2u` | `p2` hand-unrolled K=3 | flat | ACCEPT; trace **byte-identical** to `p2` (9 lines) |
| `p2k1000` | `p2` at K=1000 | — | ACCEPT; **50 lowered IR lines at K=3 and at K=1000** |
| `p9` | `p2` with `if (!b)` | in-body theta cond | **ACCEPT** (the negated arm is the diagonal `rz(−θ)`) |
| `p16` | `p1` hand-unrolled K=3 | flat | ACCEPT — **`p16.trace` is the 9-line stream `p1` rolled must print** |
| `p4` | the one-qubit Grover LOOP (`p4u` = `slice_control_phase_bool_grover.c` rolled) | 2 regions/trip: #1 reads the φ, #2 reads the in-body theta | DECLINE @ **region 1 only** |
| `p3`,`p8`,`p18`,`p19`,`p24`,`p25`,`p26`,`p28`,`p33` | every other carried-bool spelling | header `phi i1` | DECLINE, **one site, one string, one anchor** |
| **`p5`** | `int q…; bool b…; if (q>3) b = cq_theta(b,.9); if (b) cq_phi(.3);` | `%7 = phi i1 [%5,%4],[%2,%0]` — **both incomings one wire** (`%5`'s arg-0 IS `%2`) | DECLINE `branch phase on a bare i1 condition` |
| `p21` | the preceding controlled-Ry region ALONE | merge φ | **ACCEPT** — `cqrt_ry_i1_controlled(%h_cmp, %h1, .9)`, the φ **RAUW'd away** by M-β |
| **`p22`** | **`p5`'s plain-`int` COMPARE twin** | `phi i32` | DECLINE **`condition predates a non-diagonal gate`** @ the `icmp` |
| `p6` | 4.4 DATA select on a carried bool **in a loop** | `select` in the body | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` — the **loop layer**, `lowerLoops` at `CQLoweringPass.cpp:364`, *before* detection at `:376` |
| `p20` | 4.4 DATA select on a **merge-φ** bool (flat) | `select i1 %7, i32 2, i32 5` | DECLINE `control flow` @ **the select** (not the rail string) |
| `p32` | carried bool + a second region that is an in-place-Ry arm | header φ | DECLINE `control flow` @ **the φ** (`ArmClassify.cpp:2394`) |
| `p23`,`p34` | INVARIANT bool in a loop (the shipped 1b accept) | **no rail φ** | ACCEPT, rolled |

### 0.2 The bead is TWO capabilities, and only one of them is about `_Bool`

* **D-A, the HEADER φ** (`p1`,`p3`,`p4`,`p8`,`p18`,`p19`,`p24`,`p25`,`p26`,`p28`,`p33`). Blocked by
  exactly ONE site — `classifyPhaseKickback`'s step-5 `collectCondTree` refusal at
  `ArmClassify.cpp:4086`. Every probe declines there, on the `br`, with the same string. The
  lowering it wants already exists: the collapse (`collapseRailPhisIn` step (4),
  `LoopLowering.cpp:2747`) RAUWs the header φ to its root mint, which `lowerRotations` then
  RAUWs to the one handle — so `cqrt_rz_i1(%φ, θ)` emitted at detection time lands on `%h`.
* **D-B, the region-MERGE φ** (`p5`, and its select consumer `p20`). Blocked TWICE, and the second
  block is **arm-class-independent and not about `_Bool` at all** — see §0.3.

### 0.3 The merge-φ half's second blocker is the WIRE fence, and its `int` twin declines on `main`

`p22` is `p5` with `int` in place of `bool` and nothing else. On `main` it declines
**`condition predates a non-diagonal gate`**, anchored (`CQ_CTRL_DBG=1`) on `%8 = icmp sgt i32 %7, 1`
— the second region's compare reading the merge φ of a region that put a **controlled `Ry`** on that
wire. `condProvenance` (`ArmClassify.cpp:231-261`) walks a φ's operands and stops at each theta, so
for `p5` it returns `{%7, %5, %2}`; `%5` is the arm's own non-diagonal gate and is not provably
post-branch, so `wireGainsNonDiagonalGate` answers `DeclineNow` **for the bool spelling too**.

**Admitting the φ as a rail leaf would therefore buy `p5` nothing**: it would move the decline from
`ArmClassify.cpp:4086` to `ArmClassify.cpp:4342` and change the string. The capability `p5` actually
wants is "read a register a preceding CONTROLLED rotation moved", which has an `int` red-green twin
already (`p22`/`p21`) and belongs to the drbq control-in-place family, not to 1b-D.

### 0.4 TWO SHIPPED ACCEPTS IN THIS FAMILY ARE PINNED BY NOTHING

`p2` and `p9` — a carried `_Bool` whose region condition is the **in-body chained theta** — lower
**rolled** on `main`: trace byte-identical to the hand-unrolled twin (9 = 9), IR size independent of
K (50 lines at K=3 and K=1000), stage 2b `1 rail mint … 0 violation(s)`. MEASURED:

```
grep -l 'phi i1' ir-pass/test/control_phase_kickback_rail_*.ll      → (empty)
ls tests/e2e/slice_control_phase_bool_*                              → no carried-bool slice
```

This is the ONE shape where the 1b kickback already fires on a rail whose wire crosses a back edge,
and it is the discriminator any boi6 widening needs (it must stay byte-unchanged). Pinning it is
red-green work that belongs at the **front** of the increment, not at the end.

---

## 1. Every site that assumes the rail is a `cq_theta_i1` CALL

The ladder to mirror is `classifyPhaseKickback` **step 5b** (`ArmClassify.cpp:4173-4207`) plus the
wire dispatch at `:4287-4300`. Three rungs: (i) tainted, (ii) not measured before the read point,
(iii) the wire question.

| site | line | today | what a φ needs |
|---|---|---|---|
| `isCondRailLeaf` | `SelectClassify.cpp:543-549` | `dyn_cast<CallInst>` + `getName() == "cq_theta_i1"` | **DO NOT WIDEN** — H-3. A new predicate + a new grammar field. |
| `CondTree::RailLeaves` | `SelectClassify.h:88` | `SmallVector<CallInst *, 2>` | the element TYPE is the enforcement (H-3); add `RailPhiLeaves`, do not retype. |
| `collectCondTree` | `SelectClassify.cpp:551-575`, decl `SelectClassify.h:150-151` | rail test before the `CmpInst` test | a φ leaf behind a new `AllowRailPhi` flag (the `AllowLogicalSelect` precedent, `SelectClassify.h:117-131`). |
| step 5 refusal | `ArmClassify.cpp:4078-4088` | `IsCondTree ? "control flow" : "branch phase on a bare i1 condition"` (an inline literal, **not** a named constant — unlike `kBareRailCondReason`, `SelectClassify.h:111`) | THE ONE SITE every D-A probe dies at. |
| step 5b ladder | `ArmClassify.cpp:4173-4207` | `for (CallInst *Rail : Tree.RailLeaves)` | a φ arm: rung 0 (claimable) + (i)(ii)(iii). |
| `condProvenance` seed | `ArmClassify.cpp:4283-4290` | union over `Leaves` + `RailLeaves` | **UNCHANGED and already right for a φ** — measured by reading `:245-261`: it walks the φ's operands and stops at each theta, giving `{φ, latch θ, root mint}`, which is exactly the wire. |
| `railCondWireDisposition` | `ArmClassify.cpp:1803-1816` | `if (!isCondRailLeaf(R.Condition)) return DeclineNow;` | must admit a φ — **and its STRUCTURAL ground (`:1789-1802`) must be re-derived**, H-5. |
| `railWireNamesBackward` | `ArmClassify.cpp:1868-1915`, decl `ArmAnalysis.h:176` | `const CallInst *Rail`; `break`s at the first non-call | **STRUCTURALLY BLIND to a φ** — H-4. |
| `railMeasuredBeforeReadPoint` | `ArmClassify.cpp:1915-1955`, decl `ArmAnalysis.h:163` | `const CallInst *Rail` | widen to `const Instruction *`; the closure is H-4's. |
| step 7 (loops) | `ArmClassify.cpp:4340-4358` | `flatRegionRollableInLoop` + a PREMISE SENTENCE | the premise is **FALSE** for this shape — H-2. |
| `markRailCondRead` | `ArmClassify.cpp:1958-1966` | `Value *Rail` — already type-general | records fine; the READER does not — H-1. |
| `reverifyRailCondReads` | `ArmClassify.cpp:2060-2110` | `dyn_cast_or_null<CallInst>(E.first)` at **`:2075`** | **THE HEADLINE HAZARD** — H-1. |
| `CondTreeEmit::emitCondNetwork` | `CondTreeEmit.cpp:195-199`, `:219`, `:229-245` | `FlagOf[V] = V` for a rail leaf; `RootIsRail`; the `CopyRailRoot` cnot | a φ maps to itself identically; `RootIsRail` must NOT become true for the 4.4 select (H-3). |
| `emitKickbackGroup` | `SwapRouteEmit.cpp:1489-1492` (the `markRailCondRead` site) | `Ctl`, `CtlIsRail` → `rz(rail, −θ)` for a negated arm | UNCHANGED — a φ is just another `Value *` control. |
| `RegionFlatten` | `RegionFlatten.cpp:96`, `:189`, `:193` | "never erase a user's rail", `isCondRailLeaf`-keyed | add the new predicate — H-7 (moot for a header φ, live for a merge φ and for any later widening). |
| `classifyArms` | `ArmClassify.cpp:2391-2397` | `isCondRailLeaf(...) ? kBareRailCondReason : "control flow"` | a φ takes `control flow` today (MEASURED, `p32`) — H-8, decide once. |
| `classifyAngleSelect` | `ArmClassify.cpp:5644-5660` | `Tree.RailLeaves.front()` cast to `Instruction *` | already `Instruction *`-shaped; must keep DECLINING a φ until it is scoped. |
| `classifyPhaseKickbackNest` | `ArmClassify.cpp:4617`, `:4660`, `:4698-4704`; emitter `SwapRouteEmit.cpp:1933-1941` | rail leaves per level; a NEGATED rail root declines | the nest keeps its blanket in-loop decline (`:4708-4716`) — a φ must never reach it. |
| `Specialization.cpp:288` | — | `|| !Tree.RailLeaves.empty()` ⇒ skip | must also skip a φ tree. |
| `SelectMergeEmit.cpp:130` | — | `RailLadderProven` backstop | the r9e5 round-1 tripwire — a φ tree must be refused there, not silently admitted. |

**Sites needing NO change** (verified by reading): `walkPhaseSpine`, `armBlockIsPureSpine`,
`phaseAngles`, `emitKickbackGroup`'s bracket logic, `markBranchPhaseGate`, `stripCondNetwork`
(nothing is minted for a rail), and the whole `flatRegionRollableInLoop` (A)–(D) walk
(`ControlDetect.cpp:190-237`), which is about the CFG and never looks at the condition.

---

## 2. The design

### 2.1 D-A — the header-φ rail leaf (the increment)

**The claim proof, by CALLING the round-2 collapse's own body — never a second spelling.** The
drbq Inc-3 (b′) precedent is explicit (`LoopPlan.h:353-400`, `ArmClassify.cpp:3207-3270`):
`railPhiRootMint(P, L, GateCalls, taint, DT)` IS `collapseRailPhisIn` step (1)'s
external-incoming body, and clause (b′) asks it at detection with a `GateCalls` built by the
one recipe (θ ∪ φ). D-A asks the identical question about the CONDITION φ.

⚠ **But `railPhiRootMint` proves only HALF of "the collapse will claim this φ", and `LoopPlan.h`
says so in as many words** (`:363-380`): step (1) additionally requires the **closed self-cycle**
`peelInPlaceBase(LatV, …) == &P` on the LATCH incoming, whose failure is a `continue` or the loud
`kMsgCrossIter`. For drbq Inc 3 a round-2 refusal was acceptable (a loud, accurately-labelled
post-emission decline). **For D-A it is not acceptable in the same way**: the region's own gate
`cqrt_rz_i1(%φ, θ)` has already been emitted ONTO the φ, so a refused φ leaves a gate naming a
value the collapse will not collapse — still a loud decline (`declineClassicalMuxes`), still no
wrong unitary, but with a string that calls a quantum register a classical mux. **Lift the latch
half too**, as a second named body in `LoopLowering.cpp` beside `railPhiRootMint`
(`railPhiSelfCycleClosed`), called from step (1) and from the classifier — one question, one
spelling, two callers, exactly as Rule 14 required the first half.

**The grammar.** A new `CondTree::RailPhiLeaves` field and a new `collectCondTree` flag
`AllowRailPhi`, defaulting **false**. The flag is the `AllowLogicalSelect` precedent verbatim: one
grammar, per-consumer verdicts, and the header note at `SelectClassify.h:78-87` ("EVERY CONSUMER
THAT READS `Leaves` MUST DECIDE ON `RailLeaves` EXPLICITLY") re-armed for the new field. The
syntactic test in the grammar is deliberately weak — *a tainted 2-incoming `PHINode` of type `i1`*
— because the grammar has no `Loop`, no `DominatorTree` and no `GateCalls`; **the proof belongs to
the classifier**, which has all three.

**The ladder** (step 5b gains a φ arm):

* **rung 0 — CLAIMABLE.** `Region.InLoop` must be set (i.e. `flatRegionRollableInLoop` has already
  proved A–D), the φ must be in `LI->getLoopFor(Region.Pred)`'s **header**, and both
  `railPhiRootMint` and `railPhiSelfCycleClosed` must succeed. Anything else declines
  `control flow inside a loop body` (the string every in-loop refusal in this classifier already
  uses) — which `p18` (nested), a multi-latch loop and an irreducible cycle all take for free.
* **rung (i) tainted** — unchanged, `Taint.Tainted.count(φ)`.
* **rung (ii) measured-before** — over the RAIL's names, not the φ's (H-4). The rail's names are
  exactly `collapseRailPhisIn`'s `Chain` (`LoopLowering.cpp:2575-2595`); the honest spelling calls
  the loop layer's own enumeration rather than growing a second closure beside
  `railWireNamesBackward` (the 8h7d.5 F-1/F-3 lesson: *when you widen a set, ask what OTHER set was
  computed over the same closure*). `p24` and `p19` are the red-green programs.
* **rung (iii) the wire** — `railCondWireDisposition` over `Prov = {φ, latch θ, root mint}`. This
  already works **at classification time**, and the reason is worth stating because it stops working
  later: `gateIsHarmless`' **superseding-phi** machinery (`WireWalk.cpp:317-325, 340-363`) was
  written for exactly this — a loop-header φ that lists the seed among its incomings, dominates the
  emit point and `phiTracksWire` becomes a BARRIER, so the body theta reached round the back edge is
  proven harmless. Do not add a second per-activation spelling; this one is it.

**Emission.** `FlagOf[φ] = φ` in `emitCondNetwork` (one line beside `:196`), `markRailCondRead(taint,
φ, gate)`, and `emitKickbackGroup` unchanged: `cqrt_rz_i1(%φ, +θ)` for the true arm, `cqrt_rz_i1(%φ,
−θ)` for a negated one (`p8`, and MEASURED live in `p4u`/`p16`'s flat streams). **No `cqrt_x` on a
user register, no mint, no strip, no `cqrt_free`, no new runtime symbol** — D3 holds.

**Then the collapse does the rest.** `collapseFlattenedLoopRails` (`CQLoweringPass.cpp:394`) RAUWs
`%φ → root mint` (step (4), `LoopLowering.cpp:2747`) and `lowerRotations` RAUWs that to `%h`.
Target stream for `p1` = `probes/p16.trace`, 9 lines; for `p4` = `probes/p4u.trace`, 11 lines.

### 2.2 D-B — the region-merge φ (NOT this increment)

`p5`'s φ has both incomings on ONE wire and would be a legitimate rail leaf; `p21` shows the
preceding region already lowers and already dissolves that φ (M-β RAUWs the merge to the last
hoisted gate). But §0.3 measured the second blocker: the wire question refuses a register a
preceding **controlled** rotation moved, and `p22` — the plain-`int` compare twin — declines
identically on `main`. So D-B is a **drbq control-in-place** capability wearing a `_Bool` costume.

There is also a **round-ordering option** worth recording rather than building: if the round-1
decline did not fire, M-β would have RAUW'd the φ to `%5` (a `cq_theta_i1` **call**, i.e. a genuine
rail leaf) before any second detection round. It does not help today — `repropagateControlMerges`'s
round-2 `detectAndLowerOnwardControl` is a **no-op unless `taint.UntaintedMergeRails` is non-empty**
(`TaintPropagation.cpp:1494`), which only the 6.5 classical-call arm and the 4.5 switch data-mux
populate — but it is the shape of a cheaper answer if D-B is ever built, and it is the *inverse* of
CLAUDE.md's standing lesson: here a stage's **decline** has a round-2-false premise.

---

## 3. Hazards

**H-1 — `reverifyRailCondReads` both SKIPS a φ record and, after the collapse, asks the WRONG
QUESTION. This is the headline, and it can kill the increment on its own.** Two faces:

* (a) `ArmClassify.cpp:2075` is `auto *Rail = dyn_cast_or_null<CallInst>(E.first);` followed by
  `if (!Rail …) continue;`. A `PHINode` record is silently skipped — so the F-B1R2-1 round-2 taint
  window (PRD §14.7/§14.8) reopens for exactly the shape this increment adds.
* (b) `TaintPropagation.h:312-315` makes both halves `WeakTrackingVH`, which **follows a RAUW** —
  and the header's own retirement trigger (`:307-311`) names the mirror image of this situation. So
  the collapse at `CQLoweringPass.cpp:394` silently rewrites the record from the φ to the **root
  mint**, and the stage at `:431` then asks rung (iii) with a seed OUTSIDE the loop and a read
  INSIDE it. Traced by hand through `gateIsHarmless` (`WireWalk.cpp:329-363`): leg 1 fails (the body
  theta reaches the read round the back edge), and leg 2's barrier set is `{root mint def}`, which
  does not re-execute, so `reachesWithoutBarrier` is true ⇒ **`condition predates a non-diagonal
  gate`**. The accept this increment exists to create would be refused by the stage added last
  session. **There is no slot that is both after the round-2 fixpoint and before the collapse** —
  `394 < 410 < 431` (the second entry point `runOnFunction` at `:659` is a DEAD SHIM with zero
  callers and never calls the collapse at all, per its own `AXIS-F HAZARD` note at `:675`).
  *Asymmetry to carry: the question IS answerable before the collapse (§2.1 rung (iii)) and is not
  answerable after it.* Options — (1) record the loop and re-ask with a loop-aware barrier (a second
  spelling; costs the Rule-14 lesson); (2) discharge in-loop φ records at the collapse, which already
  owns `staleRailRecordRead`, and argue the round-2 window cannot reach an in-loop rail (needs an
  argument, and `p28`/6.5 interactions); (3) record `(root mint, read, loop header)` and teach the
  stage that the back edge is the barrier. **Owner question — answer it before writing code.**

**H-2 — an in-source premise becomes FALSE, verbatim.** `ArmClassify.cpp:4347-4350`: *"A kickback
needs NOTHING from the round-2 rail collapse: it emits no gate on the loop-carried register, so
`collapseFlattenedLoopRails` finds nothing to collapse for it and `staleRailRecordRead` has no rail
record to invalidate."* With a φ condition the kickback emits `cqrt_rz_i1` **on the loop-carried
register**, the collapse is **what makes that gate name the right handle**, and the gate is a user
of a chain member that `staleRailRecordRead` (`LoopLowering.cpp:1042`) will judge. Every fence
downstream of that sentence must be RE-DERIVED, not inherited — it is the single clearest
"premise that a widening falsifies" in the file.

**H-3 — the grammar's TYPE is the enforcement; widening it is a silent five-consumer widening.**
`CondTree::RailLeaves` is `SmallVector<CallInst *, 2>` (`SelectClassify.h:88`) and `grep -n
RailLeaves ir-pass/src ir-pass/include` reports **25 uses across 6 files**. Retyping the element to
`Instruction *` hands a φ, with no code change and no review, to: the 4.4 DATA select
(`SelectClassify.cpp:843`, `:936`, `:1095` — which would then emit `cqrt_cnot(%φ, bf)` under
`CopyRailRoot`), the depth-2 nest (`ArmClassify.cpp:4617/4660/4698`), the Rz angle select
(`:5655`), and `Specialization.cpp:288`. Use a **new field** so the `SelectClassify.h:78`
obligation fires again.

**H-4 — rung (ii) is STRUCTURALLY BLIND to a φ, and that is an OVER-ACCEPT.**
`railWireNamesBackward` (`ArmClassify.cpp:1868-1915`) is `const CallInst *Rail` and its loop does
`const auto *CI = dyn_cast<CallInst>(V); if (!CI) break;` — a φ yields a ONE-element closure, so a
`cq_measure` naming the **root** (`p24`) or the latch theta's result is invisible and rung (ii)
accepts. This is the r9e5 round-1 finding F-B1R1-1 one construct over: *two rungs of one ladder over
two closures.* The fix must reuse the collapse's `Chain`, not add a third closure.

**H-5 — rung (iii)'s STRUCTURAL ground must be re-derived for a φ.**
`railCondWireDisposition`'s header (`ArmClassify.cpp:1789-1802`) drops the compare path's positional
prong on a MEASURED ground: *a condition rail is always read later by its own branch in `R.Pred`, so
M-C's G6 refuses an in-place `add`/`xor` conversion on it.* For a header φ the later read is in the
header and an IN-BODY `add`/`xor` is refused outright by M-C's G5 — but a **PREHEADER** one is
exactly the F-C1-1 shape that has already produced two confirmed silent miscompiles in this epic
(CLAUDE.md, findings F-C1-1 / F-C1B-1). Write the argument down or restore the prong.

**H-6 — the C-1 in-loop entangled-rail family gets a NEW subject, and the instrument cannot see it.**
Eight instances over six adversarial rounds, two introduced by a fix, the eighth found by a round
reviewing a different increment. Until now every accepted in-loop kickback had an **INVARIANT**
condition register — `control_phase_kickback_rail_inloop_invariant.ll`'s own header says the leak
family *"has NO SUBJECT here"*. D-A makes the condition register **CARRIED**, so the region's `Pred`
IS the loop header and `collapseFlattenedLoopRails`' `markIfRailLocal` / `invariantRegisterRoots` /
`CarriedRoots` split (`LoopLowering.cpp:3221-3465, 3664, 3677`) is asked about the very rail the
region reads. And **`tools/loop_twin_matrix.py` has no `_Bool` axis at all** — `grep -c 'bool'`
returns 2, both inside `phi_surface_of_header` — so all 288 cells (259 expected + 29 quarantined,
MEASURED) are blind to this shape.

**H-7 — `RegionFlatten`'s "never erase a user's rail" guard is `isCondRailLeaf`-keyed** at
`RegionFlatten.cpp:96`, `:189`, `:193`. Moot for a header φ (the latch theta always uses it) and
live for a merge φ; add the new predicate anyway, or a later widening re-opens a block-lifetime hole
the file already carries a scar for.

**H-8 — a φ changes which STRING a non-phase consumer emits, and a string is a coverage claim.**
MEASURED: `p32` takes `control flow` at `ArmClassify.cpp:2394` (the ternary is `isCondRailLeaf`-keyed),
`p20` takes `control flow` at the select, `p6` takes the loop-layer message. If the new predicate is
wired into those ternaries, three pre-existing fixtures change string without changing disposition
(`control_swap_reject_select_rail_phi_cond.ll` is the named one). Decide ONCE and record it; the
1b discriminator argument (`SelectClassify.h:104-111`) depends on the answer.

**H-9 — D-B is blocked by a fence that is not in this layer** (§0.3, `p22`). Splitting is the
recommendation.

**H-10 — `p2`/`p9` are shipped accepts pinned by nothing** (§0.4). They are the discriminator that
D-A's widening changes no existing stream; pin them FIRST.

---

## 4. The decline partition (what must still decline, and with which string)

| shape | probe | expected string after D-A |
|---|---|---|
| nested loop around the carried bool | `p18` | `control flow inside a loop body` |
| irreducible / multi-latch loop | hand IR | `control flow inside a loop body` |
| the φ's latch incoming is a FRESH rail (no closed self-cycle) | hand IR | `control flow inside a loop body` (rung 0), **never** a post-emission `kMsgCrossIter` |
| the φ's external incoming peels to a DERIVED base (`mul`) | hand IR | `control flow inside a loop body` (rung 0 — `railPhiRootMint` is exactly PRD §13.2 row DB) |
| `cq_measure` of the rail in the body, before or after the region | `p19`, `p7` | `condition measured before the control route` |
| `cq_measure` of the SEED before the loop | `p24` | same (H-4 is what makes this true) |
| SIBLING theta on the carried rail in the body | `p33` | `condition predates a non-diagonal gate` |
| ITERATION-LOCAL bool (no rail φ) | `p17` | unchanged (`condition measured before the control route`) |
| the φ as a leaf of a compound `&&` tree | `p10` | `control flow` (rung 0 is asked per rail-φ leaf; over-decline is safe) |
| a φ over TWO distinct rails | `p12` | `control flow` |
| a φ at any NON-phase consumer (4.4 select, value arm, in-place Ry, state prep, angle-select Ry stem, nest) | `p20`, `p32`, `p6` | H-8's answer — one string, applied once |
| the NEGATED rail root of a depth-2 NEST level | — | `branch phase on a bare i1 condition` (the 1b residual, unchanged) |
| a `trunc`/`zext`/template/argument `i1` condition | shipped fixtures | `branch phase on a bare i1 condition` (bd `r903`, unchanged) |

---

## 5. Families

**Probe → fixture.** Every accept fixture carries whole-file negatives in their OWN prefixes —
`NOX-NOT: cqrt_x(i32 %h` (**no `cqrt_x` on a user register**, the non-negotiable), `NOROUTE-NOT:
cqrt_cswap`, `FCNT`/`XCNT`/`ACNT` exact counts derived from the pass output and never guessed — and
the injection matrix (an injected `cqrt_x` on the register, an extra `cqrt_free`, an extra
uncontrolled `cqrt_ry` on the condition register, a `cqrt_cswap`, a rail handle in a classical
immediate slot, **and a gate moved OUT of the loop body**) must redden ≥1 prefix in EVERY accept.
The r9e5/eqpx lesson is that the first run of that matrix reads MISSED; budget the second pass.

**ACCEPT fixtures (~20):** `control_phase_kickback_rail_loop_phi{,_negated,_grover,_two_regions}.ll`
(`p1`,`p8`,`p4`,`p25`), `..._loop_phi_second_register.ll` (`p26`), `..._loop_phi_k32.ll`,
`..._loop_phi_dynamic_trip.ll` (`p28`), `..._loop_phi_data_use.ll`, plus **the H-10 pins**
`..._rail_inloop_carried_theta_first{,_negated}.ll` (`p2`,`p9` — RED on nothing, byte-unchanged, and
that is the point).

**DECLINE fixtures (~16):** one per §4 row, each RED on `main` `0c7380c` **or** (for the rung-0 rows)
green on `main` for the wrong reason and pinned to the new string; `..._reject_loop_phi_{nested,
multilatch,irreducible,open_cycle,derived_base,measure_body,measure_seed,sibling_theta,tree_leaf,
two_rails}.ll`.

**e2e (STRICT stage 2b), 6 slices + 3 `cmp` twin gates:**
`slice_control_phase_bool_carried_loop{,_unrolled}.c` (`p1`/`p16`, gate: 9 = 9),
`slice_control_phase_bool_grover_loop{,_unrolled}.c` (`p4`/`p4u` — the rolled spelling of the
committed `slice_control_phase_bool_grover.c`, whose header says outright it was **written flat
because of this decline**; gate: 11 = 11), and
`slice_control_phase_bool_carried_theta_first{,_unrolled}.c` (H-10's pin; gate: 9 = 9).
Plus a K-independence MEASUREMENT (not a ctest entry — the 8h7d.5 precedent for
`slice_control_grover_loop_dynamic`): lowered IR line count equal at K=3 and K=1000.

**The twin-matrix axis (the expensive piece).** A new sub-grid whose CONDITION register is a carried
`_Bool` and whose REGION spellings are `if (b)` / `if (!b)` / `if (b && q==k)`, crossed with the
existing PREFIX/SUFFIX gates on a second register and with a PREHEADER op on the bool's own rail
(the F-C1-1 / F3 position). Expect ~24–40 cells; both tables must be regenerated
(`--regenerate` refuses while a boundary control has moved) and `e2e-loop-twin-matrix` costs
~180 s per run. **This is the only instrument in the tree that can see a leaked TEMPLATE-minted
rail, and H-6 is exactly its subject — do not skip it.**

---

## 6. Cost

| | |
|---|---|
| production lines | **~190–260** across 7 files, most of it rationale: `SelectClassify.{h,cpp}` (~65 with the header note), `ArmClassify.cpp` (~70: step-5b φ arm, the wire dispatch, step 7's premise REWRITE, H-8's ternaries), `ArmAnalysis.{h,cpp}` (~40: rungs (ii)/(iii) widened to `const Instruction *` + the chain closure), `LoopLowering.cpp`/`LoopPlan.h` (~30: `railPhiSelfCycleClosed` lifted from step (1)), `CondTreeEmit.cpp` (~10), `RegionFlatten.cpp` (~6), `reverifyRailCondReads` (**20–60, H-1-dependent**) |
| new frozen symbols | **0** (D3) |
| fixtures | ~36 (`ir-pass-lit` 1776 → ~1812) |
| goldens / ctest | +6 goldens (341 → 347), +9 ctest entries (387 → 396: 6 slices + 3 `cmp` gates) |
| instruments | one new twin-matrix sub-grid; both matrix tables regenerated (288 cells → ~315) |
| adversarial rounds | **three, budgeted** (CLAUDE.md's 3-for-3, then 4-for-4, then 8-over-6 record for in-loop work) |
| probe first | **H-1**, then **H-4**, then **H-6** |

H-1 is the only item that can change the cost by more than a factor: if the answer is option (1) or
(3) it is +20–40 lines and a new fixture family; if it turns out the re-verification must move
relative to the collapse, it is a pipeline-ordering change with its own clearance.

---

## 7. Recommendation to the owner

1. **SPLIT THE BEAD. Build the HEADER-φ half (`boi6.a`); file the MERGE-φ half (`boi6.b`) against
   the WIRE fence, not against `isCondRailLeaf`.** §0.3 is measured: `p22`, the plain-`int` compare
   twin of `p5`, declines `condition predates a non-diagonal gate` on `main`, so admitting the merge
   φ as a rail leaf buys `p5` nothing but a different decline string. `boi6.b` is a **drbq
   control-in-place** capability ("read a register a preceding controlled rotation moved") that
   happens to be reachable through a `_Bool`; it has an `int` red-green twin (`p21` accepts, `p22`
   declines) and belongs with `drbq.10`/`drbq.12`, not with 1b.
2. **Answer H-1 before any code is written.** `reverifyRailCondReads` — the stage the previous
   session added to close a CONFIRMED plain-C miscompile — both skips a φ record
   (`ArmClassify.cpp:2075`) and, because `WeakTrackingVH` follows the collapse's RAUW, would then
   refuse the very accept D-A creates. There is no pipeline slot that is both after the round-2
   fixpoint and before the collapse (`394 < 410 < 431`). This is a design decision with three
   named options and a Rule-14 cost attached to two of them.
3. **Pin `p2`/`p9` FIRST, in whatever session touches this** (H-10). A carried `_Bool` whose region
   condition is the in-body chained theta already lowers rolled, twin-identical and K-independent,
   and **no fixture and no slice covers it**. It is the discriminator that D-A changes no shipped
   stream, and it is cheap (2 fixtures, 2 slices, 1 `cmp` gate) — worth doing even if `boi6` is
   deferred.
4. **The customer is real and already in the tree, written the wrong way round.**
   `tests/e2e/slice_control_phase_bool_grover.c` says in its own header: *"⚠ WRITTEN FLAT ON
   PURPOSE … that is this increment's documented residual"*. `p4` is that program as a `for` loop,
   and `p4u.trace` is the 11-line stream it must print. This is the same shape as the flagship
   `for (i…) { oracle; reflection; }` customer that 8h7d.5 shipped for `int` registers — D-A is its
   `_Bool` half.
5. **Do not widen `isCondRailLeaf` or retype `RailLeaves`** (H-3). A new field plus an
   `AllowRailPhi` flag; the type is currently the only thing stopping a φ reaching five consumers
   that never scoped one.
6. **Budget the twin matrix.** H-6 gives the C-1 family a subject it has never had (a CARRIED
   condition register), and the instrument that exists to see that family has no `_Bool` axis at
   all. A sub-grid is not optional here; it is the measurement.
