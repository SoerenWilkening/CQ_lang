# Orchestrator ROUTING — session 2026-09-18

Obligations that fall BETWEEN tracks, each with a named owner and a named moment. Not rulings
(`DECISIONS.md`), not findings (`bd` / `MERGE_FILINGS.md`). An item here that reaches the closing
record unrouted is an orchestration defect.

Status key: **CARRIED** = inherited from 2026-09-15 `ROUTING.md` · **NEW** = opened this session.

## Carried from 2026-09-15

### R6 — compositions have no Rule-13 opinion — CARRIED, partially discharged
A×B (rail bank × classifier) and F′×P′ (`c1`/`c2`) were cleared by measurement and by no review. bd
`hlhh` is the tracker item for the F′×P′ half; Wave 0-B verifies whether the 2026-09-15 ARM round's
subject included the composition and closes or annotates accordingly. **Owner:** Wave 0-B, then the
orchestrator. **Moment:** Wave 0 report.

### R7 — S′ and T repaired/retired the same fence in parallel — CARRIED → this session's reviewer
`loopfix/FIX.md` §8: the two merge-derived fixture conversions and `r3`'s A×B composition were cleared
by the agent that merged them. **ROUTED** to `review_r13_loopconv/` (spawned at session open, on the
ORACLE `9bd01598`). Its verdict gates whether the Group-1 implementer starts from a clean premise.
**Owner:** the orchestrator on receipt. **Moment:** before Group-1 implementation is spawned, or —
if the review is late — before its Rule-13 round 1.

### R12 — bd `bbu0` (D) ruled — CARRIED, and (D) IS BUILT
Track D landed the reorder instrument in `95949550` (merge `79eb5b60`) and delivered the number
(`$PREV/trackD/MEASUREMENT.md`: SILENT 0 / WARNED 17 rows = 12 programs at the minimum scope; 21
rows = 14 programs at full corpus, 0 SILENT). A/B/C are put to the owner with that number in
`DECISIONS.md` Q1. **Owner:** the owner. **Moment:** batched at session open; carried if unanswered.

### R13 — over-spawning — CARRIED → PROTOCOL.md non-negotiables
The build cap (~3 concurrently building tracks at `-j2`–`-j4`) and the safe `pkill` form are now in
`$SES/PROTOCOL.md`, not in an anecdote. **Owner:** the orchestrator at every spawn.

## Opened this session

### R14 — NEW — Track V lands BEFORE Group 1's accept is cleared; file ownership decided at spawn
`tools/loop_twin_matrix.py` + `.expected.txt` + `.quarantine.txt` are Track V's EXCLUSIVELY. Group 1
does not edit them: its twin witness goes through committed goldens + `*-twin-identical` ctest
entries (as Track T did), and any divergence to quarantine is HANDED to the merge-and-gate agent as a
row + its per-trip unitary argument (owner S3). The Group-1 merge-and-gate agent rebases onto V's
landing and re-runs the matrix ONCE on the combined binary. **Owner:** the orchestrator (ordering),
the Group-1 merge-and-gate agent (the matrix run). **Moment:** V's report, then Group 1's gate.

### R15 — NEW — bd writes happen ONLY in the main checkout
`.beads/` is per-checkout; a worktree write creates a DB `main` never sees (measured 2026-09-14 by
Track T). Tracks put the exact `bd` text in their `IMPL_*.md` §bd; the orchestrator applies it.
Wave-0 agents write bd directly (they run in the main checkout); two of them concurrently — the
dolt gate lock serializes, retry on lock. **Owner:** the orchestrator. **Moment:** each landing.

### R16 — NEW — Group 2 is spawned only after Group-1 scoping reports its FILE SURFACE
Tracks X (bd `x5fp`) and D (bd `drbq.12`) both edit `ArmClassify.cpp` (D also `RegionTreeDetect.cpp`)
and are therefore ONE group with ONE merge-and-gate agent regardless of topic. If Group-1 scoping
reports that the tu9q increment must touch `ArmClassify.cpp` / `RegionTreeDetect.cpp` / `WireWalk.*`,
Groups 1 and 2 merge into one gate. **Owner:** the orchestrator. **Moment:** on `SCOPE_T2.md` §1.

### R17 — NEW — the owner-question batch cannot be answered mid-session
The session runs autonomously; `DECISIONS.md` records the questions WITH the numbers, the
recommendation, and the assumption each track proceeds under. Nothing in it is a ruling (L7).
**Owner:** the orchestrator. **Moment:** written at open; surfaced verbatim in the closing report.

