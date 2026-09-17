# Session 2026-09-21 — brief

Read in this order: `CLAUDE.md` (**§4f is new**, and **§4c has MOVED** to
`docs/CLAUDE-HISTORY.md`), `ROADMAP.md`, `$PREV/PROTOCOL.md` (a DELTA — the
binding protocol is still the 2026-09-19 one it cites), `$PREV/CLOSING_REPORT.md`,
`$PREV/DECISIONS.md`, `$PREV/GATES.md`, `$PREV/round{2,3,4}/REVIEW.md`, then this.

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-20-orchestrator/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

## 0. STATE AT CLOSE

See `$PREV/GATES.md` for the hash-keyed rows. Full `ctest -j6` **466/466 in
594.30 s** ⚠ **under concurrent agent load — not comparable with a quiet-box
figure.** Corpus A/B over 2108 fixtures: **0 A→D**. Fixtures 2108 · goldens 400 ·
ctest 466 · twin matrix 312+70.

⚠ **`shasum -a 256 build/ir-pass/cq-opt` BEFORE believing any decline you see by
hand.** A stale `cq-opt` makes a fixed program look broken and a broken pass look
green in lit.

## 1. THE FIRST THING TO DO: bd `4jok` — THE COMPOSITION GATE

It is **P2 and it GATES the bd `tu9q` P0+P3 landing**, and it is the first time
in five sessions that the composed accept surface has been **exhibited** rather
than asserted. Nine C programs compile ONLY when bd `zujr` and bd `tu9q` P0+P3
are both present — **one of them is the owner's rolled cascade plus one line** —
and five of them decline on the shipped compiler at the bd `s82e`/`6n1s` string
*"rolled body leaks a rail entangled with a rotated register"*. The probes and
the four binaries' hashes are in `$PREV/round3/`.

**What is owed**: adjudicate those nine AS A FAMILY, on a COMPOSED binary, with
fixtures and goldens — not one at a time. ⚠ Every instrument in the tree reports
ZERO on them (2106-fixture corpus A/B: 0 composition-only movers; twin matrix
verdict tables byte-identical at 382 cells; all 390 e2e slices identical), so
**the instruments cannot help you here and their silence is not evidence.** That
is Rule 2's *necessary and not sufficient*, in its sharpest form yet.

⚠ **SECOND GATE ON THE SAME LANDING**: bd `tu9q` P0+P3 **alone** over-accepts the
bd `6n1s` g8 shape (`i1`, exit 0 with only the `lyyf` warning) because the branch
predates `22a0ab11`. It must never land below bd `6n1s`.

## 2. THEN, IN THIS ORDER

1. **bd `lgu8`** — the MULTI-EXIT carried handle. ⚠ **It is NOT bd `h1ip` and
   `h1ip`'s landed fix does not reach it**: no guard, no seed incoming to
   rewrite, and its exit φ muxes handle-against-handle. The fix shape is in the
   bead.
2. **bd `xt20`** — (P1)'s stated ground is WRONG (Phase 7.4 puts three NON-merge
   rails in `taint.ControlOwnedRails` before the promotion runs). Closed today
   only by the nested-loop fence, which is a CONTINGENT closure, not the reason
   the source gives. **L7's shape for the second time in one bead's history.**
3. **bd `ix2v`** — the narrow-literal ABI attribute. Pre-existing; fixing it moves
   goldens across the tree, so it is its own increment.
4. **bd `hyhl`** — the five diagnostic degradations. Untouched this session.
5. **bd `xfso`, bd `fhh3`** — round 2's remaining two P3s (a missing fixture, a
   trigger to re-word at the site).

## 3. OWNER QUESTIONS TO BATCH AT OPEN

* **bd `4jok`**: those nine composed-only accepts include the owner's cascade plus
  one line. Does the owner want them COMPILING (in which case `tu9q` P0+P3 lands
  with them as its fixtures) or does the `s82e` fence refuse them? This is the
  same question shape as Q3 of 2026-09-20 and it is now concrete rather than
  hypothetical.
* **bd `11qv` residue**: the `_Bool` carried handle lowers when it is the
  ACCUMULATOR and still declines when it is the region's own CONDITION
  (`control flow under quantum control`, bd `r903`/`fg9k`/`boi6`). Is that second
  spelling wanted next?

## 4. PROTOCOL — carry `$PREV/PROTOCOL.md` forward (it is a DELTA; read the file it cites)

Its six additions, in one line each: **(1)** every mutation/peel harness ships a
NULL-TAG boundary control run on every invocation, written BEFORE the first real
measurement; **(2)** a widening that moves zero fixtures owes a fixture, and its
record owes the word *defensive*; **(3)** before implementing a "three-line"
widening, READ what else consumes the value you are about to mutate — bd `11qv`'s
load-bearing half was found that way and no probe in the session reached it;
**(4)** a bead or trigger that names the next wall is a LOWER BOUND — **and so is
a correction to one**; **(5)** an accept-direction widening of a condition/reader
fence owes a rolled-vs-unrolled probe with a trailing non-diagonal gate;
**(6)** run the bead's LITERAL subject on both binaries before closing it.

## 5. Close
Standard Session Completion (`CLAUDE.md`): bd (`--append-notes`), lab entry 014
(≤5 pages, `--seal`), `CLOSING_REPORT`/`DECISIONS`/`GATES`,
`git pull --rebase && git push`.
