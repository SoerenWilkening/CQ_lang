# Session 2026-09-19 — orchestrator prompt (the bd `zujr` session)

You are the **orchestrator**. You delegate to **opus subagents in git worktrees**; you do not build,
run suites, or edit pass source yourself. Same workflow as sessions 2026-09-13 / -14 / -14c / -15 / -18.

Read first, in this order: `CLAUDE.md`, `ROADMAP.md`, `$PREV/PROTOCOL.md` (copy it forward WITH the
copied-forward checklist at its top corrected — the oracle block, every file path, the vacuity checker
line, the `--allow-unproven` count), `$PREV/ROUTING.md`, `$PREV/DECISIONS.md` (Q1–Q4, O1),
`$PREV/MERGE_FILINGS.md` (F-1…F-13), `$PREV/gate/FILINGS.md` (G-1…G-12), `$PREV/CLOSING_REPORT.md`,
then this file as your brief.

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang
SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-19-orchestrator/
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

## 0. STATE OF THE TREE AT CLOSE (measured, hash-keyed — `$PREV/GATES.md`)

`main` = `014b4381 (+ the closing records commit on top)`; primary `build/ir-pass/cq-opt` = `07d937842bfb5135fe068d1b9bfb1b2cd501e67c152bf4932d9408d5c9fed6b4 (libCQPass.so 19dcfde08ffbb69c…)` (rebuilt ONCE at
close, bit-identical to the gated worktree binary). Full `ctest -j6` `459/459 in 515.58 s (load 47→5)`; equivalence
`2099/0`; corpus 7010 rows / 156 movers / 0 unattributable; twin matrix `382` cells
(`312` expected + `70` quarantine); fixtures `2099`; goldens `394`.

**Which of the loop-headline parts are landed — in words:**

