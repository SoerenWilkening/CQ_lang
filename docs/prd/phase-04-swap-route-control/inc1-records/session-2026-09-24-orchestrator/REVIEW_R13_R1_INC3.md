# bd `fn1q` increment 3 — Rule-13 ROUND 1 (independent agent) and its dispositions

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 2 P2, 6 P3.** No wrong accept was found. The
reviewer built a MUTANT TREE whose baseline `cq-opt` came out bit-identical to the
subject (a clean null control), so every mutant delta it reports is attributable to its
own source edit. It ran an INDEPENDENT 2136-fixture A/B and reproduced this record's
three movers with no fourth.

⚠ **WHAT IT DID NOT CLEAR IS THIS INCREMENT'S RECORD.** It falsified five premises
written into SHIPPED SOURCE and two of the increment's own claims. All seven are fixed
IN THE SAME CHANGE, at the source, per CLAUDE.md L7's twist — *a record correction that
is not applied to the source is not a correction*.

| # | sev | finding | disposition |
|---|---|---|---|
| F-1 | P2 | five shipped-source premises say PredMux never claims a loop — incl. **W7's own anti-overlap argument** (`PredMuxFlatten.cpp`), the pipeline comment (`CQLoweringPass.cpp`) and TWO enumerations in `Specialization.cpp` | **FIXED at all four sites.** Each now names what ACTUALLY fences the in-loop owners — **E4**, because every shipped in-loop owner holds a `cq_phi`/`cq_theta` call in its arm — and carries a retirement trigger for the day E4 admits one. |
| F-2 | P2 | `recoverRegion`'s bd-20xt.5(d) block says *"E2 declines the former [infinite loops]"*. It no longer does: with no reachable `ret` the post-dominator sets never get an exit seed, the "merge" is an arbitrary block, and such a region now travels to `W-witness` or `E2-regioncycle` | **FIXED.** All four spellings still DECLINE (measured). The comment now says the refusal rests on the Kahn proof and on an unanalysed accident of degenerate post-dominance, and marks the path UNANALYSED. ⚠ Nobody constructed one that CLAIMS — an absence of a probe, not a proof. |
| F-3 | P3 | this record's *"(b) reachable? **NO — measured**"* is **FALSE**. A MULTI-LATCH loop reaches `E2-loopheader` | **FIXED + FIXTURED** (`control_predmux_reject_inloop_header_nonentry.ll`). The source comment now says REACHED, FIRST-FIRING, BACKSTOPPED — with the mutant measurement that deleting (b) moves it to `E2-regioncycle` and changes no shipped fixture. |
| F-4 | P3 | two comments in the SAME change contradict each other: *"(e-inner) MUST NOT BE DROPPED AS REDUNDANT"* vs *"so the refusal is a NAMED gate and not a silent `return false`"*. The mutant sides with the second | **FIXED.** E2's `topoOrderRegion` call buys a GATE NAME, not a fence — the unconditional tail call refuses anyway. Stated as the modest benefit it is. |
| F-5 | P3 | `…_reject_inloop_irreducible.ll` does not exhibit clause (e)'s shape (under the mutant it declines at `E3-sideentry`) | **FIXTURED** (`…_reject_inloop_irreducible_inregion.ll`): both cycle entries in-region, every terminator tainted, so E3 and E6 are blind and only acyclicity refuses. Both fixtures now say which is which. |
| F-6 | P3 | `CHECK-NOT: cq controlled lowering` / `cq loop lowering` in two fixtures are **vacuous** — a diagnostic goes to stderr and those prefixes read the emitted MODULE | **FIXED.** Removed (not re-aimed), with the reason written in. Verified independently: `grep -c` for those strings on the lowered module = 0. Replaced with block-label negatives that CAN fail. |
| F-7 | P3 | the twin gate's stated reason for skipping golden lines 1..6 is wrong — they are **byte-identical unrenamed** | **FIXED** in both `tests/e2e/CMakeLists.txt` and the twin `.c`. Verified independently (`diff` of the two prologues: empty). The real reason is that the rename map would rewrite those rows' own targets. |
| F-8 | P3 | the new accept surface is ~10 shapes wide, not the four this record named — incl. the **increment-2 x increment-3 composition** | **FIXTURED** (`control_predmux_accept_inloop_rail_leaf{,_twin}.ll`) and §9 below. |

