; control_inplace_ry_tree_mergephi_leaf_prep.ll — ACCEPT: an in-Pred phi leaf of a state prep (b & c).
;
; bd test_C_libtooling-dm7f.53 — a condition-TREE LEAF that is the MERGE phi of
; an earlier controlled region (prep or in-place Ry) on the in-place Ry path.
; Before: `collectCondTree(…, AllowRailPhi=false)` refused it (`control flow`).
; Now the branch phase's step-5c ladder is CALLED (`condTreePhiLeafRefusal`:
; rung 0 the phi is a claimed InPlaceRotation merge, (i) tainted, (ii) not
; measured before the branch), the region is emitted BEFORE the prep (phi live;
; `PrepRegionIdxs` for a cross-block leaf), and the phi is a read-only control of
; the tree network (`cqrt_cnot`/`cqrt_toffoli`), stripped LIFO, ancilla freed at
; a proven |0>. The claimed region's arm gates are on-ancestry PRODUCERS of the
; leaf's record (`condTreeCoveredPhiGates`); a cross-block leaf asks the
; wire-scoped gap `crossBlockPhiLeafMintable`. IR transcribed from clang -O1.
;
;   bool a,c (rotated), b=0, t=0; if (a) cq_theta(&b,.4); if (b & c) cq_theta(&t,.3);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %1, label %3, label %5

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %7 = and i1 %2, %6
  br i1 %7, label %8, label %10

8:
  %9 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %10

10:
  %11 = phi i1 [ %9, %8 ], [ false, %5 ]
  %12 = call i1 @cq_measure_i1(i1 %1)
  %13 = zext i1 %12 to i32
  %14 = call i1 @cq_measure_i1(i1 %6)
  %15 = zext i1 %14 to i32
  %16 = add nuw nsw i32 %15, %13
  %17 = call i1 @cq_measure_i1(i1 %2)
  %18 = zext i1 %17 to i32
  %19 = add nuw nsw i32 %16, %18
  %20 = call i1 @cq_measure_i1(i1 %11)
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %19, %21
  ret i32 %22
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H2]], double 4.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H4]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H6:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[H7:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H8:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H4]])
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
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
