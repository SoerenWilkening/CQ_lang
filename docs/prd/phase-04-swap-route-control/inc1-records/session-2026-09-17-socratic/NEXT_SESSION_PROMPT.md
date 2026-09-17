# Session 2026-09-18 — orchestrator prompt

You are the **orchestrator**. You delegate to **opus subagents in git worktrees**; you do not build,
run suites, or edit pass source yourself. Same workflow as sessions 2026-09-13 / -14 / -14c / -15.

Read first, in this order: `CLAUDE.md` (operating manual), `ROADMAP.md` (status of record),
`$PREV/PROTOCOL.md`, `$PREV/ROUTING.md`, `$PREV/DECISIONS.md`, `$PREV/MERGE_FILINGS.md`,
`$THIS/DECISIONS.md`, `$THIS/GATES.md`, where

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang     # ⚠ MOVED — every older PROTOCOL names ~/Desktop/CQ_lang
SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/
THIS = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-17-socratic/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

---

## 0. THE PURPOSE — clear the debt that stands in front of the loop headline

The next headline is **bd `zujr`** (P1): the loop-carried HANDLE VARIABLE, which makes the owner's
rolled cascade `example/grover/grover_oracle_uncompute.c` compile. **It is NOT this session's
build.** This session prepares for it, per the owner's instruction of 2026-09-17:

1. **Close every open issue that is already done** — verified by measurement, never on a record's word.
2. **Implement and close** the rest of the dephasing / in-loop-pairing cluster the owner named:
   bd `s82e`, bd `tu9q` (and, already closed on 2026-09-17 after verification: `7845`, `c767`,
   `ti5o`). What remains of that cluster is ONE increment: **tu9q's hoisted-template half**.
3. **Every independent issue goes to a parallel agent.** Independence is decided **by file**, not by
   topic (PROTOCOL §S1).
4. **Parallel agents NEVER run redundant tests** (owner instruction, 2026-09-17). No two agents may run
   the same gate at the same time, and no agent re-runs a gate another agent has already recorded for
   the same binary hash. §6 says how this is enforced.

Owner rulings of 2026-09-17 that govern this session (`$THIS/DECISIONS.md`, bd memory
`owner-ruling-loop-carried-handle-2026-09-17`): trip-1 promotion is accepted; byte-identity with the
hand-unrolled twin is an **instrument, not the target** (the witness is a per-trip unitary argument
plus a quarantined divergence); and, verbatim, *"we do what is necessary to properly compile
EVERYTHING THAT IS NOT FORBIDDEN BY PHYSICS."*

The customer program, reproduced because `example/` is in `.git/info/exclude` (ruling E4: the e2e
slice is the record):

```c
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
}
```

Measured 2026-09-17 on the oracle below: `opt` exit 1 at 91:15, `control flow inside a loop body
under quantum control`, fired at `ArmClassify.cpp:5478`; its hand-unrolled twin accepts at 45 lines.
The root cause is **rail identity, not taint** — bd `zujr` carries the IR and the argument.

---

## 1. WAVE 0 — close what is done (cheap, parallel, one agent per cluster; no worktree needed)

**Method, binding.** For each candidate: locate the bead's own probe program or fixtures, run them on
the ORACLE (per-probe pipeline, PROTOCOL), and close with a **hash-keyed** reason in the form used on
2026-09-17 (see `bd show test_C_libtooling-7845` for the wording). A bead whose evidence you cannot
reproduce stays open with an `--append-notes` line saying what you tried. ⚠ `bd update --notes`
**REPLACES** the notes; always `--append-notes` (a restore from `dolt_history_issues` cost time on
2026-09-17).

Candidates the 2026-09-15 lab entry (`docs/labreport/sessions/009-*.tex`) lists as LANDED that the
tracker still holds OPEN / IN_PROGRESS as of 2026-09-17: bd `rpkr` and `gfsk` (in_progress),
`rixk`, `19vy`, `1739`, `jdec`, `gzgs`, `fve8`. Also sweep
`bd list --status open | grep -iE "loop|rail|fence|matrix"` against `git log --grep=<id>` for any
other id a landing commit names. Precedent from 2026-09-17, already closed and not to be re-done:
`hn29`, `leyd`, `52og`, `hrts`, `l3i1`, `dpau`, `7845`, `c767`, `2g52`, `ti5o`.

