# FIX — Track F, round-1 review dispositions (bd `om35`)

Worktree `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`.
Subject of the review: tip `baad186d`, `cq-opt` `147cb3d6…`. **That binary no longer exists on disk**
(it is snapshotted at `build/prefix_147cb3d6/` for the before/after runs and is gitignored).

```
ORACLE   (frozen, /Users/sorenwilkening/Desktop/CQ_lang/build, 59ac5b7 — READ-ONLY, never rebuilt)
  cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
  libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
PRE-FIX  (the reviewed binary, snapshotted before the fix build)
  cq-opt        147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4
  libCQPass.so  70d474d2971fd0192412c213f037e85ed14a57854518084a94e1b05ea46bff16
POST-FIX (this document's subject)
  cq-opt        96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1
  libCQPass.so  9537a0ce0c56548e3cc27f273a15a84995ce21dd7754d608d160e064fd9ad68e
```

⚠ **EVERY GATE LINE RECORDED AGAINST `147cb3d6…` IS VOID FOR THIS BINARY.** `GATES.md` now carries
two tables and each line is labelled `ran:` (re-run on `96fdd3a9…`) or `cited:` (a fact about
`147cb3d6…` or about the ORACLE, and about nothing else).

---

## F-F1-1 — MUST-FIX — **FIXED, and the ground is now enforced rather than assumed**

**The finding, restated so the disposition can be checked against it.** `collectStatePrepPhiDescendants`
walked `V->users()` with no dominance filter. A φ is the one opcode whose operand need only dominate its
incoming EDGE, so a LOOP-HEADER φ taking an `M`-descendant on its BACK EDGE was in `PhiDesc` while
DOMINATING both of F2's slots — i.e. it was exactly the available collider the availability bullets say
cannot exist. The two header bullets were theorems for an ACYCLIC user chain only.

**The fix — `ir-pass/src/ArmClassify.cpp`, the reviewer's two lines, spelled with the reasons they need.**
The helper takes `const DominatorTree &DT` (the call site passes `*DT`, non-null by the guard immediately
above it, which declines rather than narrowing the question silently), captures `MergeBB =
MergePhi->getParent()`, and inside the users loop:

```cpp
      if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent()))
        continue;
```

Three things are said in the source comment and must stay there:

* **It is a NARROWING of the EXCLUSION set, NOT the refused dominance conjunct.** Opposite object and
  opposite direction: the refused conjunct tests a **collider** against the **arm** and turns declines
  into ACCEPTS (it flips the ≥11 shipped merge-block colliders); this tests a candidate **member**
  against **`M` itself** and can only ever REMOVE an exclusion, i.e. only ever ADD declines. The comment
  says so explicitly so nobody "simplifies" the two together.
* **It is a no-op on every non-φ user, and is spelled for φs only to say why.** For a non-φ `I`, SSA
  already requires `M`'s definition to dominate `I`, hence `MergeBB` to dominate `I`'s block.
* **The resulting INVARIANT is what the availability bullets actually need**: every member of the set
  lies in a block dominated by `MergeBB`, which — since `Pred` strictly dominates `MergeBB`, and the arm
  is not dominated by it — is unavailable at the arm slot and at the pred edge. Before this line that
  held only for an acyclic chain, as an unstated premise; now it holds by construction.

**The monotonicity that makes `ir-pass-lit` a complete fixture-corpus gate for this edit.** Removing
members from `PhiDesc` makes the TEST `… && !PhiDesc.count(V) && f2Exact(V,S) == Seed` succeed at least
as often. Take the first pop at which the two binaries differ: the narrowed one `return true`s
(DECLINE); the un-narrowed one continues and ends in DECLINE(test), DECLINE(truncated) or ACCEPT. So the
only transitions are **ACCEPT → DECLINE** and **DECLINE(truncated) → DECLINE(test)**; a DECLINE can
never become an ACCEPT. Every accept fixture is pinned green by lit and every decline fixture pins its
string character-for-character, so a green `ir-pass-lit` is exactly the statement "no fixture moved".

