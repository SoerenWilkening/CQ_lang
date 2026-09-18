# CLOSING REPORT — session 2026-09-21

**One line:** bd `4jok`'s gate is discharged and bd `tu9q` P0+P3 is LANDED
(`62b0b111`) — the first composed accept surface in this project's history to be
**adjudicated as a family** rather than cleared by the silence of instruments that
cannot see it.

## What shipped

* **bd `tu9q` P0+P3** merged onto `main` — clause (ii-d), P0's component
  partition, P1 `multiplicityAgrees`, P2's loop-exit anchor, and
  `declineUndischargedExitObligations`. One conflict (`LoopPlan.h`), resolved
  additively; both postconditions keep their call sites.
* **Six e2e slices + goldens** for the composed surface, each verified
  **non-vacuous** against the pre-landing compiler. One is the owner's shipped
  cascade plus a line; one is the nested multiplicity shape; one is two quantum
  functions in one module (bd `1yeu`'s structural blind spot); one is the **tenth**
  surface member round 5 found where round 3 had recorded a decline.
* **Three new lit fixtures**: the F-1 nest pair (multi-exit decline + its
  one-conjunct-different accept control) and the replacement L1 pin.
* **Eight existing fixtures re-derived**, four changing verdict, none deleted (L8).
* **Two source comments corrected** — both pure documentation, binary
  bit-identical across the edits.
* `tools/labreport/seal_and_push.sh` — bd `6hy4`'s ordering fix as an executable
  script, so the close cannot repeat the erratum a fourth time by hand.

## The three things worth carrying

**1. The owner's ruling shape earned its keep.** *"Adjudicate, then land if
clear"* rather than a disposition at open. The round returned 0 P1 — so the
landing proceeded — but it also returned a **P2 in the increment's own argument**
that neither the orchestrator nor round 3 had reached. Ruling "accept" at open
would have shipped that as an unread comment; ruling "refuse" would have kept the
compiler declining the owner's own next line of code for a hazard that does not
occur.

**2. ⚠ The clearance instrument was the thing that failed, and nine boundary
controls did not catch it.** `dephase.py` built its ancestry graph from
`cq_template_*` mint operands only, so every PERMUTATION gate produced no edge —
and those are how every value-merge rail in the subject programs is built. It
reported OK on all three canonical Rule-8 violations **and on a real program the
compiler itself warns about**. It had already lied once in the same direction and
been fixed. **An instrument's blind spot is shaped like its author's model, so
more controls by the same author do not find it**; an instrument built by someone
else does. The clearance now rests on the round's `entangle.py`, not on mine.

**3. A fence's last pin was recoverable, and the cost would otherwise have been
filed as debt.** `loop_pairing_reject_round2_falsified.ll` was the only pin in
2109 fixtures of a still-live L1 fence. One post-loop read of the rail falsifies
(ii-d)'s `allUsersInside` conjunct and the fence fires again on both binaries.
**Check the retired fixture's accept conjuncts for one you can falsify cheaply
before reporting a loss.**

## What is NOT established

Rule 2, in the words it has to be said in. This is exit codes, stage-2b rail
identities, emitted traces and analytic reasoning. **There is no simulator**, and
this project's own history records every shipped Grover golden clearing exactly
this bar while being the identity. The independent opinion is round 5's, and its
own limits are in its §4.

## Filed, not fixed

bd `a945` ((L3)'s trigger is due — held closed on a composed binary by
`rewriteRailBankCellTypes`, not by the `(I1)` ground its comment gives; **L7's
shape, third instance in three sessions**), bd `46oo` (the round-3 probe-design
trap — `slice(4)` lets `-O1` delete a `break` written in terms of the argument, so
a prior round's multi-exit coverage row is unevidenced), and a P3 for the four
shipped `example/grover/*.c` that do not compile because they use the retired
two-argument `cq_phi`.

Carried untouched: bd `lgu8`, bd `xt20`, bd `ix2v`, bd `hyhl`, bd `xfso`,
bd `fhh3`, and bd `11qv`'s `_Bool`-condition residue (owner Q2: only if bd `4jok`
finished early — it did not).