Do NOT close: `s82e` (umbrella, closes with Group 1), `tu9q` (half built), `xdu2` (its `.1` is an
open P1 and its deferred half is blocked by `de8n`/`n74d`), `bbu0` (owner question, §5).

---

## 2. GROUP 1 — bd `tu9q`'s HOISTED-TEMPLATE HALF, then close `tu9q`, `s82e`, `1m5p`

This is the session's one Rule-13-core build. Owner-ruled WANTED NOW on 2026-09-17; it is the
correctness boundary for the full Grover iteration (an S† after the oracle dephases on a leaked
which-path rail — Rule 8) and a prerequisite of bd `zujr`.

**What it is** (`$PREV/trackT/IMPL_T2.md` §6, read it whole before briefing): a hoisted
loop-invariant **TEMPLATE** rail read as DATA inside a marked body (`s2_live_derived_region.c`:
`int p = y * 3;` hoisted to the preheader). Two pieces, **one increment or none** — Track T measured
that admitting the root without the second piece gives K adjoints against ONE forward gate, *a wrong
unitary where today it is a decline*:

1. **The real multiplicity test** at `Uncomputation.cpp` §4 / §2.9 — *"same enclosing marked body, or
   equal trip multiplicity"*; cheapest sound spelling a per-block MARKED-LOOP-HEADER map beside
   `IterationLocalBlocks`. ⚠ It is **unreachable today**, so it cannot be written red-green until
   piece 2 makes it reachable — write the fixture WITH piece 2, not before (bd `8h7d.10` is the
   filed statement of this gap).
2. **A loop-EXIT recovery point for a preheader-minted rail** in `FreePoint` / `DagTraversal`:
   discharge `%p` ONCE after the loop, the body's per-trip rails per trip.

**Customers to move** (all DECLINE today at `cq loop lowering: rolled body leaks a rail entangled with
a rotated register`, the interim fence from bd `s82e` D4): `s2_live_derived_region.c` (twin 25), bd
`1m5p`, the three `control_phase_kickback_mixed_{hoisted_template,preheader_volatile_imm,short_sext}_leak_control.ll`
shapes, and CLAUDE.md §5's Q-R1-1 second half. **Positive controls that must not move**:
`s1_live_shift` 14 == 14, `s3_live_rootmint_region` 22 == 22, `w2k_noregion_invread` 20 == 20,
`b7b`/`b7c` 24 == 24 / 42 == 42, and the nested-loop n1/n2/n3 which must **keep declining** unless
the increment discharges them too (bd `emkg`'s class — check, do not assume).

**Sequence inside the group.** Scoping agent first (reads IMPL_T2 §6, §10, `loopfix/FIX.md` §8,
`Uncomputation.cpp:982-1000`, and answers *by file* whether the increment touches `LoopLowering.cpp`
lines `4143-4158`, `~4380-4560`, `2136`, `2579` — the seams E5.2 names); then implementation; then
**≥3 Rule-13 rounds** (the 2026-09-15 loop round found a P1 on round 1 of a smaller change); then the
group's merge-and-gate agent. Done means: every customer ACCEPTs rolled == twin (or a quarantined
divergence with its per-trip argument), STRICT 2b clean, K-independent lowered IR, red-green fixtures
per Rule 12 with an injection matrix and its MISSED count, then close `tu9q`, `1m5p`, and `s82e`
(after confirming the `InPlaceRailOps` scrub of IMPL_S2 §3/§8 is filed under an id, or fixing it if
it is in the same file).

⚠ Carry into every Group-1 brief: `taint.IterationLocalBlocks` is a raw `BasicBlock *` set nothing
scrubs, read in the accept direction by `FreePoint`/`Uncomputation` after `lowerBreakReversePlay`
creates blocks (IMPL_T2 §10 item 3, FIX.md §8) — the increment adds customers to it.

