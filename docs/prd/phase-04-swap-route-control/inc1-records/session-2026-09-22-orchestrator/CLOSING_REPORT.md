# CLOSING REPORT — session 2026-09-22

**One line:** bd `fn1q`'s recorded bisection is wrong in three places; the real
wall was re-derived from measurement, and increment 1 of four landed — the value
arm may now hold its **classical cone**.

## What the session found before it built anything

The brief was firm: two walls, both to be fixed, two increments, two rounds.
Re-measured on a clean-worktree rebuild of the binary the bead names (**bit-identical**
to the recorded hash, so the disagreement is real):

* **The condition wall does not exist.** `if (Z >= z[i])` with a constant arm
  ACCEPTS — exit 0, 120 lowered lines.
* **"Hand-unroll it and it COMPILES" proves nothing.** `-O1` const-folds a LOCAL
  `int p[]={3,2,1}` at a now-constant index and if-converts the result; the
  unrolled IR holds `select i1 %1, i32 4, i32 5` and **no value-arm branch**.
  With a GLOBAL array at a runtime index the **loop-free** form declines too.
* **The axis is `br` vs `select`, and `-O1` picks it** — not loops, arrays or
  memory. A flat, loop-free, ALL-CONSTANT **four**-variable arm declines; its
  two-variable sibling accepts at 69 lines.
* **The owner's program sits behind FOUR fences, not two.**

The over-decline verdict survives all three corrections. The corrections and the
route were taken to the owner, who chose the normaliser route and "land increment
1 fully".

## What shipped

* **Increment 1 — the value arm's classical cone.** Five conjuncts at
  `valueArmIsPureChain`, RECORDED on the region, hoisted by `emitValueRegion`
  ahead of the chain; plus `declineRound2TaintedArmCone`, the fourth re-ask in the
  post-fixpoint slot, in both entry points.
* **9 lit fixtures** (1 accept, 1 pre-hoisted twin with a *mechanical* `diff`
  identity assertion, 7 declines) and **1 e2e slice + golden**.
* **`tools/show_pipeline.sh`** — a `STAGE 2 · DECLINED` banner.
* **`CQ_CTRL_BT`** — an env-gated backtrace lever beside `CQ_CTRL_DBG`.
* **Three `CLAUDE.md` landing sections archived verbatim** (§4e, §4f, §4g) to keep
  the file under 150 k while §4h landed; 0 dangling cross-references.

## The three things worth carrying

**1. ⚠ A BEAD'S BISECTION IS DATA, NOT EVIDENCE, UNLESS ITS PROBES ARE COMMITTED
AND ITS BINARY IS NAMED.** Three of bd `fn1q`'s claims were false, including the
one its over-decline argument rested on. Nothing was careless — `example/` is
untracked, so the only way to bisect it is to edit it in place, and it was left
mid-bisection at a variant that *accepts*. **This session's probes are committed**
(`probes/`), and bd `5zwz` proposes the convention.

**2. ⚠ WHEN YOU REPLACE A STRUCTURAL CONTAINMENT WITH A SET OF PREDICATES,
ENUMERATE WHAT THE STRUCTURE WAS HOLDING.** CQ's own front-end calls were kept out
of a value arm by the fact that *any* non-chain arm op declined. Four conjuncts
replaced that and none named them; a `speculatable`-attributed `cq_phi` was then
hoisted into the pred and **deleted** as a global phase — exit 0, no `cqrt_rz_i1`
in the stream. Found by the independent reviewer, not by the implementer, not by
the corpus, not by 473 ctest entries. Closed by (K5), asked as *"does a CQ stage
OWN this call?"* rather than by a name prefix — the bd `11qv` round-4 lesson
verbatim.

**3. ⚠ A PROBE THAT REACHES THE WRONG FENCE FIRST MEASURES THE WRONG FENCE.** The
increment's record said the round-2 L1 shape could not be exhibited; the reviewer
built it. The trick is a **block between** the 6.5 merge and the value region's
branch — without one the pair declines earlier at bd `35t0`'s precedence check,
which reads exactly like "the shape does not occur". The "not claimed reachable"
wording is corrected **at both sites** in the same change as the fixture lands
(L7), and the correction is what the fixture header is mostly about.

## What is NOT established

Rule 2, in the words it has to be said in. This is exit codes, stage-2b rail
identities, emitted traces, a byte-identity twin pair and analytic reasoning.
**There is no simulator.** The independent opinion is the Rule-13 round's, and its
own 13-item "WHAT I DID NOT DO" section — no suite, no rebuild, 623 fixtures
unswept, no cross-function/`-O2`/loop-variant attacks — is the boundary of this
clearance.

## Filed, not fixed

bd `s9xi` (P2 — the flat four-φ all-constant decline), bd `vyne` (P3 — the if/else
two-cone twin covers only the gate stream), bd `2uz1` (P3 — Rule-14 debt: the
stray-op rule has two spellings that now answer differently), bd `5zwz` (P3 —
`example/` untracked, and the bisection-reproducibility convention).

**bd `fn1q` STAYS OPEN on three fences**: `MergePhiPeel` P9 (the no-in-loop peel —
a deliberate deferral carrying a written `BreakRegions` dangling-φ obligation),
`walkValueChain`'s empty-chain classical accumulator, and clause (c3). The owner's
`example/grover/grover_oracle_uncompute.c` **does not compile yet**, and this
report does not claim otherwise.
