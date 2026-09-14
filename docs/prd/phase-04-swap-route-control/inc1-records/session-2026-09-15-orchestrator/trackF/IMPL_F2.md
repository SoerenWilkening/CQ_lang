# Track F′ — the F2 φ-descendant predicate made PRECISE and OPCODE-AGNOSTIC

Session 2026-09-15. Worktree `/Users/sorenwilkening/Desktop/CQ_F`, branch `f2-phidesc-precision`,
based on `main` `74eabd2c`. Beads: **bd `test_C_libtooling-hrts`**, **bd `test_C_libtooling-l3i1`**,
**bd `test_C_libtooling-dpau`** — all three closed by ONE line, because they were always one line.

> **The headline, and it is not the one the brief expected.** The two over-decline beads were filed
> with an explicit caveat — repeated by the round-2 review, by the X5 re-derivation and by the
> fixture headers — that **no ACCEPT was demonstrably lost**, only a diagnostic string moved, because
> every acyclic non-dominated-φ spelling anyone had built was masked by `declineClassicalMuxes`.
> That caveat is now **FALSE, and measured false**: `probes/acc1_dead_nondominated_phi.ll` DECLINES
> on the ORACLE at F2 and **ACCEPTS at exit 0** on the subject, with STRICT stage 2b clean and a
> well-formed stream. The `hrts` trigger — *"the day an acyclic non-dominated-phi module ACCEPTS on
> the un-narrowed binary and DECLINES here, the capability cost has become observable as a lost
> accept and option (b) is owed"* — **is met**, in the words it was written in. ⚠ And the honest half
> in the same breath: that module is hand-written IR whose escape from the mask is that the φ is
> **DEAD**, and `clang -O1` deletes a dead φ — the C spelling was built and measured and accepts on
> both binaries. **An IR-level ACCEPT is recovered; a C-level one is not yet demonstrated.** Both
> sentences are load-bearing; neither may be quoted without the other.

---

## 0. What the binary does now

`ir-pass/src/ArmClassify.cpp`, the F2 fence's φ-descendant walk. **Three code changes, ~10 lines.**

**(a) A new file-local predicate `availableAtAnF2Slot(I, PredSlot, ArmSlots, DT)`** that asks the
question the availability ground actually licenses:

```cpp
bool availableAtAnF2Slot(const Instruction *I, const Instruction *PredSlot,
                         ArrayRef<const BasicBlock *> ArmSlots,
                         const DominatorTree &DT) {
  if (PredSlot && DT.dominates(I, PredSlot))            // the merge φ's PRED-edge slot
    return true;
  for (const BasicBlock *ArmBB : ArmSlots)              // the arm theta's arg-0 slot
    if (ArmBB && DT.dominates(I->getParent(), ArmBB))
      return true;
  return false;
}
```

**(b) `collectStatePrepPhiDescendants` takes the two slots and tests EVERY user against them.**

```
-  if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent()))
+  if (availableAtAnF2Slot(I, PredSlot, ArmSlots, DT))
     continue;
```

**(c) The call site passes them**, from fields `recoverRegion` already committed:

```cpp
const BasicBlock *ArmSlots[] = {Region.Arm, Region.ArmFalse};
collectStatePrepPhiDescendants(Region.Merge, F, BI, ArmSlots, *DT, PhiDesc);
```

`BI` is `Pred`'s conditional terminator, established non-null by F2's own existing guard. Nothing
else in F2 moved: the TEST line is character-identical, `CondWire` is still built from
`railWireClosure` at the call site and applied at the TEST and never at the LVI ANCHOR, the LVI
dominance filter and the `isIntegerTy()` filter are untouched, `Truncated` is untouched, and
`PhiDesc` is still consulted as ONE independent conjunct and still prunes neither `Cand` nor the
users walk.

Everything else in the diff is **prose** — the function header, the in-walk comment, the TEST-site
comment, four fixture headers — and per **L7-with-a-twist** it is in the same change, not in a
record: *a record correction that is not applied to the source is not a correction*, measured three
times on one sentence in bd `z9t1`.

---

## 1. Why one line closed three beads

`hrts` and `l3i1` are the SAME imprecision seen from two sides — X5 established that and this track
agrees. `dpau` looked orthogonal and is not: the old line's `isa<PHINode> &&` conjunct was a **no-op
on valid IR only because the dominance half was a `MergeBB` test SSA already guaranteed for non-φs**.
Change the dominance half and the no-op argument has to be re-derived anyway. Taking `dpau`
separately would have meant deriving it twice, against two different predicates, and bd `dpau`'s own
text says so: *"If `hrts`'s option (b) is taken first, ask this question again of whatever predicate
replaces the line — the trigger travels with it."* It travelled; it is answered here.

