# progress — review_r2_R1 (Rule-13 ROUND-2 lens R1: the FIXES, adversarially)
## 2026-09-05 step 0 — setup
- Fresh start (previous instance killed by rate limit; nothing salvageable).
- Read BRIEF_common.md, BRIEF_review_r2.md, BRIEF_review_r1.md, fix_r1.md, impl_inc1b.md.
- Workdir: $SP/progress/review_r2_R1/

## 2026-09-05 step 1 — harness + first finding
- Built 3-binary harnesses `$SP/progress/review_r2_R1/{run.sh,multi.sh}`
  (main=c4bd888 SUBJECT, r1s=fa96336 ROUND-1 SUBJECT, orac=pre-3qlq).
- Smoke: `j3_sharecond_measure_only.c` main = 7 lines no negative angle; r1s = 10 lines
  with `cqrt_rz_i1(h1, -0x1p-2)`. Harness confirmed discriminating.
- **F-R1-1 CONFIRMED (rolled != unrolled, new population).** `o_onward_inloop.c` +
  `j1_lib.c` (the shipped 2-TU onward harness): a per-bit kickback loop over the ONWARD
  `%out` rail. main: rc 0, 34 trace lines, **0** `and_i32_hl_unc`, 3 leaked `and` rails;
  hand-unrolled twin `o_onward_inloop_unrolled.c`: 40 lines, all 3 discharge. diff is
  exactly the 3 `and_unc`+`free` pairs. STRICT 2b `0 violation(s)` on BOTH.
  r1s DECLINES `control flow` (shape only reachable through the F-L3-1 reorder).
  CONTROL `o_onward_inloop_ctrl.c` (identical module, loop reads the cq_theta ROOT q
  instead) discharges all 3 -> the cause is `invariantRegisterRoots`' root-mint-only
  clause (ii), which cannot see an onward `%out` rail (it is a CLASSICAL phi at
  `lowerLoops` time). `o_onward_inloop_interf.c` shows the 3 records survive a later
  `cqrt_ry_i32(h2,0.9)` on the very register they record (Rule 8).

## 2026-09-05 step 2 — measurements
- mdsweep over all 1582 fixtures on the SUBJECT binary
  (`$SP/progress/review_r2_R1/mdsweep.{sh,log}`): **ACCEPTED=633 MDMISMATCH=0
  NONI1FILES=0 CSWAPFILES=12**. Every emitted `call void @cqrt_rz_i1(` carries
  `!cq.branchphase`; NO non-i1 `cqrt_rz` anywhere; `cqrt_cswap` in 12 files, and
  NOT only from AbortParkEmit (4 abort-park + 8 value-arm/method-B files).
- 5 Rz emission expressions in the pass (`grep CreateCall(Rz`): SwapRouteEmit
  1539/1569/1774, AngleSelectEmit 179/181, SwitchRouteEmit 169 -> 179. ALL marked.
  ChainWalk.h:122 and NOTES §1 line 64 still say "three".
- P3/P4 probes: `&&`, `||`, folded nest, depth-3 AND, mixed AND/OR, empty outer,
  two-register nest all ACCEPT with exact-LIFO node undo + ancilla free + leaf
  strips. `&&` vs folded-nest traces BYTE-IDENTICAL (17 lines).
  Declines: shared leaf, classical leaf, trailing phase after an inner nest,
  depth-3 nest, mixed nest, inner if/else.
- P5 mutations (hand IR): default==case-block ACCEPTS and the emitted circuit is
  CORRECT (eq-fold of the 2-way switch); two-values-one-block, arm->arm,
  extra merge pred, scrutinee gated between all DECLINE.
- per-bit rolled vs unrolled: K=2/4 IDENTICAL, body-gate K=4 IDENTICAL,
  two-register K=4 IDENTICAL; K=32 diverges ONLY by a `clang -O1` frontend fold
  of bit 31 to `icmp sgt q,-1` (both fully discharge) — NOT a lowering divergence.
- tainted angle declines flat / onward / uncontrolled.
- retired family: decl-only -> no decline + decl swept; address-take -> reserved-name
  decline; new-surface address-take -> F-L3-4 string.
- **F-R1-2 OVER-DECLINE (plain C, introduced by the F-L5-6 fix).**
  `g_abort_uncond_phase.c` (abort park + an UNCONDITIONAL `cq_phi` = a D2 GLOBAL
  phase): main rc=1 `phase-class value escaping under quantum control`; r1s rc=0,
  8 lines, byte-identical to the no-phase twin. Moving the same statement ABOVE
  the tainted branch (`g_abort_phase_before.c`) makes main rc=0. The notes'
  "LATENT at this HEAD — no plain-C program reaches any of the three fences" is
  measurably FALSE for the abort carrier; ret/break stay shut.

## 2026-09-05 step 3 — report written
- `$SP/progress/review_r2_R1.md` (400 lines). 6 findings + a 14-item CLEAR list.
  F-R1-1 CONFIRMED (onward in-loop rolled!=unrolled, stage-order gap at
  CQLoweringPass.cpp:393 vs :409); F-R1-2 OVER-DECLINE + false LATENT claim
  (TaintPropagation.cpp:1640 / AbortParkEmit.cpp:321); F-R1-3..6 doc/fixture truth.
- Fixture-ready modules: $SP/progress/review_r2_R1/repro_onward_inloop{,_unrolled}.ll
- VERDICT: NOT CLEAR.