### R18 — NEW — the owed review's P1 (bd `6n1s`) is taken by Group 1 as its FIRST item, not by a separate fix track
`review_r13_loopconv` (spawned at open) found a multi-block marked body leaking coherent which-path
rails at exit 0, warning only. Its mechanism — a discharge landing in a different block from its mint —
is exactly what Group 1's P2 (the loop-exit anchor) makes the common case, and it lives in Group 1's
two files. A separate fix agent would collide by file; so the implementer's brief puts `6n1s` at step
0 (measure regression-vs-pre-existing on `0e280fc6…`, RED `t5j` / GREEN `t5i` / control `t5k`, fix F-2's
prose in the same change) ahead of P1→P2→P0→P3. **Owner:** the Group-1 implementer, then its independent
reviewer (who must attack the multi-block marked body as lens 1). **Moment:** hand-off.

### R19 — RESOLVED 2026-09-17: Track X is PARKED (branch `x5fp-clobber-per-activation` @ `69414276`, committed, NOT merged)
bd `x5fp`'s narrowing may have no reachable ACCEPT until bd `ej5w` (the loop-carried handle) lands — every
C spelling of the back-edge clobber dies at X1 `kMsgCrossIter` first. Track X scopes the witness question
first; if no accept exists, the branch is committed, NOT merged, with D→D fixtures and an L8 trigger, and
the `zujr` session lands it with its first accept. A fence narrowing with no reachable customer is a
prediction (Rule 12; IMPL_T2 §6's own refusal). **Owner:** the orchestrator on Track X's
`FILE_SURFACE.md`. **Moment:** before Group 2's gate is spawned.

**R19 resolution.** Track X measured that NO program — C at `-O1` or hand IR — has S-1 as its only wall
(`trackX/IMPL_X.md`, `FILE_SURFACE.md`): the one-operand pair `h1`/`h2b` shows the wall behind the clobber
is `ControlDetect.cpp`'s IN-LOOP SCOPE FENCE part 2 (bd `3qlq.6` / `1dbk` item 1), **not** bd `ej5w`; and on
the owner's program the clobber is an ARTEFACT of the `i8` `_Bool` wire (bd `r903`) — with the wire removed
the module declines at gate 2c (bd `drbq.12`, Track D). Consequences for the `zujr` brief: (a) `r903` is
on the owner's program's critical path and `x5fp` is not; (b) `3qlq.6` is a wall the four-wall table did not
name. Group 2 is therefore Track D alone; the X × D composition check (re-run `…inloop_dtzb_same_rail.ll`
and `…inloop_mixed_evidence.ll` on a binary carrying both) is owed the day X is merged.

### R20 — NEW — Group 2 (Track D) lands BEHIND Group 1 under ONE combined merge-and-gate; the D × Group-1 composition is the reviewer's subject
`review_r13_trackD` F-1 (P1, population): Track D's accepts hand new members to bd `s82e`'s in-loop
dephasing class — `probes/dD1_hoisted_template_cond_then_ry.c` (a hoisted `q & 1` template rail as the
compare's operand, compare LICM-hoisted, trailing `q = cq_theta(q,0.9)`, `q` measured) goes DECLINE→ACCEPT
on D's binary with the rail never `_unc`'d and a warning only, while its hand-unrolled twin `dD4` discharges
it (0 dirty). That is EXACTLY the shape Group 1's P2 (the loop-exit anchor for a preheader-minted rail)
exists to discharge. Landing D alone would ship a known P1 widening; landing D after Group 1 turns dD1
into a composition measurement. **ROUTED:** one merge-and-gate agent for both groups (V is already on
`main`), merge order Group 1 then D, with dD1/dD4/dD5 REQUIRED on the combined binary (dD1 must ACCEPT with
the hoisted rail discharged, no warning, multiset == dD4's) — if it does not, D is HELD and a fence is owed
to `s82e`, not to D. The final independent Rule-13 round's subject is the COMPOSITION (R6's lesson, third
session running). **Owner:** the orchestrator (sequencing), the merge-and-gate agent (the measurement),
the composition reviewer. **Moment:** Group 1's hand-off.

### R21 — NEW — the twin matrix is RED for a CHECKER reason, and the checker is fixed in-session (Track C)
Gate pass 1: 25 cells `HARNESS-ERROR` because stage 2b returns `UNPROVEN` on P2's loop-exit discharge
(mint before the loop, read-only uses in the body, `_unc`+free after the exit) — a proof the checker lacks,
not a compiler defect (all `0 violation`, `0 dirty`; bd `1m5p`'s six class-A cells hand-measured fixed).
**ROUTED:** Track C (`freepair-loop-exit-discharge`, off the gate tip, `tools/free_pairing_check*` only,
≥4 mutants) → merged into the gate before pass 2; `--allow-unproven` is NOT the answer. **Owner:** Track C,
then the merge-and-gate agent. **Moment:** pass 2.
