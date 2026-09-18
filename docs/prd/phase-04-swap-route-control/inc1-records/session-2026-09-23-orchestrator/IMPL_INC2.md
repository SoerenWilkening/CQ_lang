# Increment 2 — THE BARE RAIL LEAF AT PredMux's E6 (bd `test_C_libtooling-fn1q`)

**One line:** a tainted-condition region whose branch condition is the user's own
`_Bool` REGISTER — a `cq_theta_i1` result, with no compare anywhere — may now be
claimed by `PredMuxFlatten`, so a multi-φ merge over it flattens to the
straight-line tainted-`select` program the 4.4 substrate has lowered since Phase
4.4. Closes bd `test_C_libtooling-s9xi`.

## 0. Why THIS is increment 2, and not the one the brief names

`MEASUREMENT.md` is the evidence and the owner ruled on it (2026-09-23). The
2026-09-22 brief's `F1` — *"`MergePhiPeel` P9, no in-loop peel"* — is falsified: a
bypass build changes `owner.c` not at all, and the peel cannot fix the shape in a
loop or out of one, because both of the owner's merge φ are ARM-DEFINED and
`phiPeelable`'s own contract is that the peel must **never** hoist one out. The
stage that owns a multi-φ tainted merge is `PredMuxFlatten`, which refuses the
owner's program at **three** gates: E2-cycle, E6-condtree, E4-gep. The owner chose
the PredMux route with a proof-gated E4.

This increment takes **E6, and only its rail-LEAF half**.

## 1. The change, in FOUR places, in ONE file

| site | change |
|---|---|
| `isSupportedCondTree` | a LEAF case: `if (!Strict && isCondRailLeaf(V)) return true;` |
| `buildNegation` | an arm BEFORE the unchecked `cast<BinaryOperator>`: `¬rail = xor rail, true` |
| the flatten's single `CreateSelect` site | `select(¬c, T, F) == select(c, F, T)` — take the xor's operand and SWAP the arms, **only when that operand is a rail leaf** |
| `sweepDead` | ⚠ **skip `isCondRailLeaf`/`isCondRailPhiShape` — the USER'S register is never this stage's to erase** |

⚠ **THE FOURTH ROW WAS NOT IN THE DESIGN. It is Rule-13 round 1's P1**, and the
rail-operand conjunct in the third row is its P2-1. Read §5 before anything else in
this file: the implementer shipped a VANISHING USER GATE and a silent out-of-scope
accept, and the independent round found both. Neither was visible to `opt -verify`,
to `free_pairing_check.py`, to 2126 lit fixtures, to a 474-entry `ctest`, or to a
full-corpus A/B.

### Why the leaf is `isCondRailLeaf` and not "an opaque tainted i1"

Rule 14: `isCondRailLeaf` (`SelectClassify.h`) is THE spelling of *"the `_Bool`
register IS the condition"*, shipped since bd `3qlq.4`, and `collectCondTree`
already carries such a leaf into the 4.4 substrate as a `RailLeaves` entry that
mints **no flag** — the register is read only as a CONTROL. It is CALLED here, not
re-derived.

Two properties come with it free and both are load-bearing:

* **It is always TAINTED** (Rule 3 — `cq_theta` is the sole taint source), so the
  leaf cannot smuggle a classical value into a tainted cond tree.
* **It is already an `i1`**, so the edge predicate needs no flag mint.

⚠ **The obvious spelling is the wrong one and there is a fixture for it.**
`isSupportedCondTree` has NO `TaintSet` in scope, so "admit an opaque tainted `i1`"
would have had to be structural — *an `i1` that is not a cmp/phi/and/or/xor/select*
— which admits a **CLASSICAL** `i1` at any INTERIOR position of the tree. The
backstop there is `SelectClassify`'s GATE-2 per-leaf taint check, i.e. a
claim-then-decline where the oracle declined pre-claim. Asking the question you
MEAN rather than a shape that resembles it is the bd `11qv` round-4 (P4) lesson;
`control_predmux_reject_nonrail_i1_cond.ll` pins it.

### ⚠ Why it is NOT a one-line widening — the consumer audit, paid here

`buildNegation` ends in `auto *BO = cast<BinaryOperator>(V);`, **unchecked**: an
assert in `+Asserts` and a bad cast in the RELEASE build every gate here runs. A
rail is a `CallInst`. A rail-conditioned region reaches that line the moment `-O1`
puts the gate arm on the FALSE successor, which is half the time (Rule 9).

**MEASURED BY MUTATION, not argued:** a build with edit (2) removed **ABORTS** on
`control_predmux_accept_rail_leaf_negation.ll` (full LLVM crash dump) where the
oracle declined cleanly at exit 1. That is the bd `11qv` round-4 (P4) failure
verbatim — exit 134 where the oracle declined — and it is why the standing lesson
is *when you widen a GRAMMAR, enumerate what CONSUMES it*.

### Why the third edit exists, and why it is an arm SWAP and not a parser

