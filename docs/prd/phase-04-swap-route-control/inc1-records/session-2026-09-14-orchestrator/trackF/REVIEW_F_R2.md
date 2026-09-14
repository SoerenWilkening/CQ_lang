# REVIEW — Track F, adversarial ROUND 2 (Rule 13), bd `om35`: F-F1-5, the M-β drift

**Reviewer:** independent; did not write the code and did not perform round 1. **Date:** 2026-09-14.
**Subject:** `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`, tip
`1a60bb0dd841cde3eb72158be8287362d35cb08e` (verified, `git rev-parse`).

## 0. FIRST ACT — binary hashes

```
/Users/sorenwilkening/Desktop/CQ_f2phi/build/ir-pass/cq-opt
  96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1   MATCHES brief (SUBJECT)
/Users/sorenwilkening/Desktop/CQ_f2phi/build/ir-pass/libCQPass.so
  9537a0ce0c56548e3cc27f273a15a84995ce21dd7754d608d160e064fd9ad68e   MATCHES brief (SUBJECT)
/Users/sorenwilkening/Desktop/CQ_f2phi/build/prefix_147cb3d6/cq-opt
  147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4   MATCHES brief (PRE-FIX)
/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
  f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc   MATCHES brief (ORACLE)
/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so
  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d   MATCHES brief (ORACLE)
```

All five match. **No build, no `ctest`, no `lit`, no corpus sweep, no twin matrix was run** — every
measurement below is a per-probe invocation of one of the three existing binaries. The brief's
one-lit-fixture allowance was **not spent**: the fixture-pair check in §4 is a direct
`cq-opt` + `FileCheck` probe, not a lit run. Every generated `.ll` had its byte size printed before
it was measured (`review_r2_probes/run.sh` aborts on 0 bytes).

---

## VERDICT: **CLEAR-WITH-ITEMS**

**F-F1-5 is CLOSED, by PROOF OF UNREACHABILITY plus a measured isolating pair — not by assertion,
and not by the "it is recomputed" argument the implementer correctly refused to close it with.**
I could not construct the drift, and I can say *why* no one can: the invariant that forbids it is one
line of `ArmClassify.cpp`. Two items remain, both in the accept-direction-is-unaffected class:
**F-F2-1** (the source's stated L1 answer is still the wrong argument, and the right one is
unwritten — the L7 shape), and **F-F2-2** (the round-1 fix's predicate is measurably **broader than
its stated rationale**, with a reachable **acyclic** customer that its retirement trigger does not
name). **F-F2-3** closes the round-1 count disagreement: all three numbers reproduce.

---

## 1. THE PRIMARY ASSIGNMENT — F-F1-5, the M-β drift

### 1a. The question, restated so the answer can be checked against it

> Can round 1's RAUW manufacture a φ-descendancy the SOURCE did not have — making a round-2 region
> `B`'s `PhiDesc` contain a value that, in the module `clang` produced, was a writable register at one
> of `B`'s slots and was pinned to its seed?

### 1b. **FIRST: the round-2 F2 call is REACHABLE. The question is live, not moot.**

I established this before arguing about it, because an unreachable round-2 F2 would make the whole
finding vacuous and I did not want to prove something about nothing.

`review_r2_probes/r5_round2_phidesc.ll` (1664 B) is the `control_peel_round2_out_cond.ll` skeleton:
a **6.5 classical-call arm** produces `%out` (CLASSICAL at round 1 — the call result is not tainted),
so `icmp eq i32 %out, 13` is not a tainted branch in round 1 and region **B** — a state prep,
seed `i32 0` — is detected **only after `repropagateControlMerges` re-seeds**. Its collider is
`%zm = trunc i64 (mul i64 (add i64 (zext %out), -13), (zext %MB)) to i32`, which folds to `{0}` on
B's TRUE edge (where LVI pins `%out` to 13) and is a **direct user of B's own merge φ `%MB`**.
The i64 hop is deliberate: it keeps the intermediate off the TEST's `V->getType() == Seed->getType()`
clause, so the collider that fires is `%zm` and not the pinned intermediate. (My first two attempts,
`r1c`/`r4`, were **vacuous for exactly that reason** — `%d = add i32 %out, -13` is itself an i32
collider — and are kept in the probe directory labelled as vacuous.)

