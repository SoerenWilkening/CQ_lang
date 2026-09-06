# BRIEF_review_inc2_r2 — Inc 2 ROUND 2 (one lens) after the rebase onto the landed Inc 1
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_review_inc2_r1.md`, `$SP/progress/impl_inc2.md`,
`$SP/progress/fix_inc2_r1.md`, `$SP/progress/review_inc2_V1.md`, `$SP/progress/review_inc2_V2.md`,
`docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1 (esp. §1.11 "what worries me").
Agent name: `review_inc2_r2`. READ-ONLY. SUBJECT = `$SP/wt/inc2` at __INC2_HASH__ (rebased onto the landed
Inc 1; build current); ORACLE = `$SP/wt/pre-3qlq`; INC-1-ONLY = the main checkout at the landed Inc-1 commit.

## The questions
1. **The increment's own reviewer flag, re-asked after Inc 1:** `emitSelectRegion` is now reachable from the
   value diamond with inputs `classifySelectRegion` would refuse — before Inc 1 the named class was "coherent
   Rz-lineage operands" (derived bases whose lineage carries a `cq_phi`). After Inc 1 `cq_phi` is register-free
   and no Rz lineage exists. So: enumerate what `classifySelectRegion` STILL refuses that the br classifier
   accepts (derived bases, aliases, fp bases, i1, kickback-phased registers — a register whose branch carries
   a kickback phase is a NEW kind of "coherent" operand: is copying it through `copy_controlled` sound? It is a
   basis-label copy; the phase rides the amplitude, not the label — argue it and MEASURE a program:
   `if (q==5) cq_phi(θ); if (c) p = R(p)` with p entangled with q), and for each construct the program, run on
   all three binaries, argue the unitary.
2. **The rebase itself:** Inc 2 and Inc 1 both touched `SwapRouteEmit.cpp`/`ArmClassify.cpp`/`ControlPlan.h`;
   after the rebase re-run Inc 2's four twin gates and the 14-accept injection matrix on the rebased binary;
   confirm the value path emits no `cqrt_cswap` (census: AbortParkEmit only NOW — Inc 1 retired the phase
   routes; grep + a full-corpus sweep) and no `!cq.branchphase` mark lands on a value-path gate.
3. **Value arm + kickback interplay (new since Inc 1):** a kickback and a value diamond on the same register in
   sequence (both orders), in one loop body, a value arm whose condition is a compound tree (P3's `CondTreeEmit`
   is shared with `SelectMergeEmit` — the value merge now uses the SAME network emitter: byte-identity between a
   `?:` with an `&&` condition and the diamond with `&&`), a switch with value arms + a kickback case (mixed → must
   decline), a kickback inside a value arm (mixed → must decline).
4. **The dirty chain-final class (F-V1-4/F-V2-3):** confirm the leaked R(p) rail can never be read by a later
   kickback's strip or by the Inc-1 in-loop discharge (`invariantRegisterRoots` clause (ii-b) admits control-owned
   merge out-rails — is a value-merge `out` rail such a root? if so, is a loop that reads `out` as its invariant
   condition register discharged correctly, rolled == unrolled?).
Write `$SP/progress/review_inc2_r2.md` (findings F-I2-k, grades, verdict line); return it.