**Measured, three binaries, `fix_r1_probes/run3.sh` (byte size printed before every measurement; it
aborts on 0 — IMPL §7's erratum):**

| probe | ORACLE | PRE-FIX `147cb3d6` | POST-FIX `96fdd3a9` |
|---|---|---|---|
| `p8_backedge_phidesc.ll` (1466 B) | **F2** | `control flow inside a loop body` — **THE MOVER** | **F2** — restored |
| `p8c_backedge_nonphidesc.ll` (1498 B), the isolating control | F2 | F2 | F2 — **unmoved, as required** |
| `p8b_nocollider.ll` (1319 B) | F2 | loop fence | loop fence — **deliberately not restored, see below** |
| `p9_undef_seed.ll` (1047 B) | F1 | F1 | F1 — Track U's, not touched |

**`p8b` is not restored, and that is correct, not a residual.** With `%v` deleted the only candidate is
`%carry` itself — a **non-φ** user of `%m`, which SSA already puts in a block dominated by `%m`'s and
which therefore genuinely cannot be spelled at either slot. Excluding it is exactly what the
availability ground licenses. `p8b` is the **attribution control**: it shows the F2 that fires on `p8`
post-fix is on `%v` and on nothing else.

**The fixture pair, committed.**
`ir-pass/test/control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll` (= `p8`) and
`…_backedge_nonphidesc_collider.ll` (= `p8c`). Both are DECLINE fixtures with `not … | %filecheck` and
the F2 string mirrored character-for-character. **Validated by MUTATION of the BINARY, which is the
strongest form available for a decline fixture** (Rule 12(b): a `DS_Error` decline writes 0 bytes to
stdout, so the IR-text `CHECK-NOT`s are vacuous by construction and are labelled as such in both
headers):

```
FileCheck <fixture> against each binary's own stderr:
  PRE-FIX  147cb3d6 : phidesc fixture RED   · nonphidesc fixture GREEN
  POST-FIX 96fdd3a9 : phidesc fixture GREEN · nonphidesc fixture GREEN
```

The tripwire goes red on the un-narrowed binary and the control does not — which is the pair's whole
contract, and it is why the pair cannot be "consolidated" into one file (both headers say so).

**`wx8g` is named in the retirement triggers, in three places**: the helper's own comment, and the L8
header of each of the two fixtures. The wording is the one the finding requires — that **bd
`test_C_libtooling-wx8g` is the ONLY reason the back-edge shape is unreachable rather than merely
narrowed**, that in-loop regions DO reach `classifyArms` so the loop is not a blanket fence, and that
the day `wx8g` lands the narrowing must be re-derived against the shapes it admits **without assuming
the φ case is the only cyclic one**.

**Cost: zero, measured on all four customers** (below) — lowered IR byte-identical, md5 for md5.

---

## F-F1-2 — documentation (L7) — **FIXED in the source header, and the corrected paragraph is §CG below**

The compressed form (*"the φ is defined at the join, so a value using it is available at neither"*) was
the refused dominance argument wearing the availability label, and sinking defeats it. The source header
now states the **OPERAND** step, carries the explicit prohibition on the position compression, and
carries the reviewer's §2a structural argument (no pass can rewrite an existing value's definition to
take an operand that does not dominate it — that is invalid SSA — so a pre-region value cannot
*acquire* a use of `M` in place; sinking moves a definition and never rewrites its operands, which is
why the operand form survives sinking and the position form does not).

The paragraph that must travel into `CLAUDE.md` is **verbatim in §CG at the end of this file.**

One further correction made while in there: the "IT REMOVES A WITNESS" paragraph cited
`probes/c/owner.S1.ll`, which IMPL §7 records as a **0-byte and therefore vacuous** probe. It now cites
`trackF/probes/cust/owner_file_solecoll.ll` and says why.

---

## F-F1-3 — Track U composition — **NOT FIXED HERE, BY INSTRUCTION. Handed over as a named probe.**

`p9_undef_seed.ll` is copied into `trackF/fix_r1_probes/p9_undef_seed.ll` and re-measured on all three
binaries (F1 on every one of them: `state prep seed does not match the merge incoming`). It is the merge
gate's, and the question it must answer on the COMBINED binary is the reviewer's: *"does a normalized
zero seed make a φ-descendant collision reachable that was not before?"* — with the answer already known
to be **yes by construction**, so what the gate is deciding is whether any such program is a genuine
rival. Note that the committed slice uses the **initialised** spelling deliberately (IMPL §5), so the
golden cannot witness the composition either.

---

## F-F1-4 — the `Truncated` claim — **FIXED, restated precisely**