| probe | ORACLE | PRE-FIX | SUBJECT |
|---|---|---|---|
| `r5_round2_phidesc.ll` | **F2 declines** | **ACCEPT** | **ACCEPT** |
| `r5c_round2_nonphidesc.ll` — the isolating control, ONE operand changed (`%MB` → `%q`) | F2 declines | F2 declines | F2 declines |

`CQ_CTRL_DBG=1` on `r5c` prints the decline anchor as `%c2 = icmp eq i32 %out1, 13` — **the operand
name `%out1` is the round-1-emitted out-rail**, which is the proof that this F2 call is the round-2
one. `r5`'s PRE-FIX and SUBJECT lowered IR are **byte-identical** (`cmp`).

So: the φ-descendant conjunct **does fire in round 2, over the post-round-1-emission graph**. F-F1-5
is asking about a real window.

### 1c. THE ANSWER: **PROVEN UNREACHABLE.** The drift §R2 names is self-defeating.

The implementer's scenario is *"M-β RAUWs `M_A` to the arm's theta call `T_A`; if `T_A`'s base is
derived from a different region `B`'s merge φ, every former user of `M_A` transitively reaches
`M_B`."* Every clause of that is true. What it omits is the **pre-RAUW** edge that already existed:

**`ArmClassify.cpp:823` — `if (!T->hasOneUse() || T->user_back() != MergePhi) return nullptr;`.**

`inPlaceRotationArmTheta` admits an arm theta **only when the merge φ is its SOLE user**, and
`SwapRouteEmit.cpp:752-758` re-checks `Shadow.size()==1` and `T->getArgOperand(0) == Base` before
putting it in `Gates`. So at classification time `M_A` **is a user of `T_A`**. Therefore, for any `X`:

```
   X →* T_A   (pre-RAUW)
⟹ X →* M_A               because M_A USES T_A — the arm incoming IS the theta call
⟹ X →* every user of M_A
```

and those are precisely the values the RAUW re-parents onto `T_A`. **The forward closure of `M_B` is
unchanged.** The drift requires `M_B` to reach the RAUW *target* while not reaching the φ it
replaces, and that is impossible when the target is (a descendant of) one of the φ's own incomings.

The invariant holds at **every** M-β spelling, and I checked all three by reading
`SwapRouteEmit.cpp:898-960` and `:1105`:

| M-β variant | RAUW target | why it cannot grow a closure |
|---|---|---|
| diamond, un-negated | `T` itself, `moveBefore(BI)` — same `CallInst`, same operands | `M_A` was its sole user |
| if/else (2 gates) | `T2`, after `T2->setArgOperand(0, T1)` (`:948`) — a genuinely NEW SSA edge | `M_A` used **both** `T1` and `T2`; reaching `T2` post still requires reaching `Base`, which reached `T2` pre |
| negated rail arm | `TNeg`, a clone with `arg0 = T` (`:917`) and `arg1 = fneg(angle)` (`:930`) | `TNeg`'s only two operand roots are `T` and `T`'s own angle operand; both already reached `M_A` |

**The polarity check the brief asked for first, completed over every merge RAUW in the tree** (the
sites that run between round-1 detection and the round-2 `classifyArms`):

| site | target | direction |
|---|---|---|
| `SwapRouteEmit.cpp:1105` (M-β) | `Gates.back().first` — a descendant of an incoming | **neutral** (proof above) |
| `SwapRouteEmit.cpp:1295`, `:1534` (M-α) | `Q`, the straight-through **incoming** | **neutral** — same argument |
| `RegionFlatten.cpp:176` | `Q`, an incoming | **neutral** |
| `SelectMergeEmit.cpp:386`, `SwitchValueEmit.cpp:376`, `SwitchDataMuxEmit.cpp:230` | a fresh `cqrt_alloc` result, **no operands** | **SHRINK** |
| `SwapRouteEmit.cpp:536` (`emitValueRegion`) | `Sel = select Cond, TV, FV` — **gains `Cond` as an operand** | **CAN GROW** — see §1d |
| `MergePhiPeel.cpp:559` | `Sel = select CondV, TV, FV` — **gains the condition clone** | **CAN GROW** — see §1d |
| `SwapRouteEmit.cpp:1469` | `First->setArgOperand(0, Q)` on a `cq_phi` call | inert — the call is **void**, so it has no users to carry anything forward |