¬ of an OPAQUE `i1` has no leaf compare to invert, so `buildNegation` spells it
`xor %rail, true`. `collectCondTree` then refuses that node because its child is an
`i1` CONSTANT. Without the fold the module is CLAIMED, FLATTENED and only THEN
declined at `SelectClassify`, where the oracle declined at `E6-condtree` before
touching anything — same verdict, worse owner, and exactly what this file's own bd
`3c6m.67` self-operand lesson says not to ship.

The swap removes the node rather than teaching a second consumer to parse it (Rule
14): `SelectMergeEmit` already spells ¬ for a bare rail with its `cqrt_x` BRACKET
on the CNOT-copied **ancilla** — never on the user's register — so the swapped
select is the substrate's own negation spelling. **MEASURED BY MUTATION:** a build
with edit (3) removed DECLINES the negation fixture while the positive polarity is
unaffected.

⚠ **SCOPE CLAIM, stated so it can be attacked:** `xor X, true` reaches that select
site from NOTHING but the new rail arm — `buildNegation` inverts a compare leaf
into an inverted compare, De Morgans an and/or, consumes the grammar's own
`xor X, 1` NOT as ¬¬x = x, and folds a constant. If a second producer ever appears,
RE-DERIVE that sentence rather than re-quoting it.

## 2. What the emitted stream is

The shipped idiom, once per merge φ: a fresh `|0⟩` ancilla, a CNOT copy of the rail
onto it, a fresh `|0⟩` target, two X-bracketed `cqrt_copy_<W>_controlled`, the CNOT
restored, `cqrt_free` at a proven `|0⟩` (`x ⊕ x = 0` on every branch). The rail
itself is never `cqrt_x`-bracketed and never freed — the user measures it (Rule 6).

The two polarities differ by **exactly** the exchange of the two controlled copies,
which is the same unitary with the controls relabelled; the two accept fixtures
assert that against each other in prose and by their CHECKs.

## 3. What this increment does NOT do

* It does **not** admit the RAIL PHI (`isCondRailPhiShape` — the `%cq.bank1` a
  preceding controlled state-prep leaves behind, which is what the owner's
  `bool b0[n]` becomes). That predicate is WEAK BY DESIGN and its consumers prove
  it through `preppedRailPhiRegionIdx` / `AllowRailPhi`; none of that is asked at
  E6. Pinned as a decline by `control_predmux_reject_rail_phi_cond.ll` with its
  retirement trigger. **That is the next increment.**
* It does **not** touch E2 (in-loop) or E4 (the classical const-table load), so the
  owner's `example/grover/grover_oracle_uncompute.c` still does not compile.
* It does **not** relax `Strict`, so a rail leaf under an xor keeps declining
  (`control_predmux_reject_rail_leaf_under_xor.ll`).
* It does **not** fold the BoolAlg path's `and(¬rail, X)`. An `i1`-typed merge φ in
  a rail-conditioned region would take that path and my fold does not cover it —
  **named as a suspect for the Rule-13 round rather than argued empty.**

## 4. ⚠ THE ONE ARGUMENT TO READ SCEPTICALLY — protocol item 5

With a TRAILING NON-DIAGONAL gate on the condition's own register
(`b = cq_theta(b, -0.5)` after the region), the FLAT four-variable form **declines
on the oracle and ACCEPTS on the subject**. That is an accept-direction move in
exactly the presence protocol item 5 / G-13 polices, and it must not be waved past.

**The control that decides it:** the already-shipped **two-variable** sibling of
that exact program **ACCEPTS ON THE ORACLE**, silently, with the same gate KINDS
and the **same `cqrt_ry_i1` count**; the four-variable subject's gate multiset is
the two-variable oracle's plus exactly two more merges (+2 cnot, +2 copy, +2 x, +1
free each) and no new gate kind. So the class — merge-then-rotate-the-condition,
with the leftover which-path entanglement that Rule 8 says dephases the rotation —
is **pre-existing and shipped**, and this increment extends it from two variables
to four.

⚠ **"Pre-existing" is true of the defect and FALSE of its population.** This
increment adds customers to the bd `s82e` / Q-R1-1 class. It is recorded here, not
hidden in a gate table.

Rolled: declines identically on both binaries. Unrolled (three sequential regions):
declines on both, but the STRING MOVES (`nested control flow` → `control flow`)
because PredMux now claims and flattens all three and the decline lands downstream
at `SelectClassify` on a CHAINED select — a mutate-then-decline. Safe (both loud,
non-zero, nothing consumed), and filed rather than argued away.

---

## 5. ⚠ RULE-13 ROUND 1: **BLOCKED**, AND THE P1 IS THE SAME CLASS INCREMENT 1 SHIPPED

### P1-1 — the user's `cq_theta_i1` was ERASED, and the project had already ruled it must not be

`PredMuxFlatten` tracks values it replaces in `MaybeDead`; `sweepDead` erases anything
`use_empty()`. Until this increment **that could never reach a CQ front-end intrinsic,
because the E6 grammar admitted no `CallInst` at all** — the containment was
STRUCTURAL. The rail leaf makes a `@cq_theta_i1` call a condition-tree node, and THREE
sites then put it into the sweep: `run()`'s `track(BI->getCondition())` (both
polarities), `buildNegation`'s `track(V)` (false polarity), `canonicalizePred`'s
`trackCondCone` (true polarity).