**The cyclic/acyclic axis stays retired.** X5 retired it and this track did not resurrect it. Stated
in the new axis, which is availability:

| | the φ is AVAILABLE at a slot | the φ is NOT available at a slot |
|---|---|---|
| its block IS dominated by `MergeBB` | **impossible** (dominance is antisymmetric — see §3) | excluded by BOTH predicates |
| its block is NOT dominated by `MergeBB` | kept as a rival by BOTH — *the back-edge loop-header φ, the genuine hazard* | **the defect: dropped by the old proxy, excluded now** |

One predicate, one invariant, one imprecision — and the imprecision is exactly one cell.

**Which half does each fix reach?** All three beads reach the **bottom-right cell**, which is neither
the cyclic nor the acyclic half: it is BOTH of them, because cyclicity was never the discriminant.
Measured: of the three corpus movers, `r20_acyclic_nondominated_phi.ll` has **no loop anywhere** and
`c2_inloop_acyclic_bypass_nondominated_phi{,_live}.ll` are **inside a loop** — the same cell, two
CFG shapes. The top-right cell (the back-edge φ) is unmoved in **both** spellings, `w1*` (compare
condition) and `w3*` (bare rail), which is the cell `wx8g` made reachable.

---

## 2. The correctness argument, stated so a reviewer can attack it

**F2's question.** *"Could the source the author wrote have been `cq_theta(<that register>, θ)`?"*
The register can occupy exactly two slots of the module in front of the pass: the arm theta's
**arg-0**, or the merge φ's **PRED-edge incoming**. A value that cannot be SPELLED at either slot in
any module is not evidence about the source, so F2 stops counting it. **It removes a witness, not a
decline** — any other pinned value that could occupy a slot is still found, on either edge.

**The invariant, and it is now the conclusion itself.** Every member of `PhiDesc` is **unavailable at
both slots**, because every user is tested for exactly that before insertion. The predecessor
invariant — *"every member lies in a block dominated by `MergeBB`"* — was SUFFICIENT for that and
NOT NECESSARY, and the gap was the defect.

**What the walk computes is not "the users of `M`".** It is **the values whose operand chain reaches
`M` without passing through a slot-available value**, and the second clause is as load-bearing as the
first:

* **The truncation is REQUIRED, not merely conservative — and the shipped comment undersold it.**
  When the walk meets a slot-available value `I` it neither inserts it nor enqueues its users. The
  in-tree comment justified that as *"can only cost DECLINES and never accepts, so the truncation is
  in the safe direction"*. True, and not the reason. If `I` is available at a slot then a user
  `f(I)` is **SPELLABLE at that slot** — `I` is a register available there — so `f(I)` is a genuine
  rival, and enqueuing it would be an **OVER-ACCEPT**. (The round-1 draft had justified the
  truncation with *"whatever it carries forward is likewise slot-available"*, which round 2 correctly
  called not-a-theorem and replaced with the direction argument. The direction argument is true and
  is still not the reason. This is. The source comment now says so.)