| part | state at close |
|---|---|
| bd `tu9q` (hoisted-template half) | **HALF landed.** bd `6n1s` + P1 (multiplicity test) + P2 (loop-exit anchor) are on `main`; **P0+P3 are BUILT, MEASURED and NOT LANDED** (branch `tu9q-p0-p3-wip` @ `30b80d7f`, binary `e951d5d1…`) under the six obligations in `$PREV/DECISIONS.md` Q4 / `trackT2/P0P3_STATUS.md` / `review_r13_group1/REVIEW.md` part C. `1m5p` CLOSED; `s82e` and `tu9q` OPEN with the half-landed state on them. |
| bd `x5fp` (§3c clobber per activation) | **BUILT and PARKED**, branch `x5fp-clobber-per-activation` @ `69414276`, NOT on `main`: no program has S-1 as its only wall (`trackX/FILE_SURFACE.md`). Lands with its first accept, which arrives with bd `3qlq.6`/`ej5w`. |
| bd `drbq.12` (LICM-hoisted compare, P4) | **LANDED** (`ArmClassify.cpp`; 87 D→A movers; composition with Group 1 measured clean on `dD1`/`dD5`). |
| bd `832l` (L-3 classical rail root) | NOT built (this session did not touch it — it is `zujr`'s body). |
| bd `ej5w` (L-4 in-loop value arm at the X1 sites) | NOT built. ⚠ Track X measured that the wall BEHIND the clobber is `ControlDetect.cpp`'s IN-LOOP SCOPE FENCE part 2 (bd `3qlq.6` / `1dbk` item 1), NOT `ej5w` — both must move. |
| bd `8h7d.11` ((c3) escape over-decline) | NOT built. |
| bd `8h7d.12` ((c3) diagnostic wording) | NOT built (left with `LoopLowering.cpp`'s owner; Group 1 did not take it). |
| bd `vsr6` (nested-loop matrix axis) | LANDED (359 → 382 cells). |

**The FIRST decline of the owner's loop program on the closing binary** (`example/grover/
grover_oracle_uncompute.c`, untracked; measured by the gate on `07d93784…` and re-measured on the
closing primary): `exit 1 at `grover_oracle_uncompute.c:91:15`, `cq controlled lowering: control flow inside a loop body under quantum control` (CQ_CTRL_DBG anchor `%24 = icmp sgt i32 %23, 2`; the gate reports the site as `ArmClassify.cpp:5478`, the composition reviewer as `ControlDetect.cpp:642/:689` — verify) — UNCHANGED from 2026-09-17 on `9bd01598``. **The SECOND decline** (one wall hand-peeled by the composition
reviewer, `review_r13_composition/REVIEW.md` item 7): ``<unknown>:0:0`, `cq loop lowering: loop-carried tainted value crosses iterations` (`LoopLowering.cpp:78`, kMsgCrossIter; carries no `!dbg`) — reached by making the line-91 prep unconditional (`review_r13_composition/probes/owner_peel1b_uncond_prep.c`); ⚠ both walls are the SAME construct, the in-loop `_Bool` VALUE arm (`if (b0[i]) a -= 3;`): deleting line 94 alone makes the file compile at exit 0 on the oracle AND the closing binary; the rail-array wall (bd `xdu2`) is GONE`.

## 1. THE PURPOSE — bd `zujr`, the loop-carried handle variable

The owner's rulings stand (`session-2026-09-17-socratic/DECISIONS.md` S2–S4; bd memory
`owner-ruling-loop-carried-handle-2026-09-17`): trip-1 promotion accepted; byte-identity is an
instrument; *"compile EVERYTHING THAT IS NOT FORBIDDEN BY PHYSICS."* The headline is the owner's
rolled cascade compiling. Its body, per bd `zujr` and this session's measurements, in order:

1. **P0+P3 of `tu9q` FIRST** (orchestrator recommendation, DECISIONS Q4 — put to the owner at open):
   it retires the SUBJECT of `declineRound2FalsifiedRailGrants`' only fixture, so it needs the owner's
   word and a repaying RED fixture by a non-hoisted route; it is in `LoopLowering.cpp` beside
   everything below, so it goes first or not at all this session.
2. bd `832l` (preheader promotion of a constant entry incoming) + bd `ej5w` (a latch incoming that is
   a controlled-copy merge `%out`, at BOTH `kMsgCrossIter` sites `:2143`/`:2595`) + bd `3qlq.6`
   (the in-loop VALUE arm scope fence, `ControlDetect.cpp`) + bd `r903` (the `i8` `_Bool` wire —
   Track X measured it is what routes the owner's program into the value path at all; landing it
   moves the wall from §3c to gate 2c, which `drbq.12` now admits).
3. Then merge the parked `x5fp` branch with its first accept, and `8h7d.11`/`8h7d.12`.

**Owner questions to batch at open:** Q4 (P0+P3 / the fence retirement); Q1 (bbu0 A/B/C, now with
the addendum that option B's "cost" pair was a measured defect — bd `jlf8`); the class-H
disposition if it graded as a pre-existing leak (bd `z0cv`); the wall-5 scoping answer.

## 2. OPEN P1s THAT LANDED WITH THIS SESSION'S NAME ON THEM (do not lose them)

bd `jlf8` — the loop-free unrolled twin `slice_control_inplace_ry_loop_leak_unrolled.c` still compiles
a Rule-8 wrong unitary and is under NO gate (kept unregistered, RED for the fence it owes to `s82e`'s
class). bd `z0cv` — class H (see §0). bd `3n29` — matrix class D (the rolled OUTER loop's own rail
under a nested inner loop; needs both loops). bd `6n1s` — closed for the `t5j` and `g8` doors by a
BACKSTOP; the PLACEMENT for an arm-minted interior rail is filed (`trackT2/BD_TEXT.md`).

## 3. PROTOCOL — carry `$PREV/PROTOCOL.md` forward with THESE additions (each cost a filing this session)

* a `## Copied-forward checklist` at the top (F-1); every agent works under `<scratchpad>/<track>/`
  and every harness prints the cq-opt hash per result row (F-11); "never edit a script a running
  measurement imports" beside "never relink under a running measurement" (F-8); a digest-keyed
  retirement trigger names its renderer or keys on renderer-independent facts (F-13/G-10); an
  accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled probe with a trailing
  non-diagonal gate on every register the condition reads (F-10); §6.1 unchanged.
* Rule-13 budget: THREE consecutive sessions found a P1 on round 1 of a loop change; this session's
  did too (twice). Budget ≥3 rounds per core landing and one COMPOSITION round on the final binary.

## 4. Close
Standard Session Completion (CLAUDE.md): bd (`--append-notes`), lab entry 012 (≤5 pages, `--seal`),
`CLOSING_REPORT` / `DECISIONS` / `GATES` / `ROUTING` / `MERGE_FILINGS`, `git pull --rebase && git push`.