**Measured on the shipped-at-the-time binary:** `opt` exit **0**, **0 bytes of
stderr**, **no `cqrt_alloc_i1` and no `cqrt_ry_i1` in the stream** — the user's
rotation deleted outright (Rule 5). The ORACLE declined loudly. `opt -verify` clean.
`free_pairing_check.py` `0 violation(s), 0 unproven`, because it is structurally blind
to a rail that no longer exists. **No gate in this tree could have seen it.**

⚠ **`RegionFlatten.cpp:107` ALREADY CARRIED THE CONJUNCT AND THE REASON**, in writing,
since bd `3qlq.4`: *"a RAIL-LEAF condition is the USER'S `cq_theta_i1` — never this
stage's to erase, WHATEVER ITS USE COUNT … defence in depth against erasing a user's
rotation on a shape nobody measured."* It was not carried across. **A ruling written in
one stage does not propagate to its sibling by being true.**

**FIXED at the SINGLE ERASER, not at the three trackers**, deliberately: a per-site
fence is only as complete as its most-forgotten site, and a fourth tracker added later
would re-open this with no diagnostic anywhere (the `markBranchPhaseGate` lesson,
inverted). `isCondRailPhiShape` is excluded too, ahead of its own increment, for the
reason `RegionFlatten`'s comment gives.

⚠ **THE COMMENT THAT SAID IT WAS SAFE WAS THE DEFECT (L7).** `buildNegation`'s arm
carried *"the rail is the USER'S register, it is live at their `cq_measure`, so
tracking it is inert. Do not 'tidy' this by skipping the track."* That is an assumption
about the **program**, not a property of the code — a user need not measure `b`. And it
named the wrong site: `run()`:3023 reaches the rail at the polarity `buildNegation`
never sees. Rewritten at the source.

⚠ **HONEST BOUND:** the reviewer reproduced this from HAND-WRITTEN IR and could not
produce a `-O1` C reproducer (two attempts failed for opposite reasons). Read it as
IR-level, **reachability from C neither shown nor disproved** — which is exactly why it
mattered anyway: hand-written `.ll` is this tree's primary fixture surface.

### P2-1 — "narrow by construction" was measured FALSE

The fold's SCOPE paragraph enumerated `buildNegation`'s four behaviours and concluded
`xor X, true` could reach the select site from nothing else. It omitted `literal()` →
`canonicalizePred`, which has **no xor arm** and returns such a condition unchanged.
A module with **no rail anywhere** went ORACLE exit 1 → SUBJECT exit 0 — semantically
correct, and an unfenced accept widening outside the increment's scope.

⚠ **The corpus was structurally blind to it, and the reviewer measured the blindness
rather than assuming it:** of 2130 fixtures exactly ONE carries an `xor i1 …, true`
feeding a `br`, and it appears only on `CHECK:` lines (a `LoopLowering`-minted
`%cq.brk.guard`, downstream of PredMux), so **no input module in the tree can reach the
fold that way**. L10, in its exact form.

FIXED by requiring the xor's operand to be a rail leaf. The SCOPE paragraph is
rewritten to say it is a FILTER and why.

### P2-2 / P2-2a / P3-1

The **BoolAlg** surface was real, sound and unfixtured — now pinned by a fixture PAIR
whose gate-stream identity against an ORACLE-accepted twin is asserted **mechanically**
(`grep | diff` on a RUN line), re-verified independently at 52 gates each. The fold's
*"everywhere"* claim is narrowed to *"at this site"* with the three surviving
claim-then-decline shapes named. Every `CHECK-COUNT` is closed by a whole-file `-NOT`,
after the round measured an injected **ninth** controlled copy being **MISSED by all
four prefixes**; re-validated, the same injection is now CAUGHT.

### And one the ORCHESTRATOR found against its own fixture

`control_predmux_reject_rail_phi_cond.ll`'s retirement trigger claimed it would become
an ACCEPT when the rail-φ increment lands. **Measured false**: its prep sits under a
CLASSICAL condition, so it keeps declining for a second, independent reason — the
downstream proves a rail φ through `preppedRailPhiRegionIdx`, which needs a CLAIMED
state-prep region. Corrected at the source with the measurement, and
`probes/inc2/railphi_tainted_prep.ll` is the shape increment 3 actually has to take.

## 6. The standing lesson, paid twice in two increments

**WHEN YOU REPLACE A STRUCTURAL CONTAINMENT WITH A PREDICATE, ENUMERATE WHAT THE
STRUCTURE WAS HOLDING.** Increment 1: four conjuncts replaced *"any non-chain arm op
declines"*, none named CQ's own calls, and a `speculatable`-marked `cq_phi` was hoisted
and DELETED. Increment 2: the E6 grammar admitted no `CallInst`, that is what kept CQ's
intrinsics out of `sweepDead`, the rail leaf made one, and the user's Ry was DELETED.
**Same class, same consequence, one increment apart — and both were found by the
independent round, not by the implementer and not by any gate in the tree.**