The source now says: it can **only ever convert a TEST decline into a `Truncated` decline, never the
reverse**, because excluding a value removes an early return and so can only make the walk run MORE
steps, never fewer. Both are declines (`Pinned = f2SeedPinnedByLiveRegister(...) || Truncated` — one
call site, one string, so the transition is invisible at the string level, which is exactly why the
claim has to be precise rather than reassuring). The four fixtures are now described as **measured**
unmoved rather than unmoved "by construction", and `p8` is cited in the comment as the live example of
the walk continuing past a value the ORACLE stopped on.

---

## F-F1-5 — **NOT CLOSED. Written up as the round-2 assignment.** See §R2 below.

The review is right that IMPL §3's "recomputed, therefore correct by construction" proves
**recomputation** and not **stability**, and that the drift direction is the ACCEPT direction. I am not
closing it by assertion. §R2 names the specific drift I cannot rule out, the two RAUW sites with their
**polarity**, and the shape of the cure if it turns out to be reachable.

---

## F-F1-6 — duplicate-body count — **RECONCILED: the axis is BLANK LINES, and the reviewer's 8 does not reproduce**

Measured on this tree (1932 fixtures) and again with the two new fixtures excluded (1930), which gives
the same answer because neither new fixture is in any group:

| normalisation | groups |
|---|---|
| **N1** — comment lines stripped, **blank lines KEPT** | **7** |
| **N2** — comment lines stripped, **blank lines DROPPED** | **9** |
| N3 — N2 + per-line whitespace stripped | 9 |
| N5 — N1 + per-line whitespace stripped | 7 |

So **whitespace is not the axis; blank lines are.** The two groups that exist only under N2 are
`control_angle_select_phase_constants` / `control_angle_select_rz_cond_register` and
`control_classical_call_arm_accept` / `lowering_measure_round2_sixfive_handle`.

* **IMPL §8's 9 is N2** — so IMPL's own description ("non-comment lines") was imprecise; it was
  non-comment **and non-blank**. The number is right, the label was not. Corrected in IMPL §8.
* **The reviewer's 8 reproduces under NEITHER** N1, N2, N3 nor N5. I could not construct a normalisation
  that yields 8, so I am recording it as **unreconciled by one group** rather than inventing one; the two
  blank-line-only groups above are named so the reviewer can say which one their scan lost.
* **The load-bearing part agrees under all four normalisations: both new fixtures are in groups of size
  1**, and so are the two fixtures the increment added earlier. Re-measured on this tree.
* No L8 contradictory-verdict hazard in either blank-only group: all four files are positive-accept RUN
  lines, not one module under two names with opposite verdicts.

---

## §CG — THE CORRECTED GROUND PARAGRAPH (verbatim; this is what goes into `CLAUDE.md`)

