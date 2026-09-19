# bd `fn1q` increment 5a — Rule-13 ROUND 1 (independent agent)

**VERDICT: `BLOCKED` — 1 P1 (A COMPILER CRASH), 2 P2, 2 P3.**

Null controls run first: the reviewer's mutant-harness baseline rebuilt **bit-identical to
the subject**, and its corpus A/B null control reported **0 movers of 2153**.

## P1 — `F1`: the new E6 rail-φ leaf **SIGSEGVs the compiler** where the oracle declines

**CONFIRMED INDEPENDENTLY before fixing**, from ORDINARY C at the documented `-O1` floor —
the owner's own program with ONE operator changed (`if (!b0[i] && Z > 1)`):

| binary | rc | stderr |
|---|---|---|
| ORACLE | 1 | `cq controlled lowering: control flow under quantum control` |
| SUBJECT (defective) | **139** | an LLVM crash dump |

**THE CAUSE.** `isStructuralRailPhi` is checked at E6 **before** the `dyn_cast<PHINode>`
arm, so the φ never reaches `isConvertiblePhiCond` and is never RECORDED in `S->Recorded`.
`convertPhis` therefore never converts it, and the moment the **false-edge literal** is
demanded, `literal()` hands a raw `PHINode` to `buildNegation`, whose terminal
`cast<BinaryOperator>(V)` is UNCHECKED.

⚠ **THE CRASH SITE'S OWN COMMENT NAMED THIS, IN WRITING, BEFORE THE INCREMENT WAS
WRITTEN** — `isConvertiblePhiCond`'s condition 3: *"`buildNegation` would run its terminal
`cast<BinaryOperator>` on a `PHINode`: an assert in a `+Asserts` build and an unchecked bad
cast in the shipped Release build."* A retirement trigger was read by nobody. L3's mirror,
and the same shape as the 2026-09-14 P1.

**POPULATION: 12 of a 32-cell polarity matrix crashed**, all 12 declining cleanly on the
oracle. The trigger is simply *"the false-edge literal is demanded"* — which `clang -O1`
makes true about HALF the time (Rule 9), a sentence increment 2 had already written at that
same site. It crashes for CLASSICAL-prep φs too, i.e. the shape the increment claimed it
merely declines later.

⚠ **CORROBORATED FROM THE COMMITTED CORPUS, not only from hand-written probes.** A mutant
with the incoming-check removed makes **three committed fixtures crash**
(`control_predmux_accept_w6_direct_condphi.ll`,
`control_predmux_accept_w6_stranded_merge_condphi.ll`,
`control_predmux_leave_w6_selectchain_phi.ll`). Those φs are handled correctly today only
because `isConvertiblePhiCond` **records** them. Admitting a φ at E6 without recording it
IS the defect.

**WHY P1 AND NOT "JUST A CRASH":** Rule 1's *no third path* postcondition is violated — no
`DiagnosticInfoUnsupported`, no `!dbg`, no source location; a decline became a crash
report. And the bad cast is **undefined behaviour** in the Release build every gate here
runs, not a guaranteed trap. Precedent: CLAUDE.md §4f, where gate (P4)'s first spelling did
exactly this and was filed P1.

⚠ **NO SHIPPED GATE SAW IT.** 0 of 2153 corpus fixtures crash the subject; full `ctest` was
479/479. 79 fixtures carry a `phi i1` with a `cq_theta_i1` incoming, but only the
increment's own two exercise it AS A PREDMUX BRANCH CONDITION, and both sit at the one safe
polarity.

**FIXED, IN TWO HALVES — and round 1 named the second before it was written (F4):**
`buildNegation` takes a rail φ through the rail-LEAF route (`¬x = xor x, true`), **and**
the ARM-SWAP FOLD accepts a rail-φ operand so the `xor` is removed before
`collectCondTree` — which refuses an `xor` with a constant operand — ever sees it.
Widening the arm alone would have turned the negated polarity into a claim-then-decline.
Verified: polarity sweep **18 cells, 0 crashes**, 8 of them now COMPILE; the owner's
program still compiles. Pinned by `control_predmux_reject_rail_phi_false_edge.ll`,
**MUTATION-VALIDATED** (half 1 reverted ⇒ that fixture exits **139**; restored ⇒ declines).

