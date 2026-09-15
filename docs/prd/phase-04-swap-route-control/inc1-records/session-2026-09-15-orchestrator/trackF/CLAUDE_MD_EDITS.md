# Track F′ — proposed `CLAUDE.md` edits, for the orchestrator to land

Session 2026-09-15, branch `f2-phidesc-precision`. Beads closed: bd `test_C_libtooling-hrts`, bd
`test_C_libtooling-l3i1`, bd `test_C_libtooling-dpau`.

⚠ **Why this file exists at all.** `CLAUDE.md` §4c's φ-descendant block **already carries a fired
trigger and says so in its own text** — *"THAT RETIREMENT TRIGGER HAS ALREADY FIRED, AND THE
RE-DERIVATION IS OWED, NOT DONE"* — and its closing paragraph names bd `hrts`/bd `l3i1` as *"the
φ-descendant dominance skip is broader than its stated rationale and has ACYCLIC customers"*. Both
statements are now history. Per L7-with-a-twist the same corrections are **already applied to the
source** (`ir-pass/src/ArmClassify.cpp`) and to four fixture headers in the same change; these are
the operating-manual halves the orchestrator lands.

---

## EDIT 1 — §4c, replace the whole verbatim φ-DESCENDANT block

**FIND** the block beginning `> **F2's φ-DESCENDANT exclusion (bd `om35`, owner-ruled 2026-09-14) — the ground is AVAILABILITY…`
and running through its closing `The fixture pair `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` is the tripwire.`
**AND** the paragraph immediately after it that begins `⚠ **THAT RETIREMENT TRIGGER HAS ALREADY FIRED, AND THE RE-DERIVATION IS OWED, NOT DONE**`.

**REPLACE BOTH WITH:**