> **F2's φ-DESCENDANT exclusion (bd `om35`, owner-ruled 2026-09-14) — the ground is AVAILABILITY, and it
> is an OPERAND argument, not a position one.** F2 asks *"could the source the author wrote have been
> `cq_theta(<that register>, θ)`?"*, and that register can occupy exactly **two** slots of the module in
> front of the pass: the arm theta's arg-0, or the merge φ's PRED-edge incoming. The region's own merge φ
> `M` is defined **at the join**, so `M` is available at **neither** slot — and therefore **no value whose
> operand chain reaches `M` can be SPELLED at either slot, in any module**. Such a value is not a register
> the author could have named in the definition of `M` itself, so it is not a witness, and F2 stops
> counting it. It **removes a witness, not a decline**: any other pinned value that could occupy a slot is
> still found, on either edge, and still declines.
> ⚠ **Never compress this to "`V` sits after the join".** That sentence is about POSITION, it *is* the
> dominance conjunct that stays REFUSED IN WRITING, and it is **false** — `-O1` **sinks**, so the ≥11
> shipped merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`,
> `offwire_sideways_min`, `step_cap_over`) also sit after the join and are genuine rivals precisely
> because their position is a consequence of the fold, not evidence about the source. The operand form
> survives sinking because **sinking moves a definition and never rewrites its operands**; and a
> pre-region value cannot *acquire* a use of `M` in place at any `-O` level, because that is invalid SSA.
> ⚠ **The argument is a theorem only for an ACYCLIC user chain, and since 2026-09-14 that precondition is
> ENFORCED, not assumed.** A φ is the one opcode whose operand need only dominate its incoming EDGE, so a
> **loop-header φ taking an `M`-descendant on its BACK EDGE** both uses `M` and dominates both slots —
> the available collider the bullets say cannot exist (measured as a mover: ORACLE fires F2, the
> un-narrowed subject does not). `collectStatePrepPhiDescendants` therefore **skips a φ user that `M`'s
> block does not dominate**. That is a **NARROWING of the EXCLUSION set** — opposite object and opposite
> direction from the refused conjunct, which tests a *collider* against the *arm* and turns declines into
> accepts, where this tests a *member* against *`M` itself* and can only add declines. The invariant it
> buys is that every member lies in a block dominated by `M`'s block.
> ⚠ **RETIREMENT TRIGGER: bd `wx8g`, by name.** Every in-loop state prep is stopped before F2 today
> (`control flow inside a loop body`), and that open over-decline is the **only** reason the back-edge
> shape is unreachable rather than merely narrowed — in-loop regions **do** reach `classifyArms`, so the
> loop is not a blanket fence. The day `wx8g` lands, re-derive the narrowing against the shapes it admits,
> and do not assume the φ case is the only cyclic one. The fixture pair
> `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` is the tripwire.

---

## §R2 — ROUND-2 ASSIGNMENT, carrying F-F1-5 forward unclosed

**The question.** Round 1's emission **RAUWs**: `emitInPlaceRotationRegion`'s **M-β** rewrites a merge φ
to the arm's **theta CALL**, and `SelectMergeEmit` rewrites a merge to the **`%out` handle**. `PhiDesc`
is rebuilt in round 2 over the **post-RAUW** graph. So:

> **Can round 1's RAUW manufacture a φ-descendancy that the SOURCE did not have — making a round-2
> region's `PhiDesc` contain a value that, in the module `clang` produced, was a writable register at one
> of that region's slots and was pinned to its seed?**

If yes, the narrowed predicate excludes a **legitimate** witness and the region ACCEPTS where it should
decline. This is the L1 **PREDICATE** species exactly (a predicate asked over a graph a later round
falsifies), and that species has hit this project three times.

**The polarity of the two RAUW sites, which is the first thing to check and is not symmetric:**

* **`SelectMergeEmit`'s RAUW to the `%out` handle SHRINKS the set.** `%out` is a fresh `cqrt_alloc`
  result with no operands, so replacing a φ-derived value by it **removes** descendancy — the DECLINE
  direction, safe, and not the drift.
* **M-β's RAUW to the arm's theta CALL can GROW it.** The theta call's arg-0 is the rotated register /
  the chained base. If that base is derived from a **different** region `B`'s merge φ, then after the
  RAUW every former user of `A`'s φ transitively reaches `M_B`. When `B` is classified in round 2, those
  users are in `B`'s `PhiDesc` and are no longer counted as colliders.

**Why the availability ground does not answer it.** In the **round-2 module** those values genuinely sit
in blocks dominated by `M_B`'s, so the ground is TRUE of that module — and says nothing about the
**source**, which is the only thing F2's question is about. The ground is not the defence here; this is
the same hole R-1 closed for `MergePhiPeel`'s clones (a value the pass manufactured), except that what
the pass manufactures here is an **edge in the user graph** rather than a value.

**The construction to attempt (or to prove unreachable).** A region `B` classified **only in round 2** —
i.e. whose condition becomes tainted through `repropagateControlMerges`' re-seeding from a 6.5/4.5
`%out` rail — whose merge φ **dominates** a round-1-emitted in-place-rotation region `A`'s arm, where
`A`'s arm theta base is `M_B`-derived, and where some value pinned to `B`'s seed on one of `B`'s edges is
a user of `A`'s φ. On such a module the un-narrowed binary declines and the narrowed one accepts, with no
source rival having been excluded — a genuine over-accept. Note the interaction to watch while building
it: `RotBase ∈ CondRails ⇒ R4 declines` is a **different** fence and may or may not stand in the way;
establish which fence actually fires before concluding the shape is unreachable (the 2c/R4 asymmetry is
measured at 16-of-27 versus 0-of-27, so "R4 would have caught it" is not a safe assumption).

**What would close it, if it is reachable.** The **R-1 pattern**, which `CLAUDE.md` L1 prescribes:
RECORD at the site that knows the answer (the RAUW site — which values were substituted for what), and
ASK at the site that needs it (the TEST), so a descendancy the pass manufactured is not counted as one.
**Do not close it by "the set is recomputed"** — recomputation is what makes the drift possible, not what
prevents it. And do not close it by re-asserting the availability ground, for the reason above.

**Also still open for round 2, carried from review §6:** the fix itself is a Rule-13 core edit and has
had no independent review; and F-F1-3's composition cannot be measured until the merged binary exists.