---

## 3. GROUP 2 — independent over-declines, in files Group 1 does not touch (parallel)

Each is a defect per the 2026-09-11 ruling. Spawn only after the Group-1 scoping agent has reported
its file surface, and drop any track that collides.

* **Track X** — bd `x5fp`: the §3c clobber fence (`ArmClassify.cpp` `diagonalAliasHit` +
  `StraightThrough`) fires THROUGH THE BACK EDGE; ask it PER ACTIVATION via `WireWalk`'s
  `provablyBeforePerActivation` / `phiTracksWire`. It is a part of bd `zujr` that is independent by
  file, so landing it now shortens the headline. L2 obligation from the bead: `condProvenance`'s φ
  walk feeds the 2c fence too — narrow both or neither.
* **Track D** — bd `drbq.12`: the LICM-hoisted loop-invariant compare (`condWireDisposition` P4).
  Position-aware generalisation shared by four callers; the i1 twin-matrix cell
  `m_none_ablphi_none_none_binv` is its live witness. `ArmClassify.cpp`, `RegionTreeDetect.cpp`.
* **Track V** — bd `vsr6`: the twin matrix has **no nested-LOOP axis** — the instrument that could
  not see bd `emkg`. `tools/` only. It is the witness Group 1 needs for n1/n2/n3; land it **before**
  Group 1's accept is cleared, as bd `uq96` / `rpkr` were.
* Optional, if capacity: bd `8h7d.12` (the (c3) diagnostic names a construct that works) — but it is
  in `LoopLowering.cpp` and therefore Group 1's file; give it to Group 1's implementer or leave it.

**Not this session**: bd `832l`, `ej5w`, `8h7d.11` — they are bd `zujr`'s body and all sit in
`LoopLowering.cpp` beside Group 1; building them under a tu9q increment is the E5.2 semantic-group
collision by construction.

---

## 4. OWED REVIEWS, not code

* **The 2026-09-15 loop group's two merge-derived fixture conversions and its `r3` composition** were
  cleared by the agent that merged them (FIX.md §8). Spawn one Rule-13 reviewer on the current
  `main` binary for those alone, before Group 1 lands on top of them.
* bd `tu9q.1` — `r1_break_loop` is an ACCEPT the one deciding instrument cannot be pointed at. Ask
  the Group-1 reviewer to give it a second opinion in passing.

## 5. OWNER QUESTIONS — batch them EARLY

* **bd `bbu0`** — E6 ruled (D) first; Track D's number is delivered (the warning is silent on 0 of
  14 programs the fence declines). A/B/C are still unruled. Put them with the number.
* **bd `zujr` wall 5** — E5 says the four-wall table was *"the first four I could reach"*. Before the
  loop session, is a scoping-only track (no code) wanted now to find wall 5 on a binary with Group 1
  landed? Recommend YES: it is cheap and it sizes the next session.
* **bd `dnqo`**, **bd `yiid`** (now a three-increment path, E3/E7/E8) — carried, not asked again
  unless a track needs them.

---

## 6. Protocol — binding, copy `$PREV/PROTOCOL.md` into `$SES/PROTOCOL.md` with TWO corrections at the top

1. **The repo path.** Replace every `/Users/sorenwilkening/Desktop/CQ_lang` with
   `/Users/sorenwilkening/Desktop/Projects/CQ_lang`. The primary `build/` was reconfigured in place
   on 2026-09-17 after the move (its `CMakeCache.txt` pointed at the old source dir).
