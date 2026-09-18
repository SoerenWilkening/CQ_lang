# Session 2026-09-22 — brief

Read in this order: `CLAUDE.md` (**§4g is new**; **§4d has MOVED** to
`docs/CLAUDE-HISTORY.md`; ⚠ **the §5 Q-R1-1 paragraph has a new correction block
and it is the text most likely to be misread**), `ROADMAP.md`,
`$PREV/PROTOCOL.md` (a DELTA — the binding protocol is the 2026-09-19 one it
cites), `$PREV/CLOSING_REPORT.md`, `$PREV/DECISIONS.md`, `$PREV/GATES.md`,
`$PREV/ADJUDICATION_4JOK.md`, `$PREV/round5/REVIEW.md`. Then `bd prime`.

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-21-orchestrator/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

## 0. STATE AT CLOSE

`main` **62b0b111**. `cq-opt` **3368af1262695d7e4c…**, `libCQPass.so`
**48b8b4db61777082e9…** — the primary tree rebuilt at the close and **BIT-IDENTICAL
to the gated worktree binary**. Full `ctest -j6` **472/472 in 505.80 s**; lit
**2112 / 2111 + 1 XFAIL**; corpus A/B over 2109 fixtures **0 A→D**.
Fixtures **2112** · goldens **406** · ctest **472** · twin matrix 312+70.

⚠ `shasum -a 256 build/ir-pass/cq-opt` BEFORE believing any decline you see by hand.

**bd `tu9q` P0+P3 IS LANDED and bd `4jok` IS CLOSED.** The parked branch
`tu9q-p0-p3-wip` is now history; do not re-merge it.

## 1. WHAT IS FIRST — bd `a945`, and it is due ON THIS TREE

bd `zujr` (L3)'s written retirement trigger — *"the day a bank cell can hold a
TEMPLATE-minted rail, (I1) stops covering it and only (I3) does. Re-derive this
exemption then"* — **is due now**, because the exemption's stated ground is
`isInteriorTerminalHandle` **(I1)** and on this tree the gap is held closed by
`rewriteRailBankCellTypes` instead. That is a CONTINGENT closure standing in for
the stated reason: **`CLAUDE.md` L7's shape, the third instance in three sessions,
and the second in this exact area** (bd `xt20` is the other). Re-derive it AT THE
SOURCE — L7's twist is that a correction which does not land in the source is not
a correction, and this project has measured that three times on one sentence.

Then, in order: **bd `lgu8`** (the MULTI-EXIT carried handle — ⚠ NOT bd `h1ip`;
no guard, no seed incoming, exit φ muxes handle-against-handle), **bd `xt20`**,
**bd `ix2v`**, **bd `hyhl`**, **bd `xfso`**, **bd `fhh3`**, and the P3 for the four
`example/grover/*.c` that do not compile (retired two-argument `cq_phi`).

## 2. OWNER QUESTIONS TO BATCH AT OPEN

* **bd `11qv`'s residue, carried from last session's Q2** (answered *"only if
  `4jok` finishes early"* — it did not): the `_Bool` carried handle lowers as the
  ACCUMULATOR and still declines as the region's own CONDITION
  (`control flow under quantum control`, bd `r903`/`fg9k`/`boi6`). Wanted next?
  ⚠ Carry the caveat: this is the wall bd `3slt`'s tripwire names, so moving it
  makes `loop_carried_handle_reject_postloop_rotation.ll` accept a Rule-8 hazard —
  it has to land WITH the bd `s82e` work, not before it.
* **bd `46oo`**: a prior Rule-13 round's coverage row is unevidenced because its
  probes could not express the shape they claimed. Does the owner want the
  round-3 multi-exit probes re-run properly (a measurement), or is round 5's
  hand-written IR pair sufficient (a judgement)?

## 3. THE FOUR LESSONS THIS SESSION PAID FOR — carry them

1. **⚠ AN INSTRUMENT'S BLIND SPOT IS SHAPED LIKE ITS AUTHOR'S MODEL.** The
   orchestrator's clearance instrument shipped NINE boundary controls and FOUR
   real-trace mutants and was still unsound on its main axis — blind to every
   permutation-gate entanglement edge, so it passed all three canonical Rule-8
   violations and a real program the compiler itself warns about. **More controls
   by the same author do not find this. A different author does.** State an
   instrument's edge model in its header so a reviewer can attack the model.
2. **A MUTANT A FIX MAKES PASS IS NOT A VALIDATION UNTIL THE WHOLE SET IS
   RE-RUN.** The first fix introduced a false positive that would have been filed
   as a compiler defect had the trace not been read by hand.
3. **A PROBE FOR A CONTROL-FLOW SHAPE MUST BE CHECKED AT STAGE 1 FOR THE SHAPE IT
   CLAIMS** (bd `46oo`). `main(){ return slice(4); }` lets `-O1` delete a `break`
   written in terms of the argument.
4. **BEFORE FILING A LOST FIXTURE AS DEBT, TRY TO BUILD THE REPLACEMENT.** The L1
   fence's only pin was restored by one added line.

## 4. PROTOCOL — carry `$PREV/PROTOCOL.md` forward (a DELTA; read the file it cites)

Thirteen additions now. The five that are new this session are §9–§13 there.

## 5. Close
Standard Session Completion (`CLAUDE.md`). ⚠ **Use
`tools/labreport/seal_and_push.sh <entry.tex>`** — it enforces bd `6hy4`'s order
(`pull --rebase` → read HEAD → seal → commit → push → **verify with
`git merge-base --is-ancestor`**) and fails loudly if the recorded hash is not
reachable. Three entries in a row recorded an unreachable close hash by doing this
by hand; entry 014 did not.
