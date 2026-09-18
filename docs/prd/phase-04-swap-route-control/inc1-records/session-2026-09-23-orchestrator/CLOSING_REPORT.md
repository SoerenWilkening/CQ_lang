# CLOSING REPORT — session 2026-09-23 (bd `test_C_libtooling-fn1q`)

**One line:** the bead's fence map was re-derived from measurement for the SECOND
time in two sessions and is different again; the owner chose the route; increment 2
of the new plan landed, and its independent round found a **vanishing user gate**
that no gate in this tree could have seen.

## 1. The session opened by falsifying its own brief — again

The 2026-09-22 session corrected three false claims in bd `fn1q` and wrote a
four-fence map in their place. **That map's fence 1 is also wrong.** Measured on a
bypass build: removing `MergePhiPeel` P9 changes `owner.c` **not at all**, and the
peel structurally cannot fix the shape in a loop or out of one — both of the owner's
merge φ are ARM-DEFINED, and `phiPeelable`'s own contract is that the peel must
*never* hoist one out. The loop-free twin declines identically, which is what settles
it.

⚠ **THE STANDING LESSON, AND IT IS NEW: A CORRECTED BISECTION IS STILL A BISECTION
AND INHERITS THE SAME BURDEN.** The session that files a correction is not exempt
from the rule it is enforcing. The 2026-09-22 map was read off the code; it was never
measured by removing the clause.

**The real owner is `PredMuxFlatten`** — named as such, in writing, one screen above
the clause the brief proposed to retire — refusing at THREE gates: **E2-cycle**,
**E6-condtree**, **E4-gep**. **Route proved, not proposed:** with all three bypassed,
`probes/owner.c` compiles verbatim — exit 0, stderr empty, **106 lines and still
ROLLED**, stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`, 88 trace lines,
the shipped controlled-copy idiom twice per trip, no new symbol.

**Owner ruling 2026-09-23:** take the PredMux route; admit a classical const-table
load at E4 **only with a proof** of in-bounds-ness, so an unprovable index keeps
today's decline and increment 1's `flat_qc_load` ruling stands unchanged.

## 2. What shipped — increment 2 of 4: the BARE RAIL LEAF at E6

Four edits in ONE file (`PredMuxFlatten.cpp`): the `isCondRailLeaf` leaf at E6; the
`buildNegation` arm for `¬rail`; the `select(¬c,T,F) == select(c,F,T)` arm-swap fold,
fenced to a rail operand; and the `sweepDead` exclusion. Closes the filed over-decline
bd `test_C_libtooling-s9xi`.

**10 lit fixtures** (4 accept incl. a mechanically-diffed twin pair, 5 decline, 1 the
P1 regression) and **1 e2e slice + golden**.

## 3. ⚠ The two rounds, and what they cost

**Round 1: BLOCKED.** 1 P1, 2 P2, 3 P3.

The P1 is **a vanishing user gate**: the rail leaf makes a `@cq_theta_i1` call a
condition-tree node, three `track()` sites put it into `MaybeDead`, and `sweepDead`
**erased it** — `opt` exit 0, **0 bytes of stderr**, no `cqrt_alloc_i1` and no
`cqrt_ry_i1` in the stream, where the oracle declined loudly. `opt -verify` clean;
`free_pairing_check.py` `0 violation(s)` because it is structurally blind to a rail
that no longer exists.

⚠ **`RegionFlatten.cpp:107` ALREADY CARRIED THE CONJUNCT AND THE RULING** — bd
`3qlq.4`, *"never this stage's to erase, WHATEVER ITS USE COUNT"* — and nothing had
carried it across. **A ruling written in one stage does not propagate to its sibling
by being true.**

Round 1 also measured the fold's *"narrow by construction"* scope claim FALSE
(`canonicalizePred` is a second producer, so a module with **no rail anywhere**
flipped decline→accept), that the BoolAlg surface shipped unfixtured, and that every
`CHECK-COUNT` was "at least N" — an injected ninth controlled copy was **missed by all
four prefixes**.

**Round 2 on the fixes: CLEAR-WITH-ITEMS, 0 P1**, 2 P2, 4 P3 — and it found the same
P1 class ONE ERASER OVER (`RecursivelyDeleteTriviallyDeadInstructions`), which FIX A
does not reach. Capped at P2 and **filed as bd `test_C_libtooling-cfmv`** by two
measurements: it needs a `memory(none)` attribute `CQ.h` cannot emit, and it is
PRE-EXISTING (the oracle deletes the rail too for a compare-conditioned region).
⚠ *"Pre-existing" is true of the defect and FALSE of its population.* It also caught
two comments in the same change contradicting each other, and a `RAIL` prefix that
claimed *"read only as a control"* while missing an injected rotation on the user's
register.

## 4. The lesson this session paid for twice in two increments

**WHEN YOU REPLACE A STRUCTURAL CONTAINMENT WITH A PREDICATE, ENUMERATE WHAT THE
STRUCTURE WAS HOLDING.** Increment 1: four conjuncts replaced *"any non-chain arm op
declines"*, none named CQ's own calls, and a `speculatable`-marked `cq_phi` was
hoisted and DELETED. Increment 2: E6's grammar admitted **no `CallInst` at all** —
that is what kept CQ's intrinsics out of `sweepDead` — the rail leaf made one, and the
user's Ry was DELETED. **Same class, same consequence, one increment apart, and both
found by the independent round rather than by the implementer, the corpus, or any gate
in the tree.**

## 5. What is NOT established

Rule 2, in the words it has to be said in. This is exit codes, stage-2b rail
identities, emitted traces, gate-stream twin identity and analytic reasoning. **There
is no simulator.** The independent opinion is the two rounds', and **their own "WHAT I
DID NOT DO" sections are the boundary of this clearance** — round 2 ran no `ctest`, no
full lit, built no mutant binary, and could not settle the switch-scrutinee question
in either direction.

⚠ **Protocol item 5 moved in the ACCEPT direction** and the argument for it is the
control, not the absence of a flag: the already-shipped TWO-variable sibling accepts
the identical trailing-gate program on the ORACLE, silently, with the same gate kinds
and the same `cqrt_ry_i1` count. The class is pre-existing; **this increment adds
customers to bd `s82e` / Q-R1-1**, and `entangle.py` flags it IDENTICALLY on both
binaries — say that, never "no findings".

## 6. Still open — the owner's program does not compile yet

* **increment 3** — the RAIL φ (`isCondRailPhiShape`, what the owner's `bool b0[n]`
  becomes). ⚠ Measured: admitting it at E6 is NOT sufficient on its own — the
  downstream proves a rail φ through `preppedRailPhiRegionIdx`, so a TAINTED-prep φ
  accepts while a CLASSICAL-prep φ does not. `probes/inc2/railphi_tainted_prep.ll` is
  the shape it has to take.
* **increment 4** — E2, the acyclic region strictly inside a loop body.
* **increment 5** — E4, the proof-gated classical const-table load.
* **bd `cfmv`** (new, P1) — the eraser hole one stage over.

New from this session: bd `test_C_libtooling-cfmv`.
