# bd `fn1q` increment 3 — Rule-13 ROUND 2 (independent agent, on the ROUND-1 FIXES)

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 2 P2, 8 P3.** No wrong accept. Null controls run
first: the reviewer's mutant baseline rebuilt BIT-IDENTICAL to the subject, and a
subject-vs-subject sweep over all 2140 fixtures gave four zeros.

⚠ **ROUND 2 EARNED ITS BUDGET IN THE WAY THE BRIEF PREDICTED IT WOULD: ROUND 1'S OWN
FIXES INTRODUCED TWO NEW MEASURABLY-FALSE MECHANISM CLAIMS INTO SHIPPED SOURCE, AND
THREE OF THE FOUR NEW FIXTURE HEADERS STATED DISCRIMINATORS A SINGLE-CLAUSE MUTANT
FALSIFIES.** A round that only re-reads the fixes would have found none of it.

| # | sev | finding | disposition |
|---|---|---|---|
| R2-1 | P2 | **the WHOLE `regionStrictlyInsideLoopBody` predicate is redundant over the corpus**: deleting the call (keeping only `topoOrderRegion`) gives `A->D=0 D->A=0 decline-string=0 stream=0` over 2140. Deleting clause (a) alone: the same four zeros. Only GATE NAMES move. The comment's mechanism claims for (a)/(c)/(d) were unmeasured | **FIXED at the source.** The predicate is KEPT (L3: it fails closed, and E3/Kahn are not written to answer this question) but its comment now states the measurement, per-clause, and says plainly that the (a)-(e) paragraphs are the RATIONALE and not what holds the hazard shut today. Retirement trigger: the day E3 or Kahn is relaxed. |
| R2-2 | P2 | **round 1's F-1 fix is itself wrong**: it named **E4** as what fences the in-loop owners. Measured over accepting `*loop*` fixtures: **100 leave at `W-witness`, 0 at E4**. And for the 7.4 BREAK family the counterfactual fence is this increment's own clause (d), not E4. The retirement trigger pointed at the wrong gate | **FIXED at both sites.** `W-witness` holds the line; E4 and clause (d) are the two counterfactual fences. The trigger now names a **W-witness widening** — measured on a mutant as `D->A=35, stream-moves=11`, which is the direction that actually matters. ⚠ Verified independently before landing: 100 / 0. |
| R2-3 | P3 | `…_backedge_merge.ll`'s *"without clause (c) this region reaches the flatten"* is false — it reaches `E3-mergepred`, and `PredMuxFlatten.cpp`'s W6 block already argued exactly that 270 lines earlier | **FIXED.** The header now says what it pins and what it does not. |
| R2-4 | P3 | **the two irreducible fixtures contradict each other and both mis-describe their own module**, and one still carried the pre-F-4 wording F-4 says was corrected. Under the mutant BOTH fall to `E3-sideentry`, so the stated discriminator does not distinguish them | **BOTH HEADERS REWRITTEN.** Neither exhibits a shape only acyclicity can refuse, **nobody has constructed one**, and both now say so. Kept as two structurally different pins on the gate name — stated as the modest thing it is. |
| R2-5 | P3 | **all six new reject fixtures shipped the vacuity class round 1 removed from the accept fixtures IN THE SAME CHANGE** — `CHECK-NOT` on runtime symbols over a stderr-only decline pipe (0 bytes to stdout, measured) | **FIXED in all six.** ⚠ AND THE REPLACEMENT NOTE CREATED TWO REAL DIRECTIVES ON ITS FIRST DRAFT by spelling the directive names out — **lesson 6, which this bead had already paid for once**, caught by four red fixtures. The note now names no directive and says so. |
| R2-6 | P3 | `MEASUREMENT_INC3.md` §6's switch row is over-general: a switch whose arm hosts nested tainted control fires `NestedTainted`, so W does not refuse and the region IS claimed | **FIXTURED** (`control_predmux_accept_inloop_switch_nested.ll`) and the row corrected. Verified independently: ORACLE rc=1, SUBJECT rc=0, 2b `11 verified, 0 violation(s)`. |
| R2-7 | P3 | *"NOBODY HAS CONSTRUCTED ONE THAT CLAIMS"* (the non-returning / degenerate-merge path) is now **false** | **FIXTURED** (`control_predmux_accept_noreturn_degenerate_merge.ll`) and the comment retracted. It is SOUND and the argument does not depend on the merge being the real join — E3 + Kahn force SESE-acyclicity whatever block is named. ⚠ The converse is untested and the fixture says so. |
| R2-8 | P3 | a FIFTH F-1 premise site round 1 missed: `spec_reject_clone_loop.ll` (*"a loop is CYCLIC, so E2 leaves it"* — it now leaves at `E2-loopstraddle`) | **FIXED.** Verified independently. |
| R2-9 | P3 | two round-1 comment edits broke the sentence they were spliced into | **FIXED** at both sites. |
| R2-10 | P3 | the `llvm.loop` parenthetical has no subject and is false at C level (the e2e slice carries 3 before AND after) | **FIXED.** Verified independently: 0 in that module, 3/3 in the slice. |

## The standing lesson this round paid for

⚠ **A FIX IS A CHANGE, AND IT INHERITS THE FULL BURDEN OF ONE.** Round 1 corrected four
false premises and, in the correcting sentences, asserted a new mechanism (E4) that was
never measured and is wrong; it added four fixtures, three of whose headers assert
discriminators a one-clause mutant falsifies; and it removed two vacuous negatives while
adding six more of the same class. This is CLAUDE.md's *"a corrected bisection is still a
bisection"* at the level of a FIX rather than a MAP — and it is why the brief says to
budget two rounds, not one.

## A/B delta for the two fixtures added by round 2

```
…_accept_inloop_switch_nested            oracle=1 subject=0  D->A
…_accept_noreturn_degenerate_merge       oracle=1 subject=0  D->A
```
Running totals over **2142** fixtures: **A->D = 0**, D->A = 5, decline-string = 1,
**stream-moves = 0**.

⚠ The round-2 fixes were again verified not to change the binary: `cq-opt` rebuilds
**BIT-IDENTICAL** (`63d34f76…`) to the one the full A/B and the full `ctest` ran against.

## ⚠ ROUND 2's OWN BOUNDARY — this is the edge of the clearance

It ran **no full `ctest -j6`**, no `e2e-loop-twin-matrix`, no `cq-opt-equivalence-full`,
no `free_pairing_check_test.py`. It did **NOT** construct the **L1 / round-2-premise**
counterexample either (`lowerLoops` runs ONCE over a post-flatten body while detection
runs twice) — it argued the window is empty and probed the neighbourhood, which is an
argument plus an absence of a probe, **not a proof**; that window is now unattacked by
BOTH rounds and is the single largest hole in this clearance. It built **no QROM
(`ClaimableRead` / `E4-load` / `MaskLoads`) probe inside a loop** — the one E4 path that
speculates a memory access out of an arm, now with a per-trip index, and the thing
increment 5 will touch. It did not probe `MergePhiPeel` / `promoteFp80Union` /
`promoteRailBankCells` / `promoteVolatileScalarLocals` individually against the in-loop
surface; **did not add a customer probe to bd `cfmv`**, whose population plausibly grew
because `simplifyFlattenResiduesInFunction` now runs on more modules and nobody measured
by how much; and did not attack the degenerate-merge path past the one claiming probe.
No simulation, no statevector (Rule 2).
