# BRIEF_investigate_eqpx — READ-ONLY investigation of bd `test_C_libtooling-eqpx` (P1) to ground the OWNER'S RULING
Read `$SP/briefs/BRIEF_common.md` FIRST. Then `bd show test_C_libtooling-eqpx`, `RETIRE_SWAP_ROUTE_INC1_NOTES.md`
§3.11 (F-C1B-1 — the same class through the PREHEADER writer, and how round 3 fenced it: `isa<Constant>(Imm)` at the
commit + a LOUD lowering-time tripwire) and §3.12 (F-C1C-B = eqpx), `session-adc5590a/review_c1c.md` (the lens that
found it), the bd memory `fix-that-predicts-a-later-stage-must-reverify-there`, and the code: `LoopLowering.cpp`
(`tryCaseA`'s ACCEPT marking, `collapseRailPhisIn` step (3), round 1's `railRoot` marking, `commitOutOfLoopInPlaceOps`),
`OpcodeLowering.cpp` (`rewriteInPlaceValueRail`, the round-3 tripwire and its `diagnosePreLoopCommitStale`),
`ArithLowering.cpp` `classifyInPlaceReassignment` G2 ("exactly one tainted operand"), `TaintPropagation.cpp`
`repropagateControlMerges`. Agent name: `investigate_eqpx`. Model: opus. Progress file `$SP/progress/investigate_eqpx.md`.
Work dir `$SP/progress/investigate_eqpx_work/` (copy `$SP1/progress/review_c1d_work/run.sh` there, re-point `W=`).

**READ-ONLY: you edit NO checkout, NO worktree, NO fixture, NO bd issue. You produce a report. The owner has not yet
ruled whether eqpx is fixed now or deferred; your report is what the ruling will be made on.**

## Reproducers (on `main`): `inc1-records/session-adc5590a/c1_reproducers/c1c_m_xor_and_noregion.c` (+ `tu_extf.c` as
the second TU through `llvm-link`), and the other spellings named in the bd issue / review_c1c (in-body region,
`y*3`, `y+1`, the ADD twins `r += w`). Run each on THREE binaries — main 258d974 (`$SP/bin/main-258d974/` or the main
checkout), the pre-Inc-2 binary `$SP1/wt/fix-c1`, the ORACLE `$SP0/wt/pre-3qlq` — and record STATUS + the trace lines
that carry `cqrt_xorc_i32`/`cqrt_addc_i32`/`cq_template_{xor,add}_i32*`. Confirm the defect signature: a `cqrt_xorc_i32(h, N)`
whose `N` equals a template rail's handle id, that rail never `_unc`'d.

## Questions to answer, with evidence (file:line, IR excerpts, traces)
1. **The ADD/XOR asymmetry** (the bd issue says its cause is NOT located): why does `r += w` go OUT of place
   (`cq_template_add_i32` Q+Q) while `r ^= w` goes IN place with a rail in the immediate slot? Trace both stems through
   the SAME writer: which `InPlaceRailOps` writer marks the xor, what disposition the add gets there, and which of
   G2/G4/G5/G6/G7 (or the dtzb opcode set, or `rewriteInPlaceValueRail`'s `TL = Tainted.count(L)` operand pick) differs
   between the stems. Reproduce the difference on hand-IR if plain C cannot separate the variables. Say whether the ADD
   stem is correct BY ACCIDENT (i.e. a different clause happens to refuse) or by a fence that reasons about the immediate.
2. **The four `InPlaceRailOps` writers**, each with `file:line` on 258d974, the fence it applies, and whether that fence
   proves "the OTHER operand stays classical" under round-2 taint growth (the answer for all four is expected to be NO
   for round 1's three; round 3 fenced the preheader writer with `isa<Constant>(Imm)` + the tripwire — confirm).
3. **Reachability census**: which writers are reachable from plain `clang -O1` C with a round-2-tainted immediate
   (a 6.5 classical-call `%out`, a 4.5 data-mux `%out`, an Inc-2 value-merge `%out`, a 4.4 select `%out`, and any value
   DERIVED from one — `y & 7`, `y*3`, `y+1`)? Write ≥ 12 spellings across the writers × {add, xor, sub} × {in-body,
   preheader} × {noregion, in-body region}; tabulate STATUS on the three binaries. Every ACCEPT with a handle in an
   immediate slot is a CONFIRMED member; every ACCEPT that is out of place Q+Q and rolled==unrolled is correct; declines
   are declines (quote the string).
4. **The proposed fix, made concrete but NOT implemented**: at `lowerOps`, for EVERY `InPlaceRailOps` member re-ask G2
   under FINAL taint and decline loudly (the round-3 tripwire's shape). Specify: the exact site in `OpcodeLowering.cpp`
   (relative to the existing `PreLoopCommittedInPlaceOps` re-ask — can it be the SAME tripwire widened from "the
   pre-loop set" to "every marked op", or must it be a second one because G5 would refuse every in-loop site?), the
   diagnostic string (mirror the existing one's grammar), why a silent fallback to out-of-place is NOT sound (the body
   marking already licensed the discharge — bd memory), the red-green fixture list per stem (xor, add, sub) and per
   writer, the 8h7d.5 question ("what OTHER set was computed over the same closure?") for that widening, and what the
   over-decline cost would be (any program that is CORRECT today and would newly decline — measure with your census).
   Also state the ALTERNATIVE: re-ask G2 at the WRITER under round-2 taint (i.e. re-run the loop writers' marking
   after `repropagateControlMerges`) — and why that is or is not the once-only-stage mistake again.
5. **Blast radius of deferral**: is the defect reachable WITHOUT a round-2 onward `%out` (i.e. is there a round-1-only
   spelling)? If not, the population is "programs with a 6.5/4.5/4.4/Inc-2 merge feeding an in-loop in-place xor" —
   size it against the tree's goldens (`grep -l 'cqrt_xorc' tests/e2e/*.expected.log`, then check each for a merge
   producer) and against the 615-program session-2 population (`$SP1/progress/*_work/p/`): how many existing accepts
   carry the signature today?

## Hand back (`$SP/progress/investigate_eqpx.md`, and as your final message)
1. The defect signature reproduced on three binaries (table). 2. The asymmetry's cause, located (or the precise point
where you could not separate it, with the IR). 3. The four writers table. 4. The census table. 5. The concrete fix
proposal + its over-decline cost + the alternative, each with the 8h7d.5 question answered. 6. A ONE-PARAGRAPH
recommendation for the owner: fix now (estimated size: files, fixtures, rounds) vs defer (what stays reachable).
Nothing else. No code, no fixtures, no bd edits.
