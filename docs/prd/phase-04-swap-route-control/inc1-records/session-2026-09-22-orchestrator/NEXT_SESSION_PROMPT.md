# NEXT SESSION — bd `test_C_libtooling-fn1q`, increment 2 of 4

Read, in this order:
```
CLAUDE.md                              (§4h is NEW; §4e/§4f/§4g MOVED to docs/CLAUDE-HISTORY.md)
.../session-2026-09-22-orchestrator/MEASUREMENT.md   ← ⚠ READ §6 BEFORE QUOTING §2
.../session-2026-09-22-orchestrator/{CLOSING_REPORT,GATES,PROTOCOL,IMPL_INC1,REVIEW_R13}.md
```
Then `bd prime` and `bd show test_C_libtooling-fn1q`.

```
main 7061eff4 · cq-opt 1b396ed08b01b8ecac7b268ba1d11ec3a90200e945ed091a43bf34ff23ad1c9e
               libCQPass.so f3a372fc275bcf15f2b3632b1fe3b586da086d6cc2040f0147675abe6cdcbe75
ctest 473/473 in 529.47 s · lit 2121 (2120 + 1 XFAIL) · fixtures 2121 · goldens 407
ORACLE for the next A/B is THIS binary. The pre-increment one is 3368af1262695d7e4c….
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.

## ⚠ FIRST: bd `fn1q`'S ORIGINAL BISECTION IS WRONG. DO NOT BUILD ON IT.

Three of its claims are falsified and re-measured — see §4h and `MEASUREMENT.md`.
The short version: **there is no condition wall**, the hand-unrolled twin proves
nothing, and the axis is `br` vs `select` with `-O1` choosing it. The bead's own
note carries the correction; read the note, not the title.

## THE TASK: increment 2 — retire `MergePhiPeel` P9 for a scoped in-loop peel

**F1 is the owner's program's FIRST wall.** `MergePhiPeel.cpp`'s P9
(`if (regionEntryInLoop(BI)) continue;`) means a 2-φ in-loop merge is never
normalised, so `soleMergePhi` is null and `recoverRegion` returns `OffPattern` →
`control flow`. The owner's arm merges both `Z` and `P`, so it lands there.

⚠ **P9 IS A DELIBERATE DEFERRAL, NOT AN OVERSIGHT, AND ITS COMMENT IS THE BRIEF.**
It says so in writing: *"a refusal to widen two axes at once"*, and it carries a
**dangling-pointer obligation** — `TaintSet::BreakRegions` holds RAW `PHINode *`
(`EscapePhi`, `CounterPhi`), written by `lowerLoops` BEFORE the peel and read by
`lowerBreakReversePlay` AFTER it, and what keeps them safe today is P9 plus P1.
Its retirement trigger is explicit: *"if P9 is ever narrowed to admit an in-loop
site, the peel must first scrub or re-derive `BreakRegions`' φ pointers — this is
the bd `drbq` Inc-1 stale-set class."* **That is the increment, and the measurement
behind P9's containment claim (17 fixtures reach the stage with `BreakRegions`
non-empty and NOT ONE peels a φ) must be RE-RUN, not quoted.**

The second named hazard is `flatRegionRollableInLoop` (bd `8h7d.5`) rolling a
peeled `select` plus a freshly cloned tainted compare in the loop BODY — *"a
combination nothing in the tree has measured"*.

**After F1, two fences remain**: F2 (`walkValueChain` returns EMPTY for a CLASSICAL
accumulator → `ArmClassify.cpp:6193` `value-arm swap-route`) and F4 (clause (c3)).
Both are separate increments with separate rounds.

## WHAT INCREMENT 1 LEFT YOU

* The cone machinery is in place and cleared; an in-loop value arm's cone needs no
  new work once the region is claimable.
* `probes/` has 20 committed `.ll` + 21 `.c` probes and the A/B harness (`one.sh`,
  `xargs -P6`, ~2 min for the whole corpus). **The null control runs first.**
* `CQ_CTRL_BT=1` beside `CQ_CTRL_DBG=1` names the FIRING PREDICATE by backtrace.
  Use it before writing down which fence fired — it corrected the bead twice.

## FIVE THINGS THIS SESSION PAID FOR

1. **A bead's bisection is data, not evidence, unless its probes are committed and
   its binary is named.** Three claims false; one was the whole argument.
2. **When you replace a STRUCTURAL containment with a set of predicates, enumerate
   what the structure was holding.** (K5) exists because four conjuncts replaced
   "any non-chain arm op declines" and none named CQ's own calls.
3. **A probe that reaches the wrong fence first measures the wrong fence** — and
   the earlier decline reads exactly like "the shape does not occur".
4. **Ask the question you mean, not a name** (bd `11qv` round-4 (P4), paid again).
5. **`rc=$?` on the line after the command**, never inside `if ! cmd; then rc=$?`
   (the negated compound's status is 0). It cost a wrong banner.

## AFTER bd `fn1q`

The standing owner ruling: pay down P1 correctness debt, starting with bd `s82e`
(⚠ RE-MEASURE FIRST — it may already be fixed by the 2026-09-21 landing). Then bd
`a945`, bd `a3z7`/bd `0njv`, bd `yiid` (owner decision), bd `lo7u`. New from this
session: bd `s9xi` (P2), bd `vyne`, bd `2uz1`, bd `5zwz`.
