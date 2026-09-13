# Fix brief — Track M, after review round 1 (`review_M_r1.md`, CLEAR-WITH-ITEMS)

Written 2026-09-13 by the orchestrator. Model: opus. Same worktree/branch/build (`/Users/sorenwilkening/Desktop/CQ_mphi`,
`mphi-rail-leaf`). Protocol `../PROTOCOL.md`, row "fix": rebuild (hash changes → `GATES.md`), re-run the
finding's probes + the fixtures you touch (`lit --filter`), `ir-pass-lit` ONCE at hand-off (pass source
changes), the corpus sweep ONCE after the fix, the injection matrix only for NEW accept fixtures. NO
`^e2e-`, NO full suite, NO equivalence sweep. Do not commit, do not push. Record `FIX_M_R1.md` beside this
file; append `GATES.md`. Read `review_M_r1.md` (all) and its probes first.

## F-M1 — emission ORDER: the prep can be emitted AFTER a following region, and the select's H-1 backstop then fires (OVER-DECLINE on plain C, `r03_order_third_region.c`)

`lowerControlRegions`' `hcrg` precedence graph orders a following `PhaseKickback` (whose `Pred` is the
prep's `MergeBB`) BEFORE the prep (A before B when A names a block B's flatten erases), while a
`SelectRegion` is inert (`Pending == 0`) — so the prep emits last, the select's re-read finds the φ still
present, and the loud backstop fires. **Fix = give the select its ORDER, by CALLING the record rung 0
already made:** at classification, when rung 0 admits the φ, RECORD the admitting region on the
`SelectRegion` (an index/pointer into `plan.Regions`, or the φ→region pair — a `WeakTrackingVH` if it
holds a `Value *`); in the precedence graph add exactly ONE edge "that region BEFORE this select region"
(the select has no blocks, so it aliases nothing else — verify the alias loop stays untouched). Never
re-derive the predicate in `SwapRouteEmit.cpp`. Then: `r03` must ACCEPT with the stream in SOURCE order
(prep → select → kickback per position; re-derive the commutation if the emitted order differs — each
emitter inserts positionally, so say what the trace shows and why it is the same unitary); `r18` (control)
byte-unchanged; the `_sdagger`/`m16`/owner streams byte-unchanged (cite the hash-keyed lines if the binary
were unchanged — it will not be, so re-measure the four customers). Keep the H-1 backstop (it is now the
"a seventh emitter forgot the edge" tripwire) and REWRITE the two false claims at
`SelectMergeEmit.cpp:96-119` ("emitted FIRST", "no subject today") to state the edge and the tripwire.
Fixtures: `r03` as an ACCEPT (`control_swap_accept_select_mergephi_rail_then_kickback.ll`, whole-file count
prefixes, injection row), and a DECLINE that exercises the backstop by hand IR if one can be written
without the edge (if the edge makes it unreachable, say so — the backstop is then pinned by the
counterfactual, recorded in FIX_M_R1.md the way H-1 was).

## F-M6 — the in-loop select on an OUTSIDE prep's φ moved DECLINE→ACCEPT (43 lines, rolled) with NO fixture

`r22_inloop_select_outside_prep.c`: pin it — a fixture with count prefixes (K-independent: the lowered
line count at K=3 and K=1000, no `-g`, recorded in the header), a `NOX-NOT` on the user register, an
injection row (extra `cqrt_x`, extra free, a gate moved OUT of the loop body), and an e2e slice
`slice_control_cascade_select_in_loop_outside_prep.c` + its hand-unrolled twin with a `compare_files`
gate (the `*-twin-identical` pattern) — the loop twin matrix has no `_Bool` axis, so this pair is the only
instrument for it. State in the header which loop-layer fence keeps the loop-CARRIED variant (`m30`)
declining and why this one is admitted (the φ is defined OUTSIDE the loop and is loop-invariant).

## F-M3 — in-place-ARM φ declines at rung (iii) (OVER-DECLINE, do NOT fix)

Leave it; the reviewer's caution stands (narrowing `condProvenance`'s seed before the `3d8q` fence lands
would remove the only thing that catches a pre-rotation reader). Pin `r01_inplace_arm_bool.c`'s shape as a
DECLINE fixture with a retirement trigger naming bd `3d8q`, and record it in FIX_M_R1.md for the
orchestrator to file.

## F-M5 / F-M7 — records only

F-M5: add `probes/impl/p3d8q_sibling.c` and `r15_p3d8q_sibling.c` to your §7.2 as bd `3d8q` reproducers
(the orchestrator appends them to the bead). F-M7: add the retirement-trigger comment at
`SwapRouteEmit.cpp:2526` (`declineRegion` would read a freed φ the day a block-carrying region kind gets a
merge-φ condition).

Final message ≤25 lines: the edge (file:line), `r03`'s new trace and its order argument, the four customers
re-measured, F-M6's numbers, lit line, corpus movers delta vs the r1 sweep, `GATES.md` lines added.
