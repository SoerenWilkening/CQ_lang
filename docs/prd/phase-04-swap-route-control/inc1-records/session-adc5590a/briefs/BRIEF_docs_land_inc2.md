# BRIEF_docs_land_inc2 — the Inc-2 LANDING docs flip (docs only), after the clearance verdict CLEAR-WITH-OWNER-QUESTIONS
Read `$SP/briefs/BRIEF_common.md`, `$SP/progress/clearance_inc2.md` (verdict + owner questions), and the current
Inc-2 status wording in `CLAUDE.md`, `ROADMAP.md`, `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md`
(status header, §0 Shipping status, §7 STATUS, E1/E11), `RETIRE_SWAP_ROUTE_INC2_NOTES.md`, `docs/backend.md` /
`docs/frontend.md` / `docs/design/rssa-swap-control/*.md` wherever the VALUE-arm swap route / `cqrt_cswap` is described
in the present tense. Agent name: `docs_land_inc2`. Model: opus. `.md` files only, in `$SP0/wt/inc2` (branch
`3qlq-inc2`). The record dir `inc1-records/session-adc5590a/inc2/` was just created by the orchestrator.

## Edits
1. Every "Inc 2 NOT landed / on branch `3qlq-inc2` / rebase owed / clearance pending" sentence → "**LANDED on `main`
   2026-09-06 as ONE squash commit** (the squash of branch `3qlq-inc2`, tip recorded in the landing commit message;
   `git log main -1`) after the clearance verdict `CLEAR-WITH-OWNER-QUESTIONS` (record `inc1-records/session-adc5590a/inc2/clearance_inc2.md`)".
   Keep the history dated.
2. **The swap route is now FULLY RETIRED**: `cqrt_cswap` is minted by `AbortParkEmit` (7.2) ONLY. Every sentence in
   CLAUDE.md (Rule 7's value-arm paragraph, the CORRECTNESS-RISK "SwapRouteEmit lowers value/permutation arms by
   method-B … this is the ONLY arm class that still routes, and it is Increment 2's subject", the "Where Things Live"
   rows for `SwapRouteEmit.cpp` / `SwitchRouteEmit`/`SwitchValueEmit`, the Key Prohibitions `_controlled` bullet, the
   Hallucination-Risk "Phase 4 is DONE" bullet), ROADMAP Phase 4, `docs/backend.md`, `docs/design/rssa-swap-control/`
   overview/scoping headers that describe the value-arm cswap route (`R → cqrt_copy_<W> copy-out → reverse-play R†`,
   method-B) in the PRESENT tense → rewrite to the controlled-copy merge (hoist the pure chain → two
   `cqrt_copy_<W>_controlled` into a |0⟩ rail → chain `_unc` → strip → one free; the chain-final rail LEFT ALLOCATED and
   ENTANGLED, E1) and mark the route text as HISTORY (dated), never delete it. `docs/design/rssa-swap-control/` are
   design artefacts: add a dated banner at the top of each rather than rewriting their bodies.
3. Counts: measure by command in the worktree (lit corpus, `ctest -N` total / `^e2e-` / `^e2e-slice-`, goldens,
   twin gates, goldens containing `cqrt_cswap` — expect 1) and update the dated count lines in CLAUDE.md/ROADMAP/PRD.
4. PRD §0: E1 stays; add a dated **E12** line: what Inc 2 landed, the four twin gates, `emitRoute` one call site,
   the OQ-22 widening kept, the 3qlq.5 unsoundness note, and the C-1 round 4 (bd 7yd0) status (say "in flight on
   branch `c1-round4`" unless the orchestrator's note in `$SP/progress/c1d_status.txt` says landed).
5. `inc1-records/session-adc5590a/inc2/README.md`: fill the verdict line.
6. **Clearance record items R-1 / R-2** (clearance_inc2.md §3): R-1 — PRD E1/§7.1's "5 `_unc` — the interior links"
   matches no golden: the interior rail is discharged by ONE `mul_i32_hl_unc` + TWO in-place adjoints + ONE free, the
   final rail is left dirty — correct the sentence in the PRD and in the notes. R-2 — the sentence "tracing the ancilla
   out leaves the reduced state on (q, p, out) unchanged" (`SwapRouteEmit.cpp` step-5 comment, the diamond slice
   header, PRD E1) is FALSE as a density-matrix statement (off-diagonals between p, p' with R(p) != R(p') dephase);
   what is true and sufficient: relative to the source's live registers (q, out) the reduced state equals the route's,
   since the retained p_old already determines R(p_old), and no CQ-expressible continuation can observe the
   difference because `out`'s retained label records it and the ABI mints no in-place Q+Q gate on `out` — exactly why
   3qlq.5 is unsound by default. Rewrite it in the PRD, the slice header (`.c` header comment only — the golden does
   not change; do not touch CMake), and the notes; the `SwapRouteEmit.cpp` comment is SOURCE — change the comment
   text only and note in the hand-back that a rebuild is NOT needed for a comment (the orchestrator's landing
   squash is verified by full ctest on the tree).
7. OQ-C3-1 (a value diamond followed by a rotation on its result declines `operand predates a non-diagonal gate`
   while the select twin accepts, all three binaries) and OQ-C3-2 (`int p = q*3; if (q>5) R6(p);` declines
   `non-routable value multiplexer`; instcombine folds the derivation into the chain head) are folded into bd
   `test_C_libtooling-3qlq.14` (the base-from-cond issue) — cite it in the notes' owner-question list.
ONE commit `docs(control): 3qlq — Inc 2 landing status + the swap route fully retired (clearance CLEAR-WITH-OWNER-QUESTIONS)`. Hand
back the hash and the list of sentences flipped.