> **F2's φ-DESCENDANT exclusion (bd `om35`, owner-ruled 2026-09-14; made PRECISE and
> OPCODE-AGNOSTIC 2026-09-15 by bd `hrts` / bd `l3i1` / bd `dpau`) — the ground is AVAILABILITY, and
> it is an OPERAND argument, not a position one.** F2 asks *"could the source the author wrote have
> been `cq_theta(<that register>, θ)`?"*, and that register can occupy exactly **two** slots of the
> module in front of the pass: the arm theta's arg-0, or the merge φ's PRED-edge incoming. A value
> whose operand chain reaches the region's own merge φ `M` **without passing through a value that is
> itself available at one of those slots** can be spelled at neither, in any module. Such a value is
> not a witness, and F2 stops counting it. It **removes a witness, not a decline**: any other pinned
> value that could occupy a slot is still found, on either edge, and still declines.
> ⚠ **BOTH HALVES OF THAT SENTENCE ARE LOAD-BEARING, and the second one is the 2026-09-15 change.**
> A value that merely USES `M` can perfectly well be available at a slot — a **loop-header φ taking
> an `M`-descendant on its BACK EDGE** is exactly that, and is a genuine rival. The walk therefore
> TRUNCATES at a slot-available value (it neither excludes it nor enqueues its users), and that
> truncation is **REQUIRED, not merely conservative**: if `I` is available at a slot then `f(I)` is
> spellable there too, so excluding `f(I)` would be an OVER-ACCEPT.
> ⚠ **Never compress this to "`V` sits after the join".** That sentence is about POSITION, it *is*
> the dominance conjunct that stays REFUSED IN WRITING, and it is **false** — `-O1` **sinks**, so the
> ≥11 shipped merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`,
> `offwire_sideways_min`, `step_cap_over`) also sit after the join and are genuine rivals precisely
> because their position is a consequence of the fold, not evidence about the source. The operand
> form survives sinking because **sinking moves a definition and never rewrites its operands**; and a
> pre-region value cannot *acquire* a use of `M` in place at any `-O` level, because that is invalid
> SSA. **Membership is the half that keeps this off the refused conjunct** — availability alone would
> exclude every post-join value and flip all ≥11.
> ⚠ **THE PREDICATE IS NOW THE QUESTION ITSELF, NOT A PROXY FOR IT.** Until 2026-09-15 the walk
> spelled it `isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent())` — a condition SUFFICIENT for
> "unavailable at both slots" and NOT NECESSARY, which therefore also dropped φs that were
> unavailable and merely sat off `MergeBB`'s dominance subtree (a classical branch BYPASSING the
> region and re-joining after it needs no cycle at all). That gap was an **over-decline**, filed as bd
> `hrts` / bd `l3i1`, and it is closed: `collectStatePrepPhiDescendants` now calls
> `availableAtAnF2Slot(I, PredSlot, ArmSlots, DT)` on **every** user — `DT.dominates(I, BI)` for the
> pred-edge slot and block dominance of `Region.Arm`/`ArmFalse` for the arm slot. **Measured at the
> landing (ORACLE `0e280fc6…` vs subject `8cda04ca…`): exactly ONE shipped fixture flips, ZERO of
> them say CONFIRMED MISCOMPILE, and the flip is the one the fixture's own L8 header instructed.**
> ⚠ **THE CYCLIC / ACYCLIC AXIS IS RETIRED — do not restore it** (X5, 2026-09-14c; confirmed by the
> landing). There is ONE predicate and ONE former imprecision, and cyclicity was never the
> discriminant: of the three corpus movers, `r20_acyclic_nondominated_phi.ll` has **no loop anywhere**
> and X5's `c2…{,_live}.ll` are **inside a loop** — the same cell, two CFG shapes. The back-edge φ is
> simply the sub-case where the candidate IS available at a slot, and it is unmoved in **both**
> spellings (`w1*` compare-conditioned, `w3*` bare-rail).
> ⚠ **TWO PREMISES ARE RETIRED WITH IT, and this is the part a future widening should read first.**
> (1) The argument no longer derives unavailability from `recoverRegion`'s structural gates, so X5's
> own trigger — *"the day `recoverRegion` admits a region whose `MergeBB` has a predecessor that is
> neither `Pred` nor an arm, the sufficiency step must be re-derived from scratch"* — is **gone**.
> (2) It no longer rests on *"`PHINode` is the only class LLVM 19 checks per incoming edge"* (bd
> `dpau`): every user is tested, and the no-op-on-non-φs property is now a consequence of **SSA
> transitivity** rather than of an opcode list. On reachable code the new exclusion set is a strict
> SUPERSET of the old one; the sole place it shrinks is a region whose `Pred` is unreachable, which
> is the decline direction and which `-O1` deletes anyway.
> ⚠ **THE LIVE TRIGGER, AND IT IS THE ONLY ONE LEFT HERE: the mask, not the predicate.** No top-level
> ACCEPT was recovered for the *live* spelling — a φ off `MergeBB`'s subtree carrying an
> `M`-descendant is a tainted φ under a classical condition, and `declineClassicalMuxes` claims it
> underneath. **The day that guard or its one-register lift widens (bd `xdu2`'s rail bank is the
> nearest), re-run `r20` / `c2` / `c2_live`**; if any ACCEPTS, this predicate has become load-bearing
> for a real program and is owed a fresh Rule-13 round in that light. Tripwires, as PAIRS:
> `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` (the OVER-ACCEPT
> direction — if either stops saying F2, the exclusion has been widened past availability) and
> `control_inplace_ry_{reject_,}stateprep_acyclic_nondominated_phi{,_accept}{,_control}.ll` (the
> ACCEPT direction, each with a one-operand isolating control).

---

## EDIT 2 — §4c, the `hrts`/`l3i1` sentence in the X5 paragraph

**FIND:** `(The narrowing has two further open filings of its own, bd `hrts` and bd `l3i1`: the dominance skip is broader than its stated rationale and has ACYCLIC customers, so the retirement trigger naming only `wx8g` describes the CYCLIC half.)`

**REPLACE WITH:** `(⚠ Those two filings — bd `hrts` and bd `l3i1` — are **CLOSED as of 2026-09-15**, together with bd `dpau`, by replacing the dominance proxy with the slot test. The sentence they were filed under, "the retirement trigger naming only `wx8g` describes the CYCLIC half", is superseded rather than answered: **cyclicity was never the axis**.)`

---

## EDIT 3 — §5, the Over-declines list

**FIND:** `bd `hrts` / bd `l3i1` (the φ-descendant dominance skip is broader than its stated rationale and has ACYCLIC customers);`

**DELETE IT**, and add to the *"⚠ **bd `3d8q` is CLOSED**"* note at the top of §5, or as a sibling line:

`⚠ **bd `hrts`, bd `l3i1` and bd `dpau` are CLOSED (2026-09-15)** — F2's φ-descendant walk now asks the availability question directly (`availableAtAnF2Slot`) instead of the `MergeBB`-dominance proxy. ⚠ **The filings' own caveat that "no ACCEPT is demonstrably lost" was FALSE and is now measured false**: `acc1_dead_nondominated_phi.ll` DECLINES at F2 on the pre-fix oracle and ACCEPTS at exit 0 after, STRICT 2b clean — so `hrts`' trigger was met, not merely arguable. ⚠ Read it with its limit, which is equally measured: the escape from `declineClassicalMuxes` is that the φ is **DEAD**, `clang -O1` deletes a dead φ, and the C spelling accepts on **both** binaries. **An IR-level ACCEPT is recovered; a C-level one is not demonstrated.** Never quote one sentence without the other.`