## 9. THE ACCEPT SURFACE IS WIDER THAN §2 SAID

Round 1 measured about ten shapes moving DECLINE -> ACCEPT, each with a `select` twin the
**ORACLE** already accepts and each stage-2b STRICT clean: a nested tainted region in a
loop; a region in the OUTER body of a NESTED loop; two SEQUENTIAL regions in one loop
body; a RUNTIME-TRIP guarded loop; increment 2's BARE RAIL LEAF as an in-loop condition
(iteration-local and loop-invariant); W6/`StrandedCondPhi` chaining two in-loop regions; a
classical `break` beside an in-loop diamond; and i8/i16 narrow widths (correct template
widths — bd `11qv`'s `HandleWidth` record holds under the composition).

⚠ **THE COMPOSITION IS THE ONE THAT GOT A FIXTURE, AND THE REASON IS A STANDING FILING.**
CLAUDE.md records *"a composition is not cleared by clearing its parts"* as filed in FIVE
CONSECUTIVE SESSIONS. Increment 2's rail leaf plus increment 3's in-loop admission is
exactly such a surface, and unlike most of those filings it is exhibitable by
construction. Verified independently of the reviewer: ORACLE declines `control flow`,
SUBJECT exits 0, the `select` twin accepts on **both**, the two subject streams are
**BYTE-IDENTICAL at 27 calls**, and stage 2b reports `2 verified, 0 violation(s), 0
unproven`.

⚠ **THE REVIEWER'S OWN BOUNDARY IS PART OF THIS CLEARANCE.** It ran no full `ctest`, no
full `ir-pass-lit`, no twin matrix, no `cq-opt-equivalence-full`; it did not construct an
infinite-loop region that CLAIMS, did not probe the `claimAll`/Bennett-clone path or the
`CtlzIdiomPrepass` composition by construction, built no mutant for clause (a), and used
one function per module throughout (bd `1yeu`'s recorded structural gap). Its full "WHAT I
DID NOT DO" list is the boundary and is reproduced in the session handoff.

⚠ **IT ALSO CORRECTED THIS RECORD IN THE SAFE DIRECTION, AND THAT IS STILL A CORRECTION.**
§2 says clause (d)'s merge half is *"the one that matters most"* for the tainted loop exit.
Mutant-measured: with the merge half deleted, `…_reject_inloop_tainted_exit.ll` still
declines (at `E2-regioncycle`/`E2-loopheader`), because a tainted loop-exit region always
swallows the back edge. The claim was an overstatement; the disposition is unchanged.

## 10. A/B DELTA FOR THE FOUR FIXTURES ADDED AFTER THE FULL SWEEP

```
…_reject_inloop_header_nonentry        oracle=1 subject=1  same-decline
…_reject_inloop_irreducible_inregion   oracle=1 subject=1  same-decline
…_accept_inloop_rail_leaf              oracle=1 subject=0  D->A   (the composition)
…_accept_inloop_rail_leaf_twin         oracle=0 subject=0  same-accept
```
Running totals over 2140 fixtures: **A->D = 0**, D->A = 3, decline-string = 1,
**stream-moves = 0**.

⚠ The comment-only fixes for F-1..F-4 were verified not to change the binary: the rebuilt
`cq-opt` is **BIT-IDENTICAL** (`63d34f76…`) to the one the full A/B and the full `ctest`
ran against, so those results stand verbatim rather than being re-asserted.