### 1d. The one vector that CAN grow a closure — and why it does not reach a round-2 F2

The brief named two RAUW sites. There is a **third shape** neither named, and it is the only one with
the right polarity: a **`select` that replaces a φ gains the CONDITION as an operand**, which the φ
never had. So `M_B →* Cond` now implies `M_B →*` every former user of that φ. That is genuine growth.

It does not reach a round-2 F2, for a reason that is measured, not assumed:

* **`emitValueRegion`'s `Sel` is transient.** It is RAUW'd to the out-rail and erased inside
  `emitSelectRegion` (`SelectMergeEmit.cpp:386`) **in the same round**, so what survives into round 2
  is the fresh `cqrt_alloc` — the SHRINK row.
* **`MergePhiPeel`'s `Sel` is consumed in the round that made it.** For the manufactured edge to be
  an `M_B`-descendancy, the peeled region's **condition must be `M_B`-reachable** — and `M_B` is a
  merge φ whose arm incoming is a `@cq_theta` result, so `M_B` is **tainted in round 1**, so anything
  `M_B`-reachable is tainted in round 1, so that region is claimed, peeled and lowered in round 1 and
  its select is an out-rail before round 2 ever runs.

Measured, on modules built to be exactly that shape:
`r10_peel_manufacture.ll` / `r10c_peel_offcone.ll` and `r11_peel_manufacture_prep.ll` /
`r11c_peel_prep_offcone.ll` differ **only** in whether the peeled region's condition is
`icmp eq i32 %MB, 3` (on `M_B`'s cone) or `icmp eq i32 %q, 3` (off it). Each pair is **identical on
all three binaries**, and `CQ_CTRL_DBG` attributes both `r11` declines to the same round-2 anchor
`%c2 = icmp eq i32 %out1, 13`. If the peel had carried a manufactured descendancy into round 2, the
on-cone member of each pair would have accepted. **Neither did.** (Label this honestly: a structural
argument with a *successful* isolating measurement on the shape it is about, not an exhaustive proof
over every peel shape.)

### 1e. And if one ever escaped, the exclusion would still be SOUND — the second layer

This is the layer I would want written down even though nothing needs it today, because it is what a
future emitter widening will be judged against.

Every manufactured edge in the table above re-parents **the users of a JOIN φ `P`** onto some `W`.
If a pre-existing `V` gains membership in `PhiDesc_B` through such an edge, then `M_B →* W`, and `W`
lies inside the region whose merge is `P` — so `M_B`'s block dominates that region's `Pred`, hence
`P`'s block. `B`'s merge block does **not** dominate `B`'s `Pred` (which strictly dominates it) nor
`B`'s arm. Therefore **`P` is available at neither of B's two slots** — and `V`'s *source* operand
chain reaches `P`. The availability argument still licenses the exclusion; it is simply **anchored at
`P` instead of at `M_B`**. That the anchor moves is exactly what the source does not say (F-F2-1).

### 1f. The interaction the brief told me to establish: **it is 2c, and R4 never gets a turn**

The brief warned not to assume "R4 would have caught it". It would not have. The fence that actually
stands in front of my first, most natural spelling of the drift is **gate 2c**:
`r1_mbeta_drift.ll` declines `condition predates a non-diagonal gate` on **all three** binaries, and
`CQ_CTRL_DBG` attributes it to `%z = select i1 %cs, i32 %d, i32 %e` — i.e. the collider I wrote as a
`select` **became its own 4.4 select region**, whose condition reads a rail that a controlled Ry has
already relabelled. That is a Prime-Directive decline, **not a proof**, and I did not use it as one:
§1c is the proof and §1c is independent of it. I record 2c here only so the merge gate knows which
fence is load-bearing for this family, and so nobody later "widens 2c" believing F-F1-5 is still
closed by something else.

### 1g. The measured corroboration, with its isolating control

| probe | shape | ORACLE | PRE-FIX | SUBJECT |
|---|---|---|---|---|
| `r6_mbeta_base_is_MB.ll` | region A = in-place Ry, **base = `%MB`**, collider uses `%MA` | F2 declines | **ACCEPT** | **ACCEPT** |
| `r7_mbeta_base_offcone.ll` | same, but A's base is an independent rail `%q2` — **off `%MB`'s cone** | F2 declines | **F2 declines** | **F2 declines** |
| `r12_mbeta_ifelse_rechain.ll` | A is an **if/else** with two in-place Ry arms (the `T2->setArgOperand(0,T1)` edge), base off-cone | F2 declines | **F2 declines** | **F2 declines** |

`r7` and `r12` are the **tripwires for the theorem**. In both, region A is emitted in round 1, its
merge φ is RAUW'd by M-β, and the collider is a user of that φ — the exact re-parenting §R2 is about.
If the RAUW manufactured a descendancy, the collider would be excluded and they would **accept**.
They decline, on the round-2 anchor `%c2 = icmp eq i32 %out1, 13`. `r6` accepts because in the
**source** `%zm`'s chain reaches `%MB` twice over (through `%MA`'s pred incoming **and** through
`%ta`'s base) — the exclusion is licensed by the source closure, not by the RAUW.

Rule 2 — I read `r6`'s emitted stream rather than its exit code. The round-2 prep is
`alloc_i32(0)→h5; ry_i32_controlled(h_cmp4, h5, 0.5)` on the flag minted from the round-1 out-rail;
region A's arm is `ry_i32_controlled(h_cmp3, h5, 0.25)` **in place on the same `h5`** — the M-β chain
is visible in the stream, `h5` is frozen (never `cqrt_x`-bracketed, never freed, correct for
`Ry|0⟩ ≠ |0⟩`), and both compare flags are `_unc`-stripped and freed.

---

## 2. Findings

### F-F2-1 — the source's L1 answer proves the WRONG THING, and the right invariant is unwritten. **Severity: documentation / L7. Fix before merge (a comment).**

`ArmClassify.cpp`, `collectStatePrepPhiDescendants`' header, says:

> *"the answer is a pure function of the module in front of this call, so recomputing it in BOTH
> detection rounds is automatic and there is no premise for `repropagateControlMerges` to falsify (L1)."*

Round 1 already said this proves recomputation, not stability. It is worse than that: **as an L1
answer it is backwards.** Recomputation over a graph a previous round mutated *is* the PREDICATE
species — it is what happened in bd `9pum`/`r9e5` F-B1R2-1 and in bd `b6ap` F-B6-1. The sentence
names the mechanism that creates the hazard and calls it the reason there is none.

The real reason is §1c, and it lives in a **different file**: `M_A` is the sole user of the arm
theta, so M-β's RAUW target is a descendant of the φ's own incoming. Nothing in `ArmClassify.cpp`
records that it depends on that, and nothing in `SwapRouteEmit.cpp` records that F2 depends on it.

**Minimal fix** (no code): replace the paragraph with

> The set is recomputed in both rounds, and **recomputation is not the argument** — round 1's emitters
> mutate the user graph this walk reads, which is the L1 PREDICATE species exactly. What makes the
> round-2 set equal to the source's is a property of the EMITTERS: **every merge-φ RAUW in the tree
> targets either a fresh `cqrt_alloc` result (no operands — the closure SHRINKS) or a value that is
> the φ's own incoming, or a descendant of one** (`SwapRouteEmit.cpp:1105` M-β → `Gates.back().first`,
> whose original had `MergePhi` as its SOLE user by `inPlaceRotationArmTheta`'s `T->hasOneUse() &&
> T->user_back() == MergePhi`; `:1295`/`:1534` M-α and `RegionFlatten.cpp:176` → the straight-through
> incoming). Reaching such a target already reached the φ, so no pre-existing value gains
> descendancy. **RETIREMENT TRIGGER: the day any emitter RAUWs a merge φ to a value that is NOT a
> descendant of one of that φ's incomings — the shape `emitValueRegion`'s `select` (`:536`) and
> `MergePhiPeel`'s (`:559`) already have, since both gain the CONDITION as an operand — this
> conjunct is reading a graph the pass manufactured and must be re-derived. Those two are safe today
> only because their `select` is RAUW'd to an out-rail and erased inside the SAME round.**
> (Round-2 Rule-13 review, F-F2-1; probes `review_r2_probes/r{5,6,7,10,11,12}`.)

A one-line pointer in `SwapRouteEmit.cpp` beside `MergePhi->replaceAllUsesWith(Gates.back().first);`
saying that F2's φ-descendant conjunct depends on the target being an incoming-descendant would make
the coupling visible from the side that can break it. Per L1's own prescription — *record where the
answer is known, ask where it is needed* — the emitter is where the answer is known.

### F-F2-2 — the round-1 fix's predicate is BROADER than its stated rationale: a measured **ACYCLIC** mover, and the retirement trigger names only the in-loop one. **Severity: over-decline (safe direction) + mis-scoped trigger (L7/L8). Item, not a blocker.**

The fix, its source comment, both fixture headers and §CG all present the narrowing as being about
**one** thing: *"a φ is the one opcode whose operand need only dominate its incoming EDGE, so a
LOOP-HEADER φ can take an `M`-descendant on its BACK EDGE"*, with the retirement trigger
*"bd `wx8g`, BY NAME … the ONLY reason the back-edge shape is unreachable"*. Round 1's own reasoning
says the same: *"for a φ to use `M` and dominate the arm requires a cycle (I checked …)"*.

That is true of the **available-at-both-slots** subcase. It is **not** what the shipped predicate
tests. `!DT.dominates(MergeBB, I->getParent())` also fires on a perfectly **acyclic** CFG whenever a
φ's block is merely not dominated by `MergeBB` — which needs no cycle at all, only a branch that
bypasses the region and re-joins after it.

**Measured.** `review_r2_probes/r20_acyclic_nondominated_phi.ll` (1291 B): an opaque classical guard
`icmp sgt i32 %arg, 100` bypasses the state-prep diamond; `%u` in the merge block is an `M`-descendant
folding to `{0}`; `%p = phi i32 [ %u, %mB ], [ 0, %Y ]` sits in a block `%mB` does not dominate.
**Acyclic — there is no loop anywhere in the module.**

```
ORACLE   exit=1  state prep seed is proven equal to the condition register
PRE-FIX  exit=1  cq taint escape: tainted value muxed by a classical-condition phi   <-- F2 did NOT fire
SUBJECT  exit=1  state prep seed is proven equal to the condition register           <-- F2 fires again
CQ_CTRL_DBG (SUBJECT): decline [state prep seed …] at:  %c = icmp eq i32 %q, 7
```

So the fix **moves this module**, and it is not a back-edge shape. Two consequences, and they point
in opposite directions:

* **The direction is safe.** `%p` is not available at either slot (`%J` does not dominate `%pre`), so
  the PRE-FIX exclusion was in fact *licensed* by the availability ground, and the POST-FIX decline is
  an **over-decline** — a capability cost, not a correctness gain. Both binaries decline this module
  at the top level (the pre-fix one falls through to `declineClassicalMuxes`), so **no shipped
  capability is observably lost**, and the implementer's monotonicity theorem (exclusions only
  shrink ⇒ declines only grow) covers it exactly. Per the owner's 2026-09-11 ruling an over-decline
  is a defect to remove, but this one is unobservable at the top level today.
* **The mis-scoped trigger is the part that can hurt.** A reader who lands `wx8g` and does what the
  trigger says — *"re-derive this set's dominance narrowing against the shapes `wx8g` admits"* — will
  be re-deriving a predicate they have been told is about cycles, while it has acyclic customers.
  That is the L7 shape (a justification narrower than the thing it justifies, hardening by
  repetition) and the L8 remedy (write the trigger so it is character-for-character true of the
  binary) is cheap here.

**Minimal fix, option (a) — documentation only, recommended for this merge.** Add to the helper's
comment and to both fixture headers: *"⚠ THE PREDICATE IS BROADER THAN THE SHAPE THAT MOTIVATED IT.
`!DT.dominates(MergeBB, …)` also removes a φ in an ACYCLIC CFG whose block is merely not dominated by
`MergeBB` (a branch bypassing the region and re-joining after it) — MEASURED as a mover between
`147cb3d6…` and `96fdd3a9…` on `review_r2_probes/r20_acyclic_nondominated_phi.ll`, which contains no
loop. Those members WERE licensed exclusions, so this is an over-decline in the safe direction, not a
correctness repair. `wx8g` is the trigger for the CYCLIC half only."*

**Option (b) — make the predicate precise.** The question the fix actually needs is *"is this φ
AVAILABLE at a slot?"*, not *"is it dominated by `MergeBB`?"*. The member-against-the-slots form,
`if (isa<PHINode>(I) && DT.dominates(I, BI)) continue;`, keeps the back-edge fixture red-on-pre-fix
(the loop-header φ dominates the branch — that is the whole finding) and stops moving `r20`. ⚠ It
needs the `BranchInst` threaded into the helper, and it needs a **second clause for the ARM slot** (a
φ at the top of the arm block taking `M` on a back edge is available at the arm and not at the pred),
so it is a Rule-13 core edit with its own red-green and its own review round. **I recommend (a) for
this merge and (b) as a filed follow-on**, precisely because (b) is a predicate change and this
project's measured hit rate says a predicate change costs a round.

### F-F2-3 — the duplicate-body count: **FULLY RECONCILED at 7 / 8 / 9.** The round-1 reviewer's 8 does reproduce. **Severity: record hygiene, resolved.**

The implementer recorded the reviewer's 8 as "unreconciled by one group". It reconciles: the axis is
**how a comment line is detected**, not only blank lines. Measured on the subject tree
(`review_r2_probes/dupscan.py`, 1932 fixtures; identical with the two fix fixtures excluded, 1930):

| comment detection | blank lines | groups |
|---|---|---|
| `line.lstrip().startswith(';')` | KEPT | **7** ← the implementer's N1 |
| `line.startswith(';')` (column 0 only) | KEPT | 6 |
| `line.startswith(';')` (column 0 only) | DROPPED | **8** ← **the round-1 reviewer's number** |
| `line.lstrip().startswith(';')` | DROPPED | **9** ← the implementer's N2, and IMPL §8's figure |

`8` is what you get from the natural spelling `if line.startswith(';'): continue` — which keeps
**indented** comment lines as body. Both earlier scans were correct; neither was wrong about the
tree. The one group that separates 8 from 9 is
`control_predmux_reject_selectform_rotation_hop_chained.ll` / `…_poison_arg.ll` (they differ only in
an indented comment).

Also measured, over the **union of all 9 groups across all four normalisations**: **0 groups with
contradictory verdicts** (I classified each member by whether its RUN line carries `not`) — so the L8
"one module under two names with opposite verdicts" hazard is absent, confirming the implementer's
claim by a different method. And all **four** fixtures this increment added are in groups of size
**1** under all four normalisations.

---

## 3. Second readings of the fix's four added lines

I went looking for a second reading of each and found no defect; recording what was checked and what
the answer rests on, so the next round does not re-do it.

* **Can `DT.dominates(BB, BB)` crash on a block with no tree node?** No — and this is worth pinning
  because the very same function carries a comment about `LazyValueInfo` SIGSEGV-ing on an API
  precondition. LLVM 19 `include/llvm/Support/GenericDomTree.h:430-442`: *"An unreachable node is
  dominated by anything"* → `true`; *"And dominates nothing"* → `false`. Null nodes are handled, not
  dereferenced. **No Release-build wild read.** The behaviour for an unreachable-block φ is to KEEP
  it in the set (the accept direction), but such a φ cannot be a witness (`Cand` excludes it, since
  an unreachable `In` does not dominate `BI`) and `-O1` deletes unreachable blocks; inert.
* **Is the `DominatorTree` stale in round 2?** No. `ControlDetect.cpp:773` builds
  `std::optional<DominatorTree> DT` **per `detectControlRegions` call, per function**, lazily on the
  first tainted conditional branch, and detection mutates nothing — every flatten is in
  `lowerControlRegions`. Round 2 is a fresh `detectControlRegions`, hence a fresh tree. The new line
  is a `BasicBlock`-level query, which would have been the first thing in the tree to see a freed
  block; it does not.
* **Is `MergeBB` ever `I->getParent()`?** `dominates` is reflexive (`if (A == B) return true`), so a
  φ in the merge block is kept. Such a φ cannot exist anyway — a φ using `M` in `M`'s own block does
  not dominate its incoming edges and is invalid SSA. Moot, and moot in the safe direction.
* **"It is a no-op on every NON-φ user."** True: for a non-φ `I`, SSA already requires `M` to
  dominate `I`, hence `MergeBB` to dominate `I`'s block. Verified by reading, not assumed.
* **One over-claim in the comment.** *"its users are never enqueued either, because whatever it
  carries forward is likewise slot-available"* is **false in general** — a user of a slot-available
  loop-header φ, sitting in the loop body, need not itself be slot-available. The consequence is
  fewer exclusions, i.e. more declines, so the direction is safe; but the sentence states a theorem
  that is not one. Suggest: *"its users are not enqueued either — which can only cost declines, never
  accepts, so the walk is truncated in the safe direction."*

---

## 4. What I verified independently (Rule 11 — not restated from the fix document)

| claim | my measurement | verdict |
|---|---|---|
| the fixture pair's **binary mutation** | `cq-opt` + `FileCheck` of each fixture against its own stream, three binaries: `backedge_phidesc_collider` **RED on PRE-FIX, GREEN on ORACLE and SUBJECT**; `backedge_nonphidesc_collider` **GREEN on all three** | **confirmed** — the tripwire goes red on the un-narrowed binary and the control does not |
| the increment's own accept | `phidesc_collider_accept` **RED on ORACLE, GREEN on PRE-FIX and SUBJECT**; `nonphidesc_collider` GREEN on all three | **confirmed** |
| the four new/changed fixtures are unique bodies | sha-256 over four normalisations, 1932 files | **confirmed, size 1 under all four** |
| the implementer's 7/9 | reproduced exactly, on both the 1932- and the 1930-file sets | **confirmed** |
| the round-1 reviewer's 8 | **reproduced** (§F-F2-3) | **reconciled — the record can now say all three agree** |
| the fix is cost-free on the customers | NOT re-verified — I took the implementer's four-customer md5 table on trust and spent the budget on the drift instead | **not verified by me** |

---

## 5. What I did NOT examine

* **No build, no `ctest`, no `lit`, no corpus sweep, no twin matrix, no e2e slice.** My measurements
  are 20 probe modules through three existing binaries. **1932 shipped fixtures were not run by me**
  beyond the four named above; for those I rely on the implementer's `ir-pass-lit` and round 1's
  33-/169-fixture families.
* **I did not re-verify round 1's findings** (F-F1-1's mover, the 2a structural argument, the
  169-fixture lowered-IR diff). I verified the *fix*, not the finding.
* **I did not enumerate every peel shape.** §1d's second bullet is a structural argument about taint
  timing plus two measured isolating pairs, not an exhaustive proof.
* **I did not measure the combined (Track U + Track F) binary** — it does not exist. F-F1-3 is
  unchanged and still owed at the merge gate.
* **I did not attempt the `r20` over-decline as a capability loss.** Every acyclic non-dominated-φ
  spelling I could build is masked by `declineClassicalMuxes`, so I could not produce a module that
  ACCEPTS on PRE-FIX and DECLINES on SUBJECT. That is a failed construction, not a proof that none
  exists.

---

## 6. What the MERGE GATE must run

1. **F-F1-3, unchanged and still owed:** `p9_undef_seed.ll` plus the undef spelling of each Track-F
   customer, on the COMBINED binary, answering in writing *"does a normalized zero seed make a
   φ-descendant collision reachable that was not before?"*.
2. **`review_r2_probes/r7_mbeta_base_offcone.ll` and `r12_mbeta_ifelse_rechain.ll`** — these are the
   **only** tripwires in the tree for §1c's invariant. Both must stay **DECLINE (F2)**. If either
   turns into an ACCEPT, an emitter has started RAUWing a merge φ to something that is not one of its
   incomings' descendants and F-F1-5 is re-opened. **I recommend committing one of them as a fixture**
   with an L8 header naming `SwapRouteEmit.cpp:1105` and `ArmClassify.cpp:823` — the invariant
   currently has no fixture anywhere.
3. **`review_r2_probes/r5_round2_phidesc.ll` + `r5c_round2_nonphidesc.ll`** — the round-2-reachability
   pair. `r5` ACCEPT / `r5c` DECLINE is the statement "the conjunct fires in round 2 and the
   attribution is the φ-descendancy". Cheap and it is the only thing pinning that the window exists.
4. `cq-opt-equivalence-full` (PROTOCOL, a diagnostic-surface change) and the full `ctest -j6`
   (Rule 19 moments 1 and 5 — this is a Rule-13 core predicate change).

---

## 7. Round 3 — **NOT warranted for F-F1-5; NARROWLY warranted only if F-F2-2 option (b) is taken**

F-F1-5 is closed by a proof whose premise is one grep-able line, corroborated by an isolating pair
that would have accepted had the drift been real. I found no over-accept, on any probe, on any of the
three binaries. F-F2-1 and F-F2-3 are prose. F-F2-2 option (a) is prose.

If the owner takes F-F2-2 **option (b)** — changing the predicate to test the member against the
slots — that is a Rule-13 core edit on the same function that lost four consecutive rounds in drbq
Inc 4, and it needs its own red-green and its own reviewer. That is the only reason to spend a
round 3 here.

---

## 8. Probe index — `$SES/trackF/review_r2_probes/`

| probe | what it is | ORACLE | PRE-FIX | SUBJECT |
|---|---|---|---|---|
| `run.sh` | runner; prints byte size, aborts on 0 | — | — | — |
| `MEASURED.txt` | every measurement with its attribution | — | — | — |
| `dupscan.py` | the four-normalisation duplicate-body scan (F-F2-3) | — | — | — |
| `q1_…s1.ll`, `q2_…s1.ll` | the plain-C attempt; `-O1` if-converts and the `_Bool` i8 wire declines | D / A | D / A | D / A (labelled: did not reach the question) |
| `r1_mbeta_drift.ll` | the natural drift spelling | **2c** | 2c | 2c — **the fence is 2c, not R4** |
| `r1c`, `r4`, `r4c` | first collider attempts | D F2 | D F2 | D F2 — **VACUOUS** (the pinned intermediate is itself the collider) |
| `r5_round2_phidesc.ll` | **the round-2 reachability witness** | D F2 | **A** | **A** |
| `r5c_round2_nonphidesc.ll` | its one-operand isolating control | D F2 | D F2 | D F2 |
| `r6_mbeta_base_is_MB.ll` | M-β present, base = `M_B` | D F2 | A | A — licensed by the SOURCE closure |
| `r7_mbeta_base_offcone.ll` | **the drift tripwire** — M-β present, base off-cone | D F2 | **D F2** | **D F2** |
| `r12_mbeta_ifelse_rechain.ll` | **the `T2->setArgOperand(0,T1)` tripwire** | D F2 | D F2 | D F2 |
| `r10`/`r10c`, `r11`/`r11c` | the peel-`select` manufacture attempt + off-cone controls | identical within each pair on all three binaries | | |
| `r20_acyclic_nondominated_phi.ll` | **F-F2-2 — the ACYCLIC mover** | D F2 | **D taint-escape** | **D F2** |