---

## EDIT 4 — §5, "Owed, and owed as a REVIEW rather than as code"

**FIND:** `the **X5 re-derivation** of `ArmClassify.cpp`'s dominance-skip trigger, whose premise the same merge falsified (§4c);`

**REPLACE WITH:** `~~the **X5 re-derivation**~~ — **DONE** (session 2026-09-14c, `trackX/X5_REDERIVATION.md`), and the predicate it re-derived has since been **replaced** (2026-09-15, EDIT 1). What is owed in its place is an **independent Rule-13 round on the slot test**: two self-review rounds are recorded (`trackF/IMPL_F2.md` §3 over-accept vectors, §3a the `-O1` lens) and a green suite clears neither. ⚠ And a **Rule-13 opinion on the F′ × P′ composition**: `preppedRailPhiRegionIdx` admits a φ as a rail leaf only for a region `classifyArms` ALREADY ACCEPTED, and the slot test makes `classifyArms` accept state preps it used to decline — so Track P′'s widened leaf grammar gains customers this track created. **A composition is not cleared by clearing its parts** (2026-09-14, F × P, and it has now cost two filings in two sessions);`

---

## EDIT 5 — the `Where Things Live` row for the control chain

**FIND** in the `ControlDetect.cpp · ArmClassify.cpp · …` row: `the 2026-09-14 **φ-DESCENDANT** set (`collectStatePrepPhiDescendants`, bd `om35`)`

**REPLACE WITH:** `the **φ-DESCENDANT** set (`collectStatePrepPhiDescendants`, bd `om35` 2026-09-14, made precise 2026-09-15 by bd `hrts`/`l3i1`/`dpau` — the membership walk truncates at any value `availableAtAnF2Slot` proves available at the arm theta's arg-0 or the merge φ's pred edge, and that truncation is a soundness requirement, not a conservatism)`

---

## NOT PROPOSED, deliberately

* **No change to the Prime Directive, Rule 13, or the refused-dominance-conjunct wording.** The
  refused conjunct is untouched by this landing and its ≥11 pin fixtures are measured unmoved; the
  operating manual should keep refusing it in exactly the words it already uses.
* **No new headline number.** Nothing in the `math.h` / coverage rows moves.
* **No claim that the over-decline family is now empty.** §5's other over-decline entries (bd `35t0`,
  bd `52og`, bd `onq1`, the `il*`×`bcar` cells, bd `1ro3`, bd `58tc`, bd `x5fp`, bd `832l`, bd `hqor`,
  the `a3` residual) are untouched by this track.
