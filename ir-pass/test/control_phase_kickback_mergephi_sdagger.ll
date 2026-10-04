; control_phase_kickback_mergephi_sdagger.ll — ACCEPT (bd `3qps`, Track P). The
; S† SHAPE on a prep merge φ: a chained `cq_theta` on the SAME register AFTER the
; region (`if (b1) cq_phi(φ); cq_theta(&b1, −θ);`).
;
; The wire fence finds that later Ry through the position-free walk and the DT
; prong proves it POST-branch (`ProvenPostRegion`). The P1 argument is what
; admits it, verbatim from the rail twin
; (`control_phase_kickback_rail_post_ry.ll`): a kickback copies nothing, replays
; nothing and allocates no work rail, so a later gate has nothing of the region's
; to invalidate. Pinned ORDER: the `rz` BEFORE the second `ry`, on ONE handle.
;
; ⚠ The MIRROR shape — a chained theta BETWEEN the φ and the branch — is the
; DECLINE `control_phase_kickback_reject_mergephi_chained_arm.ll`. Same fence,
; opposite position, opposite verdict.
;
; ⚠ RED ON THE ORACLE (`branch phase on a bare i1 condition`, `59ac5b7`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %b2 = call i1 @cq_theta_i1(i1 %b1, double -2.500000e-01)
  %m = call i1 @cq_measure_i1(i1 %b2)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double -2.500000e-01)
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; NOX-NOT: cqrt_toffoli
; FCNT-NOT: call void @cqrt_free(
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