⚠ **THE OPEN HALF OF THE P1's SEVERITY, WHICH ROUND 1 COULD NOT SETTLE AND WHICH IS STILL
OPEN:** it established the value reaching the cast is not a `BinaryOperator` and that the
recursive call received NULL, but **did not bound whether a different input or allocator
state yields a garbage `Value*` that builds a WRONG PREDICATE instead of crashing.** It
also did not build a `+Asserts` `cq-opt`. Settle this in round 2.

## The rest, with dispositions

| # | sev | finding | disposition |
|---|---|---|---|
| F2 | P2 | *"same verdict, same string, same diagnostic"* is FALSE — measured on ONE module at ONE polarity. Counterexamples: the false-edge polarity CRASHED rather than declining; and with a SECOND independent tainted region the string moves (`nested control flow` → `control flow`), because the flatten mutates the first region and the decline lands with a different owner | **CORRECTED in all four places.** The defensible claim is narrower: the VERDICT is preserved and no decline becomes silence; the STRING can move, and Rule 12 pins strings character-for-character. |
| F3 | P2 | the new accept fixture is **7 of 8 VACUOUS** under injection — an injected `cqrt_measure` (Rule 5), `cqrt_free` (Rule 6), `cqrt_x` and `cqrt_ry` (Rule 7) all passed, while the header asserted exactly those properties | **FIXED**: nine exact per-family counts. Re-validated with a null-control matrix: **8 of 8 CAUGHT**. ⚠ Two of my own instrument bugs surfaced doing it — a `cqrt_ry_i1` pin missed an injected `cqrt_ry_i32` (a whole-family count fixes it), and `grep … \| count 0` cannot work at all. |
| F4 | P3 | a fix owes TWO halves — the `buildNegation` arm is unsound without the arm-swap fold | **USED**: both halves landed together, and the note is written at both sites. |
| F5 | P3 | the record says `stream-moves = 2`; the true count is **3** | **CORRECTED.** The third is `control_predmux_accept_selectchain_loopphi_residue.ll`, where a dead `phi i1` survives that the oracle removed — because BOTH erasers `continue` on `isCondRailPhiShape`, which matches ANY 2-incoming `i1` φ, not just a rail. ⚠ **NOT attributable to 5a** (byte-identical to the isolating mutant) — it belongs to increment 2 / bd `cfmv`. Harmless (an all-constant `i1` φ emits no gate). Now that `isStructuralRailPhi` exists it is the precise predicate for those guards; NARROWING them is a stream change owing its own round (L3 — do not narrow an eraser guard "for symmetry"). |

## What round 1 checked and found RIGHT

The owner's program is a **correct circuit**, walked line by line across all 88 trace lines
(§2 of `MEASUREMENT_INC5A.md`). No Rule-7 violation in any new accept (scripted scan of 18
lowered modules). Rule-8 interference declines on both binaries with a trailing
`cq_theta` on `Z` or `P`. Polarity is not confused on the accept path. The adversarial φ
shapes decline on both binaries (two different rails muxed; a rail measured before the
read; a `true` constant incoming; const/const). Both erasers protect a rail φ. Corpus A/B:
**A→D = 0**, crash-flips 0.

## ⚠ ROUND 1's OWN BOUNDARY — and one retraction it made itself

No full `ctest`, no twin matrix, no `free_pairing_check_test.py`, no quarantine selftest.
It did NOT adjudicate increments 3 and 4 on their merits (its oracle predates them). It did
NOT pin the P1's NULL provenance (above). It did NOT build a `+Asserts` binary, probe
erasers (3)/(4) with a rail φ, exercise round-2 `repropagateControlMerges` beyond one
probe, or test any pipeline but `-O1`. No simulation.

⚠ **AND IT RETRACTED ONE OF ITS OWN ROWS**: an `rc=127 → 0` flip it had reported was
CONTENTION — measured under load **it had created itself** (three cmake builds and a second
2153-fixture sweep in flight, load ~28). Re-run serially: all five binaries `rc=0`,
byte-identical IR, 5 runs each. It recorded the retraction rather than dropping it quietly,
noting: *"I caught it only because the row was implausible enough to re-run. Had it been
plausible, I would have shipped it."* That is CLAUDE.md's Rule-19 discipline working, and
L10's lesson in its sharpest form.