* **Membership is what keeps this off the REFUSED DOMINANCE CONJUNCT.** Availability alone would
  exclude every value defined after the join — that IS the refused conjunct, and it flips the ≥11
  shipped merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`,
  `offwire_sideways_min`, `step_cap_over`; measured 2026-09-14 at `collider-uses-phi = no` on 25/25
  of the shipped pin fixtures plus all 4 `Truncated` ones). Those never enter this walk, because
  their operands do not reach `M`. **The conjunction is the predicate; neither half alone is.** I
  checked which object I was touching at every edit: this tests a *member* against the *slots* and
  decides only whether that member is a rival — it never tests a *collider* against the *arm*.

**Two premises RETIRED by the change**, and this is why it is worth a Rule-13 round rather than a
comment edit:

1. **`recoverRegion`'s structural gates.** The old sufficiency step ran: `soleMergePhi` has exactly
   two incomings and each arm is single-pred(`Pred`) ⟹ `Pred` strictly dominates `MergeBB` ⟹ by
   antisymmetry `MergeBB` dominates neither `Pred` nor the arm ⟹ a `MergeBB`-dominated block is
   unavailable at both slots. X5 turned that into a live trigger: *"the day `recoverRegion` admits a
   region whose `MergeBB` has a predecessor that is neither `Pred` nor an arm … the sufficiency step
   must be re-derived from scratch."* **That trigger is now retired**: the slot test asks the slots
   directly, so `recoverRegion` can be widened however anyone likes and the question stays right.
2. **"`PHINode` is the only class LLVM 19 checks per incoming edge."** Every user is now tested, so a
   future opcode with per-edge value operands is asked the same question as everything else instead
   of short-circuiting past an `isa<PHINode>`. bd `dpau`'s own trigger — *"the day
   `DominatorTree::dominates(const Value *, const Use &)` names any class besides `PHINode` …"* — is
   retired with it: there is no class name left in the predicate to be wrong about.

**The residual premise that DOES remain** is the one in the two bullets: that arg-0 of the arm theta
and the merge φ's pred-edge incoming are **the only two slots**. That is a fact about F2's question,
not about LLVM, and it is stated at the top of the header where a widening has to argue with it.

---

## 3. Round 1 (self-review) — attacking the change for OVER-ACCEPTS

Each item is what was attacked, then what was found. Budgeted up front per Rule 13; this is round 1
of two, and an **independent** round is still owed (§7).

* **A1 — is the pred-slot test the right question?** A φ incoming must dominate its incoming EDGE.
  LLVM computes that as `dominates(Def, Use)` with `UseBB = PN->getIncomingBlock(U)` = `Pred`, i.e.
  `dominates(DefBB, Pred)` when the blocks differ and a position test when they do not.
  `DT.dominates(I, BI)` gives the same answer in both cases (a φ sits at the block top, so it
  precedes `Pred`'s terminator; every non-φ in `Pred` also precedes the terminator). ⚠ **Spelling it
  as `DT.dominates(I->getParent(), Pred)` would be WRONG** — a value defined in `Pred` is available
  on that edge and block dominance answers `false` for it. Written into the helper's header.
* **A2 — the arm slot when the region is an IF/ELSE.** For an if/else the merge φ has no `Pred`
  incoming; the straight-through incoming comes from `ArmFalse`, so a value available at
  `ArmFalse`'s terminator would be a rival the pred-slot clause alone misses. Such a value must be
  defined in `ArmFalse` (anything above it dominates `BI` too), and the arm clause catches it —
  `DT.dominates(ArmFalseBB, ArmFalseBB)` is `true`, so it is skipped and stays a rival. ⚠ **Then I
  checked whether the case is reachable at all and it is NOT, for a reason I had not seen:** F1
  computes `PredIdx = MergePhi->getBasicBlockIndex(Region.Pred)` (`ArmClassify.cpp:4719-4727`) and
  declines when it is negative — and an if/else merge φ takes its incomings from the **two arms**,
  never from `Pred`. **So an if/else state prep is refused by F1 before F2 runs, and `Region.ArmFalse`
  is ALWAYS NULL at this call site.** That makes the arm clause unreachable for a third independent
  reason, on top of the two X5 measured. I am recording the correction rather than the first draft
  because the first draft would have read as "the arm clause is there for the if/else case", which is
  false — and because the fact is a FACT ABOUT F1, not a licence: the day F1 admits an if/else prep,
  the pred-edge slot becomes the false arm's terminator and this clause is what covers it. Written
  into the source in those words.
* **A3 — could the arm theta be somewhere other than the arm block?** If `-O1` hoisted it into
  `Pred` it would be unconditional and not an arm. And if it somehow were in `Pred` before `BI`, a
  value available at `BI` but not at the theta would be over-approximated as available → skipped →
  kept as a rival → **decline direction**. Safe.
* **A4 — unreachable code.** `DT.dominates(Value*, Instruction*)` answers "any unreachable USE is
  dominated" (`true`) and "an unreachable DEF dominates nothing" (`false`). So a region whose `Pred`
  is unreachable now collapses the set to `{M}` where the old proxy kept the non-φ users — **fewer
  exclusions, i.e. strictly MORE declines**, and `-O1` deletes unreachable blocks before the pass
  sees them. A user in an unreachable block while the region is reachable reads as NOT available and
  is KEPT in the set, exactly as before. Neither direction dereferences a null tree node
  (`GenericDomTree.h:430-442`), so there is no Release wild read — the same care the next function's
  `LazyValueInfo` precondition comment demands, asked of this API too.
* **A5 — is the new set ever SMALLER on reachable code?** No, and the proof is short enough to
  check. For a φ: old inserted ⟹ `dom(MergeBB, IBB)`; new skips ⟹ available at a slot; available
  ⟹ `IBB` dominates `Pred` or is an arm block ⟹ with `dom(MergeBB, IBB)` and transitivity,
  `dom(MergeBB, Pred)`, contradicting `Pred` strictly dominating `MergeBB`. For a non-φ: old always
  inserted; new skips ⟹ available ⟹ (by SSA, since its member operand dominates it) that member is
  available, contradicting the member's own membership. **On reachable code the new set is a strict
  SUPERSET**, so the effect at the TEST is monotone: strictly more exclusions, strictly fewer
  witnesses, F2 declines no more often and sometimes less. Written into the TEST-site comment.
* **A6 — `dpau` behaviour-neutrality, proved rather than enumerated.** A non-φ user `J` of member `V`
  has `V` dominating `J` by SSA; if `J` were available at a slot then `V` would be too, contradicting
  `V`'s membership. So the test never fires for a non-φ on valid IR. That is SSA transitivity, not
  an opcode list (L5), and it is confirmed by measurement: no corpus mover is attributable to
  dropping the conjunct.
* **A7 — does the walk now reach the CONDITION's own wire and exclude it?** It cannot: every
  `CondWire` member dominates the branch, hence is slot-available, hence is skipped. The slot test
  protects the condition wire for free, which the `MergeBB` proxy did only incidentally.
* **A8 — L1, the round-2 window.** The set is recomputed in both detection rounds, and *"it is
  recomputed"* is the HAZARD and not the argument (the header says so and this track did not weaken
  it). My change adds reads of `Region.Arm`, `Region.ArmFalse` and `Pred->getTerminator()` — all
  fields `recoverRegion` commits in the SAME detection sweep that then calls `classifyArms`, and F2
  already dereferences `Region.Pred` at this point. **No new lifetime or staleness premise.** The
  emitter-RAUW argument that makes the round-2 set sound is untouched and lives in the header.
* **A9 — `Truncated`.** Unchanged. A larger exclusion set removes early returns, so it can only
  convert a TEST decline into a `Truncated` decline, never the reverse; both are declines. The four
  fixtures that decline through the `|| Truncated` disjunct are in the corpus sweep and unmoved.
* **A10 — lifetime of the `ArmSlots` array.** A local `const BasicBlock *[2]` whose `ArrayRef` is
  consumed by the call on the next line. No storage escapes.

## 3a. Round 2 (self-review) — attacking from the `-O1` lens that beat F2 four times

L5: *a syntactic answer to a semantic question loses*. So the question is what `clang -O1` can do to
make a slot-available value look unavailable, or the reverse.

* **Sinking** moves a definition and never rewrites its operands, which is why the ≥11 merge-block
  colliders are genuine rivals and why the operand form survives sinking. It cannot move an
  `M`-descendant above the join (invalid SSA) and it cannot make a non-descendant into one.
* **Hoisting / LICM** can only move a value to a position where its operands are available, so a
  hoisted value is not an `M`-descendant.
* **Jump threading / block duplication** can copy a user into a slot-dominating block — but the copy's
  operands must be available there, so the copy is not an `M`-descendant either.
* **SimplifyCFG** merging `%J` into `%mB` would make `%J` dominated by `MergeBB`, i.e. the cell both
  predicates already agree on.
* **The one that needed thinking.** Could `-O1` produce a φ that is an `M`-descendant, is unavailable
  at both slots here, yet whose SOURCE preimage WAS available at a slot? For the φ's image to use
  `M`, the source variable's value must depend on the join — and the pre-join version of that
  variable is a DIFFERENT SSA value, which is its own F2 candidate and is still found. So nothing is
  lost: this is the "removes a witness, not a decline" property, preserved.

**What is skipped, said plainly (L5).** No enumeration of `-O1` passes was performed and none is
claimed. The reliance is on one structural fact — **an operand chain is not rewritten by code
motion, and a use of `M` cannot be acquired in place at any `-O` level because that is invalid SSA**
— plus the two-slot statement of F2's question. If either stops holding, the argument goes, not a
row of a table.

---

## 4. Measured: the flip count, against the whole fixture set

⚠ **The metric that decided the owner's Q1 last session**: the φ-descendant rule was chosen over
R-2′ because R-2′ flips **25** shipped decline fixtures (13 of which say CONFIRMED MISCOMPILE in
their own headers) while it flipped **zero**. The same metric, applied to this change:

| | count | rows |
|---|---|---|
| shipped `ir-pass/test/*.ll` fixtures that FLIP | **1** | `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` — F2 → `cq taint escape: tainted value muxed by a classical-condition phi` |
| of those, headers saying CONFIRMED MISCOMPILE | **0** | — |
| of those, flipped in the ACCEPT direction | **1** | and it is the fixture whose own L8 header **instructed** the flip, character-for-character |
| session-probe modules that move | see §4a | all in the ACCEPT direction |
| shipped fixtures that flip in the OVER-ACCEPT direction (a decline becoming an accept it should not have) | **0** | the back-edge pair and the ≥11 merge-block colliders are unmoved |

**Two targeted family sweeps, run separately because they are the populations most at risk and
because they do not depend on the full-corpus run finishing** (rows committed under `probes/`):

| family | files | movers |
|---|---|---|
| the ≥11 merge-block colliders + the four `\|\| Truncated` fixtures (`range_forward_*`, `sideways_*`, `merge_edge_sideways`, `offwire_sideways_min`, `step_cap_over`, `unfoldable_curated_call`, `unevaluable_pinned_operand`, `control_peel_reject_fp_stateprep`) | **17** | **0 — all identical** |
| every `*stateprep*` / `*state_prep*` fixture in `ir-pass/test` | **148** | **2**, both this track's own files, both ACCEPT-direction. The other 146 identical, including all **73 ACCEPTs** and all **7 if/else** state-prep fixtures |

That second row is the measurement behind two claims elsewhere in this record: the refused dominance
conjunct is genuinely untouched (§2), and the ARM clause costs nothing (§7) — it can only ever ADD a
skip, which would surface as a DECLINE-direction mover, and there are none.

### 4b. The corpus sweep — COMPLETE, 3933/3933

Every `ir-pass/test/*.ll` (**2042/2042**) plus every session `*/probes/*.ll` (**1891**), both binaries
on the same input file, decline rows compared by **FULL STDERR** rather than by a tag regex —
PROTOCOL S3 records that the shared recipe's regex renders the whole `cq_measure_<sfx>` family as an
empty `D:`, so a decline→decline STRING change inside it would be invisible. Accept rows are compared
by md5 of the lowered IR with `ModuleID`/`source_filename` stripped, **within a row only** (md5s are
not comparable across sweeps). Rows: `probes/corpus_8cda04ca.txt`.

**7 MOVERS IN 3933 ROWS, AND EVERY ONE IS A NAMED, EXPECTED MODULE. ZERO UNATTRIBUTED.** They are
listed in §4a: the two committed copies of `r20_acyclic_nondominated_phi.ll`, X5's
`c2_inloop_acyclic_bypass_nondominated_phi{,_live}.ll`, this track's `acc1_dead_nondominated_phi.ll`,
and the two `ir-pass/test` files this track moved deliberately.

**One row reads `EMPTY`, and that is the instrument working.**
`session-2026-09-14c-xdu2-w1/review_r1a/probes/h0_empty.ll` is 0 bytes, and **a 0-byte module ACCEPTS
through the pass's passthrough early-out** (bd memory `empty-module-accepts-vacuity-trap`, where six
probes once scored ACCEPT on nothing). The sweep scores it `EMPTY` rather than `A:` so it cannot be
read as an accept by either binary.

⚠ **It took three attempts and the first two are the lesson.** The first spelling was serial and
buffered every row to write at the end: **25 minutes under cross-track load with ZERO observable
progress and nothing recoverable if stopped.** The second added parallelism but still could not
resume. The third writes rows incrementally, resumes from what is already measured, and orders
`ir-pass/test` FIRST so the number the landing is judged on lands before the large stage-1/stage-2
probe dumps. **A long measurement that cannot be observed is one you cannot make a decision about** —
and under a host load average that ran **183 → 410** on 6 physical cores, the decision of whether to
abandon the gate had to be made twice. (It was very nearly recorded as an ABSENCE per the
orchestrator's rule; it finished instead, and the earlier partial states are not reported as if they
were the final one.)

**So the shipped fixtures are covered THREE times over, by instruments answering different questions:**

1. **`ctest -R ir-pass-lit`: 1/1 Passed, 156.37 s, all 2042 fixtures** — every fixture still matches
   its own `CHECK`s, so the only shipped expectations that moved are the four this track moved
   deliberately. That is the flip count from the pass/fail side.
2. **The two targeted family sweeps (148 + 17 files), comparing the DIAGNOSTIC STRING** — which can
   see a decline→decline move that `lit` cannot: 2 movers and 0 movers.
3. **The corpus sweep's fixture half, 2042/2042** — (2) extended from the two families most at risk
   to every shipped fixture: **2 movers, both deliberate**.

None subsumes the others. ⚠ **What no instrument here can do is clear the change** — Rule 2: a green
gate is necessary and never sufficient, and §7 records the independent round that is owed.

⚠ **Three fixtures were ADDED and one MODIFIED during the earlier sweep attempts.** A sweep's file
list is fixed at start; the final run includes all four. Recorded rather than smoothed.

⚠ **The prose edits are measurably behaviour-neutral.** The tree was rebuilt after them (the `.o`
recompiled at 00:07:56 against a source last written at 00:00:02, binary relinked at 00:07:57) and
the `cq-opt` sha256 came back **BIT-IDENTICAL** at `8cda04ca…` — so every hash citation in the
fixture headers and in `GATES.md` is a fact about the SHIPPED source, not an assumption.

## 5. The ACCEPT construction — attempted, and this time it succeeded

X5 §4.2 and the round-2 review both recorded this as a **failed construction** and were careful to
say a failed construction is not a proof of absence. This track re-attempted it and found the escape.

**The mask, restated.** A φ off `MergeBB`'s dominance subtree that carries an `M`-descendant is a
TAINTED φ under a CLASSICAL condition, which `declineClassicalMuxes` claims. That guard runs
**post-detection**, which is exactly why these modules read as F2 on the ORACLE and as a taint escape
on the subject: F2 fires first on the old binary, and the mask is underneath it.

**The escape is LIVENESS.** `declineClassicalMuxes` claims a *live* select/φ over tainted data. Make
the φ **DEAD** and nothing claims it — F2 was the only thing between the module and exit 0.
`probes/acc1_dead_nondominated_phi.ll` is `r20` with the φ's consumer removed:

```
ORACLE  0e280fc6…  exit=1  cq controlled lowering: state prep seed is proven equal to the condition register
SUBJECT 8cda04ca…  exit=0
```

**The accept was then attacked rather than celebrated (Rule 2).** The emitted stream:

```
%h     = cqrt_alloc_i32(0);  cqrt_ry_i32(%h, 0.5)                  ; the condition register
%h_cmp = cq_template_icmp_eq_i32_hl(%h, 7)                         ; the eq flag
%h1    = cqrt_alloc_i32(0);  cqrt_ry_i32_controlled(%h_cmp, %h1, 0.5)  ; the CONTROLLED state prep
         cq_template_icmp_eq_i32_hl_unc(%h_cmp, %h, 7);  cqrt_free(%h_cmp)
         … the dead chain, lowered forward and fully _unc'd, 3 frees …
%m     = cqrt_measure_i32(%h1)
```

`%h` is read only as a compare source and never `cqrt_x`-bracketed, never freed. `%h_cmp` is one
mint, one strip, one free — a proven-|0⟩ free. `%h1` is the prepped register and is FROZEN, because
`Ry(θ)|0⟩ ≠ |0⟩`. STRICT stage 2b: `2 rail mint(s) of which 2 left allocated, 4 cqrt_free site(s):
4 verified, 0 violation(s), 0 unproven`. The **isolating control** `acc1c` — the same module with
ONE operand changed so the φ no longer carries an `M`-descendant — DECLINES at F2 on **both**
binaries, which attributes the accept to φ-descendant membership and not to deadness, block layout
or guard order.

**⚠ THREE THINGS THIS ACCEPT IS NOT, each measured rather than hedged.**

1. **It is not a C-level capability.** The C spelling was written, compiled at `-O1 -g`, and `-O1`
   DCE'd the dead chain: **exit 0 on both binaries**, so the shape does not survive the frontend.
   The pass's input language is IR and an IR-level accept is a real statement about the pass — but
   *"CQ now compiles a program it used to refuse"* is **not** shown, and must not be written.
2. **It does not clear the leak underneath it.** The dead chain's `trunc` result is a
   TEMPLATE-minted rail left allocated, and `free_pairing_check.py` is **structurally blind** to
   those (no `cqrt_alloc` to count). The `0 violation(s)` is not clearance for that class. It is the
   ordinary disposition of a dead tainted chain, identical in shape to any other accepted one, and
   it is bd `test_C_libtooling-s82e`'s family — orthogonal to this landing and named so nobody reads
   this file's green as a statement about it.
3. **It does not make the live case accept.** `probes/acc2` is the same module with the φ LIVE: it
   still declines, at `declineClassicalMuxes`, on the subject. The mask is exactly liveness.

**So the structural argument stands and is stated as an argument (L5).** Attempts made, each blocked
for a named reason: a **one-register liftable** φ cannot be an `M`-descendant (the lift requires all
incomings to resolve to one common base through the in-place gate wire, and an `M`-descendant's base
is `M`, which does not dominate the bypass edge); routing the value through `cq_measure` to break
taint makes it a non-candidate (`Cand` requires `Taint.Tainted`) and leaves nothing for `f2Exact` to
fold; making the entry branch TAINTED so the φ is a region merge instead of a classical mux gives
`MergeBB` predecessors that are neither `Pred` nor an arm, so `recoverRegion` refuses it as nested.
**That is three named blocks, not a theorem**, and the mask itself — `declineClassicalMuxes` and its
one-register lift — is under active widening pressure (bd `test_C_libtooling-xdu2`'s rail bank). The
live trigger is written into the source: *the day that mask widens, re-run `r20`/`c2`/`c2_live`.*

---

## 6. Fixtures (Rule 12), and what each pins

| file | verdict | role |
|---|---|---|
| `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` | DECLINE, **new string** | the shipped tripwire, CONVERTED exactly as its own L8 header instructed. Module byte-unchanged; header rewritten |
| `…_acyclic_nondominated_phi_control.ll` | DECLINE at F2, **unmoved on both binaries** | NEW. The one-operand isolating control that stops the converted file being fixture-hygiene defect (c) — *a decline fixture that goes green because its SUBJECT no longer exists pins nothing* |
| `control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll` | **ACCEPT** | NEW. The recovered accept, with the full gate census |
| `…_acyclic_nondominated_phi_accept_control.ll` | DECLINE at F2, unmoved | NEW. The accept's isolating control — an accept fixture goes green if the module merely lowers, including if F2 lost the ability to fire at all |
| `control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll` | DECLINE at F2, **HELD** | header rewritten: it now pins the OVER-ACCEPT direction of the new line, and says so |
| `control_inplace_ry_reject_stateprep_backedge_nonphidesc_collider.ll` | DECLINE at F2, **HELD** | header rewritten, same reason |

**Every fixture I moved was checked for hygiene defect (c)** — a decline fixture that goes green
because its subject vanished. The converted tripwire is the only one at risk and it is closed by a
sibling control that MEASURABLY does not move, on both binaries, rather than by re-reading prefixes.

**Injection matrix over the new accept: 14 mutations, MISSED 0, N/A 1** (`n/a-shape` — the
construct is genuinely absent from this module, which the harness reports distinctly from a HOLE).
⚠ **The first run scored 8 MISSED of 14**, and the cause was fixture-hygiene defect (a) reproduced
rather than read about: the negatives lived after a positional `CHECK` in one prefix, and **a
positive CHECK windows every negative after it**, so eight injected gates placed before the last
positive match were invisible. The repair is one prefix per counted symbol plus a pure whole-file
negative prefix — forced, not tidy, because the gates INTERLEAVE in the stream and FileCheck matches
strictly forward, so one prefix cannot count one symbol to exhaustion and then start another. The
harness's own empty-argv refusal was re-checked and still exits non-zero (bd `test_C_libtooling-…`
2026-09-14 hole).

⚠ **The shared vacuity checker was NOT cited, and the reason is a finding.**
`session-2026-09-13-orchestrator/trackM/probes/impl/vacuity.py` (PROTOCOL S3's named tool) is
(a) hardcoded to `/Users/sorenwilkening/Desktop/CQ_mphi`, a worktree that no longer exists — it dies
with `FileNotFoundError` rather than reporting anything — and (b) matches only
`(NOX|NOFREE)-NOT: … (i32 %handle)`, a shape none of this track's fixtures uses, so even repaired it
would print `checked 0`, which PROTOCOL S3 itself calls a **HOLE, not a pass** (bd
`test_C_libtooling-jdec`). **It is therefore not cited as a gate here.** The injection matrix is the
stronger instrument for the same property and it was run: M4–M8 inject exactly the symbols the
negative prefix names (`cqrt_x`, `cqrt_cnot`, `cqrt_cswap`, `cqrt_rz`, a surviving `cq_theta`) and
all five are `caught`, which is what "these negatives have teeth" means operationally.

⚠ **Two instrument findings of my own, both self-inflicted and both worth carrying** (L10: the only
instrument worth citing is one that has been made to fail on purpose — these failed by accident,
which is the same evidence): (i) a bare `CHECK-NOT: @cqrt_x` **matches the lowered module's own
`declare void @cqrt_x(i32)`** and fails on a module that is in fact clean — bd
`test_C_libtooling-qta2`'s family, met here for real; (ii) a **section heading** in my own comments
that named a prefix before a colon was parsed by FileCheck as a POSITIVE directive for the prose
that followed it — and then the sentence explaining that trap, which quoted the heading verbatim,
did it a second time. **A fixture's comments are input to FileCheck, not decoration.**

---

## 7. What is open, and what a reviewer should attack

* **An independent Rule-13 round is OWED.** Two self-review rounds are recorded above (§3 over-accept
  vectors; §3a the `-O1` lens). A green suite does not clear a core change, and neither does the
  author's own adversarial reading. The measured hit rate says the next round finds something —
  drbq Inc 4 lost **four consecutive rounds** on this exact function.
* **Suggested lenses for that round**, in the order I would attack my own change: (1) the ARM-slot
  clause's block-dominance over-approximation — it is conservative in the decline direction *as I
  argued it*, so find the shape where it is not; (2) the if/else pred-slot case of §3-A2, which I
  covered by reasoning and by ZERO measured movers, not by a fixture (none exists — see below);
  (3) whether any shipped `Truncated` fixture's step count moved enough to change its verdict;
  (4) the composition with Track P′ (below).
* **A GAP, stated rather than implied: the ARM clause has no dedicated red-green, and cannot have
  one.** It is unreachable for three independent reasons (§3-A2), so any fixture for it would pin
  "nothing happens" — the vacuous kind. What IS pinned is that it costs nothing: the corpus sweep's
  decline-direction mover count is the measurement, because the clause can only ever ADD a skip,
  which shows up as a DECLINE-direction mover. There are **7 if/else state-prep fixtures** in
  `ir-pass/test` and they are in the sweep. ⚠ Read the clause's unreachability as three facts about
  *other* code (F1's `PredIdx`, `recoverRegion`'s single-pred arm, SSA), each of which is its own
  retirement trigger — not as a property of this predicate.
* **The three blocked ACCEPT constructions of §5 are an argument, not a theorem.**

## 8. ⚠ CROSS-TRACK — the composition with Track P′, which nobody has reviewed

Track P′ shares `ArmClassify.cpp` with this track (the prep merge-φ leaf-grammar cluster: bd `hn29`,
bd `leyd`, bd `52og`). **I did not touch `preppedRailPhiRegionIdx`, `classifyArms`' committed verdict
structure, or any rail-ladder rung.** But the composition is real and it is in the ACCEPT direction
on both sides, which is the shape that cost this project two filings in two sessions:

> `preppedRailPhiRegionIdx` admits a φ as a rail leaf **iff its region is already in the plan as a
> `BranchRegion` with `ClassArm`/`ClassArmFalse == InPlaceRotation` and a non-empty `Shadow`** — i.e.
> iff `classifyArms` ACCEPTED that state prep. **This change makes `classifyArms` accept state preps
> it used to decline at F2.** So it enlarges the population of φs that Track P′'s widened leaf
> grammar can then consume. Track P′ widens *what a leaf may be*; this track widens *which regions
> produce a leaf at all*. **A program that neither branch accepts alone may accept with both.**

That is the F × P composition of 2026-09-14 in a new pair of tracks, and last session's lesson is
exact: **a composition is not cleared by clearing its parts.** The merge-and-gate agent should
attribute movers by string across BOTH tracks' binaries, and the Rule-13 round should be given the
composed binary, not either branch alone.

## 9. Beads

| bd | disposition |
|---|---|
| `test_C_libtooling-hrts` | **CLOSED by implementation.** Option (b) taken. ⚠ Its trigger *"the day an acyclic non-dominated-phi module ACCEPTS … option (b) is owed"* is **MET** — `acc1`, §5 — so the note that no accept was demonstrably lost must be superseded, not just extended |
| `test_C_libtooling-l3i1` | **CLOSED by the same line.** Option (b), not option (a) |
| `test_C_libtooling-dpau` | **CLOSED in the same change**, and it had to be: the `isa<PHINode>` no-op argument was a property of the predicate it guarded |
| `test_C_libtooling-s82e` | untouched; named in §5 so this landing's green is not read as covering it |
| `test_C_libtooling-xdu2` | named as the live trigger for §5's mask |
