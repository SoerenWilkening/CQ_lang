; control_phase_kickback_mergephi_tree_leaf_inplace_arm.ll — ACCEPT: kickback tree leaf = an IN-PLACE Ry region's merge.
;
; bd test_C_libtooling-dm7f.53 — the SHARED leaf predicates (one spelling, R12):
; the branch phase calls the same `condTreeCoveredPhiGates` as the in-place Ry
; consumer, so a leaf whose region rotated a LIVE register (`φ = [Ry(S), S]`)
; no longer reads its own producer gate as staling evidence. Population change
; disclosed (L9): before, every such kickback declined `condition predates a
; non-diagonal gate`; the prep-merge leaves (fresh rail) were unaffected.
;
;   q0 Ry(1); q1 Ry(.3); if (q0) Ry(q1,.4); if (q0 ^ q1) cq_phi(.1);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i1 @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br i1 %1, label %3, label %5

3:
  %4 = call i1 @cq_theta_i1(i1 %2, double 4.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ %2, %0 ]
  %7 = xor i1 %1, %6
  br i1 %7, label %8, label %9

8:
  call void @cq_phi(double 1.000000e-01)
  br label %9

9:
  %10 = call i1 @cq_measure_i1(i1 %1)
  %11 = zext i1 %10 to i32
  %12 = call i1 @cq_measure_i1(i1 %6)
  %13 = zext i1 %12 to i32
  %14 = add nuw nsw i32 %13, %11
  ret i32 %14
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 4.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H2]], double 1.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H2]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
;
; Whole-file, pure negatives (a positive in a prefix windows the negatives
; after it): no route / copy / adjoint gate, every arm theta and region phi
; consumed; FCNT/CRCNT count the frees and the controlled Ry gates.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: zext i1 {{.*}} to i8
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