2. **The oracle block.** Measured 2026-09-17 10:26 on `main` `79bd7af9` (pass source == `95949550`):

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d  build/ir-pass/libCQPass.so
```

`shasum -a 256` it before you use it; if it differs, STOP and report. ⚠ Before that rebuild the
primary `cq-opt` had been the 2026-09-14 oracle (`0e280fc6…`) for three landings — a decline the owner
measured by hand before 2026-09-17 may have been measured on it.

### 6.1 — NO REDUNDANT TESTS ACROSS PARALLEL AGENTS (owner instruction 2026-09-17, binding)

The 2026-09-15 protocol already says *cite, don't re-run* for a gate recorded at the same hash. This
extends it to **concurrency**: **no two agents run the same test at the same time, and no agent runs
a test whose result another agent is producing.** Mechanism, which the orchestrator enforces at
spawn and every agent follows:

* **Every gate has exactly ONE owner per binary hash**, named in the brief. The gate matrix in
  `$PREV/PROTOCOL.md` is the default assignment: the implementer owns `lit --filter` and single
  slices on its own fixtures, plus ONE `ir-pass-lit` at hand-off; the reviewer owns nothing that
  spawns a suite; the group's merge-and-gate agent owns the full `ctest -j6`, the equivalence sweep,
  the twin matrices and the corpus sweep. **Two tracks in one group share ONE merge-and-gate agent,
  so the group's suite runs once.**
* **Announce before you run.** Before starting any gate that takes longer than a single fixture
  (`ir-pass-lit`, any `ctest -R` over more than one entry, a corpus sweep, a matrix), append
  `IN-FLIGHT | <gate> | <hash16> | <who> | <HH:MM>` to `$SES/GATES_INFLIGHT.md` (one shared file in
  the MAIN checkout, append-only, one line per gate). Replace it with the result line in your own
  `GATES.md` when it finishes and mark the in-flight line `DONE`. An agent that finds a matching
  IN-FLIGHT line at its own hash **waits and cites**; it does not start a second run.
* **Same hash ⇒ same result.** A gate recorded in ANY track's `GATES.md` at the binary hash on your
  disk is cited, never re-run — including across groups. The orchestrator points each agent at the
  other tracks' `GATES.md` files at spawn.
* **Different hash ⇒ your own inner loop only.** A rebuild changes the hash and licenses only the
  gates the matrix assigns to your role; it never licenses a full suite.
* **The full `ctest -j6` runs at most ONCE per group landing and at most ONE at a time on the box**
  (already binding); with this rule it also runs at most once per binary hash, period.
* **Report the redundancy check.** Every hand-off report states, for each gate it cites, whose line
  it cited, and for each gate it ran, that no IN-FLIGHT line existed for it at that hash when it
  started. A gate that turns out to have been run twice at one hash is a protocol FINDING to record
  in `$SES/MERGE_FILINGS.md`, not a footnote.

Everything else in `$PREV/PROTOCOL.md` carries forward unchanged and binding: hash-keyed `GATES.md`
per track (`$THIS/GATES.md` is the format, with this session's cited lines); the gate matrix (the
implementer's inner loop is `lit --filter` + single slices, the reviewer runs no build and no suite,
the merge-and-gate agent is the ONLY full-`ctest` runner, never two full suites in flight);
`cmake --build build --target CQPass` alone is a false-green trap; the primary `build/` is read-only;
never `pkill` by pattern; `tests/e2e/CMakeLists.txt` has one tail anchor; the duplicate-body scan
after any fixture rename; Rule 13 rounds budgeted up front; Rule 19 wording.

---

## 7. Close

Standard Session Completion from `CLAUDE.md`: file issues for everything unresolved, run the group
gate(s), update bd (**`--append-notes`**), **append the lab-report entry** (`docs/labreport/`, ≤5
pages, `--seal`), then `git pull --rebase && git push` and verify `git status` is up to date.

Write `$SES/CLOSING_REPORT.md`, `$SES/DECISIONS.md`, `$SES/GATES.md`, `$SES/ROUTING.md`,
`$SES/MERGE_FILINGS.md`, and `$SES/NEXT_SESSION_PROMPT.md` for the bd `zujr` session — whose brief
must state, in words, which of `832l` / `ej5w` / `x5fp` / `8h7d.11` / `8h7d.12` / `tu9q` are landed
and what the first decline of the owner's program is on the closing binary.
