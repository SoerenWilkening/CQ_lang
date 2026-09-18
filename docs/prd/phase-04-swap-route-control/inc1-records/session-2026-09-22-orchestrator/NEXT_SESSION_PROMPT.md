# NEXT SESSION — bd `test_C_libtooling-fn1q`, increments 2–4

Read, in this order, before doing anything:
```
CLAUDE.md          (§4h is NEW — read it FIRST, it corrects the bead you are about
                    to work from; §4e/§4f/§4g MOVED to docs/CLAUDE-HISTORY.md)
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-22-orchestrator/
    MEASUREMENT.md         ← ⚠ READ §6 BEFORE QUOTING §2. The table is pre-increment.
    CLOSING_REPORT.md · GATES.md · IMPL_INC1.md · REVIEW_R13.md
    PROTOCOL.md            (a DELTA — the binding protocol is the 2026-09-19 one it cites)
```
Then `bd prime` and `bd show test_C_libtooling-fn1q`.

```
main 2e69a9eb
cq-opt       1b396ed08b01b8ecac7b268ba1d11ec3a90200e945ed091a43bf34ff23ad1c9e
libCQPass.so f3a372fc275bcf15f2b3632b1fe3b586da086d6cc2040f0147675abe6cdcbe75
ctest 473/473 in 529.47 s (load 2.9→72) · lit 2121 (2120 + 1 XFAIL)
fixtures 2121 · goldens 407 · twin matrix 312 + 70 = 382
LLVM = /usr/local/opt/llvm@19/bin   (NOT on PATH)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.
⚠ **This binary is the ORACLE for your A/B.** The pre-increment-1 one is `3368af1262695d7e4c…`.

---

## 0. ⚠ THE BEAD'S ORIGINAL BISECTION IS WRONG. DO NOT BUILD ON IT.

bd `fn1q`'s description records two walls and proves them by hand-unrolling. **Three
of its claims are falsified and re-measured** (§4h, `MEASUREMENT.md`; the bead's own
appended note carries the correction — read the note, not the title):

* **There is no condition wall.** `if (Z >= z[i])` with a constant arm ACCEPTS —
  exit 0, 120 lowered lines.
* **"Hand-unroll either and it COMPILES" proves nothing** — and it was the whole
  over-decline argument. `-O1` const-folds a LOCAL `int p[]={3,2,1}` at a
  now-constant index and if-converts the result, so the unrolled IR holds
  `select i1 %1, i32 4, i32 5` and **no value-arm branch at all**. Swap in a GLOBAL
  array at a runtime index and the **loop-free** form declines too.
* **The axis is `br` vs `select`, and `-O1` picks it** — not loops, arrays or
  memory. A flat, loop-free, ALL-CONSTANT **four-variable** arm declines
  (bd `s9xi`) while its two-variable sibling accepts at 69 lines.

The over-decline verdict survives all three. The owner's program sits behind **FOUR**
fences; increment 1 closed one.

---

## 1. THE FOUR FENCES, AND WHICH ARE LEFT

| | fence | site | status |
|---|---|---|---|
| **F1** | `MergePhiPeel` **P9** — no in-loop peel, so a 2-φ in-loop merge has no `soleMergePhi` and `recoverRegion` returns `OffPattern` | `ir-pass/src/MergePhiPeel.cpp:382` | **OPEN → increment 2** |
| **F2** | `walkValueChain` returns EMPTY for a CLASSICAL accumulator, so `isValueChangingOp(Base)` fires | `ir-pass/src/ArmClassify.cpp:6358` | **OPEN → increment 3** |
| F3 | `valueArmIsPureChain`'s stray-op rule | `ArmClassify.cpp:2435` | **CLOSED** 2026-09-22 |
| **F4** | clause (c3) `iterationLocalTaintEscape` — fires only when the SAME value is read by both the condition and the arm | `ArmClassify.cpp:5922` **and** `LoopLowering.cpp:6894` (**one question, two sites — Rule 14 says fix the question**) | **OPEN → increment 4** |

⚠ **Those line numbers moved when increment 1 landed** (`:6193`→`:6358`,
`:5765`→`:5922`). Re-grep rather than trusting any number in an older record.

**The acceptance target is the owner's own file**: `./tools/show_pipeline.sh
example/grover/grover_oracle_uncompute.c` exits 0, stderr clean, stage 2b STRICT.
⚠ The file on disk is currently at the **all-constant variant `Vb`, which ACCEPTS**
— a previous session bisected it in place. The owner's real program is in
`probes/owner.c`. **Restore it before you claim anything about it.**

---

## 2. INCREMENT 2 — retire `MergePhiPeel` P9 for a scoped in-loop peel

**This is the owner's program's FIRST wall.** Its arm merges both `Z` and `P`, so
the merge carries two φ and the peel never runs in a loop.

⚠ **P9 IS A DELIBERATE DEFERRAL AND ITS COMMENT IS YOUR BRIEF.** It says so in
writing — *"a refusal to widen two axes at once"* — and it carries a **written
dangling-pointer obligation**:

> `TaintSet::BreakRegions` holds RAW `PHINode *` (`LoopBreakRegion::EscapePhi`,
> `::CounterPhi`), written by `lowerLoops` BEFORE this stage and read by
> `lowerBreakReversePlay` AFTER it. What keeps them safe today is THIS CLAUSE plus
> P1. **RETIREMENT TRIGGER: if P9 is ever narrowed to admit an in-loop site, the
> peel must first scrub or re-derive `BreakRegions`' φ pointers — this is the bd
> `drbq` Inc-1 stale-set class.**

**The containment measurement behind P9 must be RE-RUN, not quoted**: "over the 1814
fixtures, 17 reach this stage with `BreakRegions` non-empty and **not one of them
peels a φ**". The corpus is 2121 now.

The second named hazard is `flatRegionRollableInLoop` (bd `8h7d.5`) rolling a peeled
`select` plus a freshly cloned tainted compare in the loop BODY — *"a combination
nothing in the tree has measured"*. Measure it.

## 3. INCREMENT 3 — the CLASSICAL ACCUMULATOR (`ArmClassify.cpp:6358`)

`armonly_p.c` in `probes/` is the minimal exhibit. `P` is classical at round-1 taint,
so the arm's `add` is not a tainted binop, `walkValueChain` never starts, and
`isValueChangingOp(Base)` declines `value-arm swap-route`.

⚠ **The neighbouring `select` spelling of the same program ALREADY LOWERS**, through
`SelectMergeEmit` + bd `zujr`'s loop-carried-handle promotion. So the question is not
"can we build this circuit" but "why does the `br` spelling not reach the promotion".
Start there before designing anything.

⚠ **`value-arm swap-route` names a mechanism that no longer exists** (bd `OQ-13`,
6 sites, 28 fixtures). Read the predicate, not the message.

## 4. INCREMENT 4 — clause (c3), and it is ONE question at TWO sites

`iterationLocalTaintEscape` fires when the per-trip value is read by both the
condition and the arm. **(c3) has already been narrowed once** (bd `8h7d.12`, blast
radius one fixture in 2106) — read that history and **re-measure the blast radius**.
Rule 14: fix the question, not one spelling.

---

## 5. HOW TO LAND EACH ONE — not negotiable

Each is an ACCEPT-direction widening and owes, **separately**:

* **Rule-12 red-green**: the decline fixture FIRST, watched failing, then the
  minimal implementation. Plus an injection/mutation check that the fixture is
  non-vacuous.
* **Its own Rule-13 round by an agent that did not write it.** ⚠ The round on
  increment 1 returned **0 P1 but two real P2s**, one of which was a hole the
  4-fixture corpus, 2121 lit tests and 473 ctest entries all missed. Budget it.
* The standing **rolled-vs-unrolled probe with a trailing non-diagonal gate** on
  every register the condition reads (protocol item 5 / G-13).
* **Corpus A/B with the NULL CONTROL RUN FIRST**, then a positive control.
  `probes/one.sh` + `ls ir-pass/test/*.ll | xargs -P6 -n1 ./one.sh` ≈ 2 min.
* A full `ctest -j6`, and **report its load** — a figure under agent load is not
  comparable with a quiet-box one.
* **A tracked fixture AND an e2e slice.** `example/` is NOT in the repository
  (`git ls-files example/` = 0, bd `5zwz`), so nothing in any gate compiles it.

---

## 6. WHAT INCREMENT 1 LEFT YOU

* The cone machinery is cleared; an in-loop value arm's cone needs no new work once
  the region is claimable.
* **`probes/`** — 20 `.ll` + 21 `.c` probes, the A/B harness, and the reviewer's own
  probe set. A bisection recorded without its probes is not reproducible (bd `5zwz`).
* **`CQ_CTRL_BT=1`** beside `CQ_CTRL_DBG=1` prints a BACKTRACE naming the firing
  predicate. Use it before writing down which fence fired — it corrected the bead
  twice, and the brief's own replacement hypothesis was wrong too.
* `tools/show_pipeline.sh` now prints `STAGE 2 · DECLINED` on a compiler decline.
* Use **`$PREV/probes/entangle.py`** (edge-complete, 18 controls), **never**
  `dephase.py` (ships marked SUPERSEDED with its two misses in its header).

## 7. SIX LESSONS THIS SESSION PAID FOR

1. **A bead's bisection is data, not evidence, unless its probes are committed and
   its binary is named.**
2. **When you replace a STRUCTURAL containment with a set of predicates, enumerate
   what the structure was holding.** (K5) exists because four conjuncts replaced
   "any non-chain arm op declines" and none named CQ's own front-end calls — a
   `speculatable`-attributed `cq_phi` was hoisted into the pred and DELETED.
3. **A probe that reaches the wrong fence first measures the wrong fence** — the
   earlier decline reads exactly like "the shape does not occur".
4. **Ask the question you mean, not a name** (bd `11qv` round-4 (P4), paid again).
5. **`rc=$?` on the line AFTER the command**, never `if ! cmd; then rc=$?` — the
   negated compound's status is 0.
6. **An increment owes the L1 round-2 question about ITSELF**, not only about its
   neighbours.

## 8. AFTER bd `fn1q`

Standing owner ruling: pay down P1 correctness debt, starting with **bd `s82e`** —
⚠ **re-measure first, it may already be fixed** by the 2026-09-21 landing. Then bd
`a945`, bd `a3z7`/bd `0njv`, bd `yiid` (owner decision), bd `lo7u`.
New from this session: bd `s9xi` (P2), bd `vyne`, bd `2uz1`, bd `5zwz`.
