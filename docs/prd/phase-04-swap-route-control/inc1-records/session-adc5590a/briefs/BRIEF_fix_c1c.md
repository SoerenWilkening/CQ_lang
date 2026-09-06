# BRIEF_fix_c1c — the THIRD C-1 round: NARROW round 2 (lens findings F-C1B-1 and F-C1B-2), monotone, small
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1b.md`, `$SP/progress/fix_c1b.md` (what round 2 shipped
and why), then `$SP/progress/review_c1b.md` IN FULL (its reproducers under `$SP/progress/review_c1b_work/p/`, its
`CQ_DBG` copy under `…/dbgtree`), and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 ⭐ table + §3.10. Agent name: `fix_c1c`.
Model: opus. Same worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1`, at **638334c**. FIRST save the round-2
binary: `cp -f build/ir-pass/cq-opt $SP/progress/fix_c1c_work/cq-opt.fix2; cp -f build/ir-pass/libCQPass.so
$SP/progress/fix_c1c_work/libCQPass.so.fix2`. Binaries for red-green: PRE-FIX (main checkout 542d588), FIX-1
(`$SP/progress/fix_c1b_work/*.fix1`), FIX-2 (your saved pair), yours. ORACLE `$SP0/wt/pre-3qlq`.

## THE SCOPE IS NARROWING ONLY. This round adds NO capability. Every change must be in the refuse/decline direction, measured as: every trace that FIX-2 emits either stays byte-identical or becomes a REFUSAL (leak-control) / a LOUD decline; no new accept anywhere.

