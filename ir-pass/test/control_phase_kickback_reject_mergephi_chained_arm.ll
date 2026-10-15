; control_phase_kickback_reject_mergephi_chained_arm.ll — **NOW AN ACCEPT**
; (bd `test_C_libtooling-dm7f.53`, discharging bd `drbq.7`'s retirement trigger).
;
; ⚠ THE `reject_` IN THE NAME IS HISTORY AND THE FILE IS DELIBERATELY NOT RENAMED
; (the bd `gahu` precedent: a `git mv` can be RESURRECTED by a merge, CLAUDE.md L8).
;
; THE OLD HEADER (Track P) said this stays a DECLINE "until bd `drbq.7` lands",
; and warned: do not fix it by NARROWING the φ's rung-(iii) seed to the arm theta
; alone. dm7f.53 lands drbq.7 for a claimed merge-φ condition WITHOUT narrowing
; any seed: the seed set is still `condProvenance(%b1) = {%b1, %armv, %seed}`
; and every seed is still walked. What changed is that the CLAIMED region's arm
; gate `%armv` is passed to `findNonDiagonalWireGate` as `Covered`
; (`condTreeCoveredPhiGates`): skipped as EVIDENCE, its forward wire still
; walked. The old verdict "DIRTY off-ancestry" was relative to the seed `%seed`;
; the condition reads `%b1`, and `%armv` is the PRODUCER of `%b1`'s arm-path
; record — it executes only before `%b1` is defined, so it cannot stale it.
; "The merge φ names two different basis labels of ONE register" is exactly
; what an in-place controlled Ry produces, and reading that register as a
; control is the kickback's ordinary rail read.
;
; WHAT STILL DECLINES (the cone the old header protected): a gate ON `%b1`
; (a second Ry arm whose target is its own condition, the in-place-ARM φ family)
; is a forward user of the seed `%b1` and is NOT covered —
; `control_inplace_ry_reject_tree_mergephi_leaf_target.ll`; a pre-region name
; read by another leaf keeps `%armv` as evidence (`condTreeCoveredPhiGates`'
; enumeration) — `control_inplace_ry_reject_tree_mergephi_stale_prename.ll`.
;
; Trace check: b0 Ry(.5); seed Ry(.9); Ry(.2) on the seed rail under b0 (region
; 1, emitted after the kickback, M-β); then the branch phase `cqrt_rz_i1` on that
; SAME rail (the register IS the flag — nothing minted, stripped or freed, no
; `cqrt_x`). Stage 2b: 2 rail mints, 2 left allocated, 0 frees.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %seed = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %armv = call i1 @cq_theta_i1(i1 %seed, double 2.000000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %armv, %arm ], [ %seed, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
;
; Whole-file, pure negatives.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_free(
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
