# X5 — the re-derivation of F2's φ-DESCENDANT dominance skip, after bd `wx8g` fired its trigger

Track X, session 2026-09-14c. Worktree `/Users/sorenwilkening/Desktop/CQ_x5`, branch
`x5-rederivation` off `main` `c8007c37`. **VERDICT: THE NARROWING STANDS. The ARGUMENT was
wrong on its own axis and is rewritten in the source in the same change as this file**
(`ir-pass/src/ArmClassify.cpp` — the `collectStatePrepPhiDescendants` header, its in-helper
comment, trigger (3a), trigger (3b)'s X5 UPDATE, and a new trigger (3c)). The two tripwire
fixture headers are corrected too. **A record correction not applied to the source is not a
correction** (L7-with-a-twist, bd `z9t1`, measured three times on one sentence).

## 0. The binary every row below was measured on

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so
5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4
```

⚠ **The frozen ORACLE for this session IS HEAD's compiler.** Measured, not assumed:

```
$ for d in ir-pass include runtime; do diff -rq $d /Users/sorenwilkening/Desktop/CQ_lang/$d; done
Only in /Users/sorenwilkening/Desktop/CQ_lang/ir-pass: .DS_Store
Only in /Users/sorenwilkening/Desktop/CQ_lang/ir-pass/test: .lit_test_times.txt, Output
```
— no source differs. So every "ORACLE" row here is a statement about the compiler at
`c8007c37`, and there is **no pre-`wx8g` binary on this box** to compare against; the 2026-09-14
oracle `f7b65d8c…` was rebuilt away at that session's close. **That shapes what this
re-derivation can and cannot do:** it cannot re-run the merge gate's two-binary movers, so
every isolation below is constructed to move **on ONE binary**, which is the stronger form
anyway.

## 1. The finding that reframes the whole job: THE TWO NAMED TRIPWIRES WERE NEVER BEHIND `wx8g`'s FENCE

`MERGE_FILINGS.md` §1 and `MERGE_REPORT.md` §6 both report, correctly, that
`control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` **HELD** across the
`wx8g` landing. Re-measured here, they still do:

```
$ trackX/probes/run.sh ir-pass/test/control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll
  DECLINE exit=1 | cq controlled lowering: state prep seed is proven equal to the condition register
$ … _backedge_nonphidesc_collider.ll        DECLINE exit=1 | (same string)
$ … _acyclic_nondominated_phi.ll            DECLINE exit=1 | (same string)
```

**But "held" is much weaker evidence than it reads, and the reason is structural.** The
carve-out `wx8g` retired is quoted verbatim in `ArmClassify.cpp`'s own retirement note:

```
if (RailCond && Region.InLoop) decline("control flow inside a loop body");
```

It is guarded on **`RailCond`** — a BARE `_Bool` rail condition. Both tripwires spell their
condition as a **COMPARE** (`%c = icmp eq i32 %q, 7`). ⚠ **So neither file was ever stopped by
that fence**, and each file's own header says so without noticing: it records the pre-`wx8g`
ORACLE firing **F2** on the module, which is impossible if a fence ahead of F2 had claimed it.
The header nevertheless asserted:

> ⚠ THIS FILE IS DECLINED TWICE OVER TODAY … Every IN-LOOP state prep is stopped before F2 by
> bd `test_C_libtooling-wx8g` (`control flow inside a loop body`) …

**That sentence was false when it was written**, it is the premise that made the trigger read as
"unreachable, therefore inert", and it is corrected in both fixtures in this change. The
consequence for the trigger is exact: *the pair holding across the `wx8g` landing says nothing
about the spelling the trigger was written for.* The bare-rail spelling had to be measured, and
had never been.

## 2. THE BARE-RAIL SPELLING, MEASURED — a three-way isolation on ONE binary

Calibration first, so nothing below is vacuous (bd memory `empty-module-accepts-vacuity-trap`):
the MINIMAL in-loop controlled state prep **accepts in both condition spellings**.

| probe | verdict |
|---|---|
| `w2d_railcond_inloop_prep_minimal.ll` (bare `_Bool`) | **ACCEPT**, STRICT 2b `2 mint(s), 2 left allocated, 0 free` |
| `w1d_cmpcond_inloop_prep_minimal.ll` (compare) | **ACCEPT**, STRICT 2b `2 mint(s), 2 left allocated, 1 free` |

Then the isolation. Each triple is ONE module with ONE operand or ONE φ changed between rows.

**Bare-rail — `wx8g`'s newly-admitted territory** (`w3*`):

| probe | what changed | verdict |
|---|---|---|
| `w3_railcond_inloop_prep_backedge_phidesc_collider.ll` | loop-header φ `%v` takes the `M`-descendant `%carry` on the BACK EDGE | **DECLINE at F2** |
| `w3b_railcond_inloop_prep_only_nonphi_mdesc.ll` | `%v` deleted → the only collider is the NON-φ `M`-descendant `%carry` | **F2 SILENT** (module runs on to `cq uncompute: dead chain would free a measured register`) |
| `w3c_railcond_inloop_prep_only_nonmdesc.ll` | `w3b` with ONE operand changed (`%rm` → `%bz`) so the collider is no longer an `M`-descendant | **DECLINE at F2** |

**Compare-conditioned — the tripwires' own spelling** (`w1*`), all three verdicts reproduce:

| probe | verdict |
|---|---|
| `w1_inloop_prep_backedge_phidesc_collider.ll` | **DECLINE at F2** |
| `w1b_inloop_prep_only_nonphi_mdesc.ll` | **F2 SILENT** (falls to `control flow inside a loop body`) |
| `w1c_inloop_prep_only_nonmdesc.ll` | **DECLINE at F2** |

**What the triple proves, stated as the two separate questions it answers.**
`w3b` vs `w3c` differ by one operand and nothing else, so F2's silence on `w3b` is attributable
to **φ-descendant MEMBERSHIP** and to nothing about the loop, the rail, or the trip count — the
exclusion is **LIVE, not vacuous**, in `wx8g`'s territory. `w3` vs `w3b` says the dominance skip
still puts the **AVAILABLE** collider back: a loop-header φ that dominates both of F2's slots is
not excluded, and F2 finds it. **The cyclic hole the round-1 review opened is closed in the
spelling that was never tested.**

### 2a. Two scaffolds that FAILED, recorded because a failed construction is data (L5)

* `w1`/`w1b` first attempt (a bare rail `%b` plus a separate condition rail): both declined
  `control flow inside a loop body` anchored on `%b`, i.e. R7's rollability clause, before F2.
* `w2`/`w2b`/`w2c` (an EXTRA loop-invariant `i32` rail read inside the body as the LVI anchor):
  `w2` declined earlier still, at `lowerLoops` — `loop-carried tainted value crosses iterations`;
  `w2b`/`w2c` at R7. ⚠ **The anchor choice is load-bearing**: a hoisted loop-invariant rail read
  in the body is itself a decline (CLAUDE.md's Q-R1-1), so the anchor has to be the CONDITION
  rail, reached forward through `%bz -> %mask2 -> %mask -> %carry`. `w3` does that.
  A reviewer re-running this must not read `w2*`'s declines as the skip working.

## 3. "DO NOT ASSUME THE φ CASE IS THE ONLY CYCLIC ONE" — DISCHARGED, by retiring the axis

The trigger's second sentence is the part three merge-gate probes could not touch. It is
discharged **not** by enumerating cyclic shapes but by replacing the argument with one in which
cyclicity is not a term.

### 3a. The invariant, and its induction

`PhiDesc`'s members all lie in a block **dominated by `MergeBB`**. Induction over the insert
order in `collectStatePrepPhiDescendants`:

* `M` itself — `DT.dominates(MergeBB, MergeBB)` is true;
* a **non-φ** user `I` of a member `V` — SSA requires `V`'s def to dominate the use, so
  `dom(VBB, IBB)`; with `dom(MergeBB, VBB)` and transitivity, `dom(MergeBB, IBB)`;
* a **φ** user — the one case SSA does not give, and **exactly** what
  `if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent())) continue;` tests.

### 3b. Why the invariant is SUFFICIENT — and this step is structural, from `recoverRegion`

`ControlDetect.cpp`'s `recoverRegion` admits a **Diamond** only when
`Arm->getSinglePredecessor() == Pred` and `soleMergePhi(MergeBB)` has **exactly two** incoming
values. A φ's incoming count is its block's predecessor count, so `MergeBB`'s only predecessors
are `Pred` and the arm, and the arm's only predecessor is `Pred`. Hence **every** path from
entry to `MergeBB` passes `Pred`: `Pred` strictly dominates `MergeBB` whenever it is reachable.
(**If/else** is the same — `MergeBB`'s two predecessors are the two arms, each single-pred
`Pred`.) Dominance is antisymmetric, so `MergeBB` dominates **neither `Pred` nor the arm**; and a
member's block, being dominated by `MergeBB`, dominates neither of them either. That **is**
"unavailable at the arm theta's arg-0" and "unavailable on the merge φ's pred edge".

⚠ **Nothing in that derivation mentions a cycle.** It holds verbatim for a region inside a loop:
on any entry path the FIRST arrival at `Pred` precedes `MergeBB`, whatever the back edges do. A
nested loop, a back edge into a non-header block, and a purely classical bypass that re-joins
after the region are **one case** to this line. That is the discharge.

### 3c. Is a φ the only opcode that can break the induction? — a SEMANTIC answer, not a list

The property that breaks it is *"this user's operands need not dominate its own definition"*.
LLVM 19 spells that in **one** place: `DominatorTree::dominates(const Value *Def, const Use &U)`
picks `UseBB` as `PN->getIncomingBlock(U)` for a `PHINode` and `UserInst->getParent()` for
everything else. `/usr/local/opt/llvm@19/include/llvm/IR/Dominators.h:181-191` documents the
three exceptions to that API; the other two —

> * Non-instruction Defs dominate everything.
> * Invoke Defs only dominate uses in their default destination.

— **narrow** availability, so they can only ever remove a rival.

**Measured rather than asserted** (all three modules are rejected as invalid IR, i.e. the shapes
are not expressible at any `-O` level):

```
$ /usr/local/opt/llvm@19/bin/opt -passes=verify -S trackX/probes/a1_nonphi_mdesc_at_arm_slot_INVALID.ll
Instruction does not dominate all uses!   %bad = add i32 %m, 0 ; %t = call @cq_theta_si32(i32 %bad, …)
$ …                                          a2_nonphi_mdesc_at_pred_slot_INVALID.ll
Instruction does not dominate all uses!   %bad = add i32 %m, 0 ; %m = phi i32 [ %t, %arm ], [ %bad, %entry ]
$ …                                          c4_arm_block_phi_taking_M_INVALID.ll
Instruction does not dominate all uses!   %m = phi … ; %ap = phi i32 [ %m, %entry ]
```

⚠ **WHAT IS SKIPPED, SAID PLAINLY (L5).** No enumeration of LLVM's ~65 instruction opcodes was
performed, and none is owed: the reliance is on the **Verifier's own rule**, which is
opcode-agnostic apart from that single `dyn_cast<PHINode>`. What is NOT covered: a future LLVM
release that gives another instruction per-edge value operands. That is now a written retirement
trigger (3c) rather than an unstated premise.

### 3d. Where the `isa<PHINode>` conjunct is load-bearing — and the correction it earns

The in-helper comment said *"It is a no-op on every NON-φ user and is spelled for φs only to say
so"*. True, and incomplete in the direction that matters: it is ALSO the only thing that would
keep a hypothetical per-edge-operand opcode out of the set, because `isa<PHINode>(I) &&`
**short-circuits** and such a user would be inserted unchecked. Both halves are now written.

**The opcode-agnostic spelling** — delete the conjunct, keep `if (!DT.dominates(MergeBB,
I->getParent())) continue;` — is behaviour-neutral on valid IR (the no-op argument *is* the
proof) and removes the dependency on the opcode question entirely. **NOT TAKEN HERE**: it is a
Rule-13 core edit on `f2SeedPinnedByLiveRegister`, the function that lost four consecutive
adversarial rounds in drbq Inc 4, and it needs its own red-green and its own round. **FILED** as
source trigger (3c) and as a bd issue.

### 3e. Two residuals named rather than waved at

* **`DT` currency.** The tree is built fresh per `detectControlRegions` sweep, lazily, one per
  function (`ControlDetect.cpp:798` / `:877`, `DT.emplace(F)`), and detection mutates nothing — so the walk
  and the dominance test read the same module. Round 2 (`repropagateControlMerges`) builds
  another. `lowerLoops` — which is where `wx8g`'s `collapseRailPhisIn` RAUWs live — runs at
  `CQLoweringPass.cpp:393`, **before the first** `detectControlRegions` (`:475`), and is not
  re-run in round 2 (`TaintPropagation.cpp:1709`'s body re-runs the peel, detection and lowering
  and then `collapseFlattenedLoopRails` **after** the fixpoint). So `wx8g` added **no RAUW inside
  the round-1→round-2 window**, and the header's emitter polarity table still has the right
  scope. Its own polarity is SHRINKING anyway: `railChainRootMint` (`LoopLowering.cpp:403`)
  accepts only a mint whose arg-0 is **untainted**, and `railPhiRootMint` (`:361`) additionally requires
  `DT.dominates(Mint, L->getHeader())`, so the RAUW target is strictly **upstream** of `M` and
  cannot be an `M`-descendant. A shrinking exclusion set only ever adds declines.
* **Reachability.** `DT.dominates(A, B)` answers "an unreachable node is dominated by anything"
  and "an unreachable node dominates nothing", so when `MergeBB` is unreachable the invariant is
  vacuous. Detection iterates every block, including unreachable ones; `-O1` deletes them, and an
  unreachable region's gates never execute, so this is not a unitary hazard — but it is a premise
  and it is now written into trigger (3a) beside the structural one.

## 4. `hrts` / `l3i1` — the reconciliation

Both issues say the dominance skip is *"broader than its stated rationale"* and that a trigger
naming only `wx8g` describes *"the CYCLIC half"*. **The reconciliation is that the CYCLIC/ACYCLIC
split is the wrong axis, and the right one is AVAILABILITY.**

There is **one** predicate, **one** invariant and **one** imprecision. The invariant is
**sufficient** for "unavailable at both slots" and **not necessary**. So:

* the **back-edge** case is the sub-case where the dropped φ **is** available at a slot — a
  genuine hazard, and the reason the line exists;
* the **bypass** case is the sub-case where it is **not** — pure capability cost.

Cyclicity does not separate them; availability does. `hrts`'s proposed option (b) — test the
MEMBER against the SLOTS — is precisely the move from the sufficient condition to the
necessary-and-sufficient one, and that is the correct framing for the owner decision.

**Three measured corrections to the filings**, all now in source trigger (3b):

1. **The cost is isolated on ONE binary**, which `r20` could not do (it moved only *between*
   binaries, and neither binary exists here any more). `c2_inloop_acyclic_bypass_nondominated_phi.ll`
   and `c2c_inloop_bypass_phi_DOMINATED_by_merge.ll` are the same program, the same collider
   value `%p` and the same loop; they differ only in whether the classical bypass sits inside the
   merge-dominated region.

   | probe | `%p`'s block dominated by `MergeBB`? | verdict |
   |---|---|---|
   | `c2` | no (bypass around the region) | **DECLINE at F2** |
   | `c2c` | yes (bypass nested after the merge) | F2 silent → `cq uncompute: dead chain would free a measured register` |
   | `c2d` (`c2` with `%p` deleted) | — | F2 silent → same later decline |

   `c2` vs `c2d` attributes the F2 to `%p` alone; `c2` vs `c2c` shows the verdict turns on block
   placement and nothing else.

2. ⚠ **THE `hrts` TRIGGER IS STILL NOT MET, and this must not be overstated.** The live-chain
   variant `c2c_…_live.ll` declines at `cq taint escape: tainted value muxed by a
   classical-condition phi` — exactly the `declineClassicalMuxes` masking `hrts` already names.
   So an *ACCEPT-on-the-precise-predicate vs DECLINE-here* pair remains **unconstructed**. "The
   cost is isolated on one binary" is a strictly weaker claim than "an accept is demonstrably
   lost", and the filings should keep saying the second is not yet shown.

3. **Option (b) is CHEAPER than `hrts` states.** `hrts` asks for
   `isa<PHINode>(I) && DT.dominates(I, BI)` **"plus a second clause for the ARM slot — a φ at the
   top of the arm block taking `M` on a back edge is available at the arm and not at the pred"**.
   ⚠ **That second clause is not needed for any region this pass detects.** `recoverRegion`
   requires the arm to be single-predecessor(`Pred`), so every φ in an arm block has exactly ONE
   incoming, on the `Pred`→arm edge, which `M` does not dominate — the shape is **not
   expressible** (`c4_arm_block_phi_taking_M_INVALID.ll`, rejected by `opt -passes=verify`, §3c).
   Option (b) is therefore one clause plus threading the `BranchInst` through.

## 5. `f2SeedPinnedByLiveRegister`'s OTHER trigger — CHECKED, NOT TOUCHED

The brief asks whether this work touches the `railWireClosure`-vs-`CondRails` trigger (the
`CondWire` narrowing the owner's three-bool file depends on). **It does not.** This change edits
comments only; `CondWire` is still built at the call site from `railWireClosure(Region.Condition,
…)` plus one call per `Prov` member, and the φ-descendant set is still a separate local set
consulted as an independent conjunct at the TEST (`ArmClassify.cpp`, the
`!CondWire.count(V) && !Taint.isPeelClone(V) && !PhiDesc.count(V)` line). No helper, `WireDir`,
seed set or `Exclude` moved.

⚠ **AND NOTHING HERE BEARS ON A MEMORY-RESIDENT WIRE.** The re-derivation is entirely about SSA
users and dominance; no load, store, `alloca` or address edge enters the argument at any point.
Tracks A and B can treat this track as orthogonal.

## 6. The tripwire fixtures — kept, headers corrected, NOT renamed

Both still DECLINE at F2 and both keep their `RUN: not … | FileCheck` lines and their CHECK
strings unchanged. Their headers gain the §1 correction (they were never behind `wx8g`'s fence),
the trigger is marked **FIRED and DISCHARGED** with a pointer to this file and to `w3*`, and the
live obligation is restated: *if either file's string changes to anything other than F2's, the
narrowing has been lost, not widened.* ⚠ **Neither file was `git mv`'d** — L8 records that a
merge can resurrect a renamed fixture and leave one module under two names with contradictory
verdicts.

## 7. What this re-derivation did NOT do

* It did **not** rebuild a pre-`wx8g` binary, so it reports no two-binary movers; every isolation
  is single-binary by construction (§0).
* It did **not** change any predicate. The narrowing is owner-ruled (2026-09-14 Q1) and stands.
* It did **not** enumerate LLVM opcodes (§3c) — deliberately, and the residual is a trigger.
* It did **not** construct an ACCEPT lost to the acyclic half (§4.2). That remains a failed
  construction, not a proof of absence.

## 8. FILED

| bd | what |
|---|---|
| **`test_C_libtooling-dpau`** (new, P3) | §3d — drop the `isa<PHINode>` conjunct so the dominance guard is opcode-agnostic. Behaviour-neutral on valid IR; a Rule-13 core edit, so filed with the measurement it needs (rebuild, corpus sweep for ZERO movers, state-prep family byte-compared). Named in source trigger (3c). |
| `test_C_libtooling-om35` | noted: the trigger fired, the re-derivation is done, the five headlines, and the gate lines. |
| `test_C_libtooling-hrts` | noted: the three corrections of §4 — wrong axis, cost isolated on ONE binary (but the trigger still NOT met), and option (b) is cheaper than filed (the ARM-slot clause is not expressible). ⚠ Its pre-existing note was clobbered by a `bd update --notes` (which REPLACES) and was restored verbatim in the next call; use `--append-notes`. |
| `test_C_libtooling-l3i1` | noted: same reconciliation, pointing at the `hrts` note for the detail. |