## F-C1B-1 — CONFIRMED-MISCOMPILE introduced by round 2 (the once-only-stage class, a NEW stage without a table row)
`commitOutOfLoopInPlaceOps` asks `classifyInPlaceReassignment` (G2 "exactly one tainted operand", G4, G5, G6/G7)
at round 1 (`CQLoweringPass.cpp:393`) and writes `taint.InPlaceRailOps`; `repropagateControlMerges` (`:409`) then
GROWS `taint.Tainted` (everything DERIVED from a 6.5 `%out` is tainted only at round 2); at `lowerOps` (`:536`)
`OpcodeLowering:263` skips M-C for a marked op and `:350` routes to `rewriteInPlaceValueRail`, which never re-asks
the shape. Result (`p/z23_preadd_r2derived_imm.c` + `p/tu_extf.c`): `cqrt_addc_i32(h7, 6)` where `6` is the HANDLE
ID of the `y*3` rail — a quantum handle in the ABI's classical-immediate slot; `z26` (operands commuted) mutates
the WRONG rail. Four plain-C programs (`z23`, `z26`, `z27`, `z29`), both stems, all `opt` exit 0, verify-clean,
STRICT 2b clean; all correct on 542d588 and FIX-1. `P->hasOneUse()` guarded G6/G7 (a later read of the parent) and
NOTHING guarded G2 (the OTHER operand is classical) — the 8h7d.5 lesson: `hasOneUse` was asked of `P`, the answer
that went stale was about `Imm`.
THE FIX, BOTH HALVES, and both are required:
* **(1a) the monotone fence at COMMIT time:** commit ONLY when the immediate operand `isa<Constant>` (a `Constant`
  can never become tainted — that is the whole argument, write it at the site). Measured by the lens to keep every
  shipped customer (`r2`'s 7, `r71`'s 9, `x1`'s 7, `z7`'s −7; `r33`/`r35`/`r40` have no preheader op) and to refuse
  all four reproducers; cost: `p/z21_preadd_volatile_imm.c` (a NEW accept of round 2 — a `volatile` load as the
  immediate) returns to today's leak, which is the Prime-Directive direction and is recorded, not regretted.
  Then answer the 8h7d.5 question for EVERY input of `classifyInPlaceReassignment` the commit evaluates at round 1:
  which of them can change between `:393` and `:536`? `taint.Tainted` (grows at round 2 — fenced by (1a) for the
  immediate; can it grow for `P` or for a USER of the op? argue and measure), the CFG (`DT`/`LI` are round-1
  trees; the round-2 flatten splices blocks — can it move the op into a loop, or change G5's answer?),
  use-lists (`hasOneUse` — the round-2 flatten RAUWs merge phis to `%out`: can that add a use of `P` or of the
  op?), `wd` widths. Write the table into notes §3.11 and give this stage its ROW in the §2 ⭐ table.
* **(1b) the loud tripwire at LOWERING time (Rule 1 — never a third path):** in `lowerOps`, for every op in
  `taint.InPlaceRailOps` that was COMMITTED by this stage (record which — a separate set, or a flag; do not
  re-verify the collapse's own body markings, which have their own proof), RE-ASK the same
  `classifyInPlaceReassignment` under FINAL taint/CFG; if the answer changed, `DiagnosticInfoUnsupported` with a
  new string (`cq loop lowering: pre-loop in-place op no longer provable at lowering` or similar — mirrored by a
  fixture) and lower nothing. A silent fallback to out-of-place is NOT sound (the body marking the commit
  licensed already stands). After (1a) the tripwire should be unreachable from plain C for the immediate half —
  pin it with a HAND-IR fixture (hand-edit `z23`'s stage-1 module so the immediate is a non-Constant that (1a)
  admits? if (1a) admits nothing non-Constant, construct the CFG/use-list half instead, or record honestly that
  the tripwire has no reachable customer and pin it by a mutation of (1a) in the notes).
* Fixtures: the four reproducers → ONE or two DECLINE-or-REFUSE fixtures (after (1a) they should emit FIX-1's
  out-of-place stream: pin THAT as an accept fixture whose `CHECK` is `cq_template_add_i32(` and `NOROUTE-NOT:
  cqrt_addc_i32` — the discriminator that a handle never lands in the immediate slot); `z21` as an
  accept-and-leak control; the tripwire's mirror fixture.

## F-C1B-2 — LATENT OVER-ACCEPT: `taint.ClaimedRailRoots` is module-wide, keyed on the root VALUE; clause (0)'s property is PER-LOOP
`p/z32_claim_across_loops_nomeas.c`: loop A carries `r` (claimed by `tryCaseA`); loop B has an onward per-bit region
and a DEAD `cq_theta(r,0.2)` in its body → `claimed=1` (from loop A) → loop B MARKED on a rail loop B never proved.
No wrong circuit was reachable (every spelling declines elsewhere), but the header's own pin (`x3`) cannot bound a
module-wide set from one loop. FIX: key the claim on the LOOP — record (root → the claiming loop's header
`BasicBlock*`) at both writers, and let clause (0) skip only when the claim names THIS loop's header. Verify the
header block SURVIVES the round-2 flatten (RegionFlatten erases merge blocks — measure that the header pointer is
stable for `r33`/`r35`/`r40`/`z9`/`z10`; if a header can be erased/replaced, key on something that cannot — say
what and why). Pin: `z32` must show `claimed=0`/unmarked (a leak-control fixture, byte-identical to FIX-1's trace),
and `r33`/`r35`/`r40`/`z9`/`z10` must stay 3/3 IDENTICAL.

## F-C1B-5 — the three doc slips (`CLAUDE.md:1756` 1665 → 1666; notes:967 1665 → 1666; the hand-back's "16 new / 4 cells" → the shipped 8 rows / 2 cells).

## Verification you owe
Red-green on FOUR binaries for every new fixture (the four reproducers: WRONG on FIX-2, correct on 542d588/FIX-1/yours) ·
the whole population (round 1 §3.5 + review_c1's 60 + fix_c1b's + review_c1b's 51) FIX-2 vs yours: the ONLY moved
traces are the four F-C1B-1 reproducers + `z21` + anything F-C1B-2's re-key refuses (list them; `z32` must move
to unmarked); everything else byte-unchanged · mutation validation for (1a), (1b), and the per-loop key (each
alone RED on its fixture) · `ctest -R ir-pass-lit` background → 0 reds outside your files · the perbit/onward/
mixed slices + every `*-twin-identical` gate + `e2e-loop-twin-quarantine-selftest` · the matrix in the background
(no cell may move) · the injection matrix over your new accepts (0 MISSED / 0 DIRTY) · STRICT 2b everywhere.
Docs: notes **§3.11** (this round: the finding, the two halves, the input-stability table, the §2 row), PRD §0 E2
(what the fix does not cover now includes the volatile-immediate leak), CLAUDE.md's C-1 sentence gains the clause
"a fix round 2 introduced a once-only-stage instance of its own, caught by the lens", counts re-measured by
command. Commit per step; hand back per BRIEF_common — first line: the four reproducers' emitted line on your
binary, and the `z32` marking.
