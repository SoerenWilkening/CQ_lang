; control_inplace_ry_tree_mergephi_leaf_crossblock.ll — ACCEPT: a cross-block phi leaf, disjoint Ry in the gap.
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
;   if (a) cq_theta(&b,.4); if (c) cq_theta(&u,.2); if (b & c) cq_theta(&t,.3);
;   (u, t prepped). The gap between b's merge and the third branch holds the
;   chained Ry on u, which the wire-BLIND scan refused; it relabels no member of
;   b's rail, so the wire-scoped gap admits it.
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
  %3 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %4 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  br i1 %1, label %5, label %7

5:
  %6 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01)
  br label %7

7:
  %8 = phi i1 [ %6, %5 ], [ false, %0 ]
  br i1 %2, label %9, label %11

9:
  %10 = call i1 @cq_theta_i1(i1 %3, double 2.000000e-01)
  br label %11

11:
  %12 = phi i1 [ %10, %9 ], [ %3, %7 ]
  %13 = and i1 %2, %8
  br i1 %13, label %14, label %16

14:
  %15 = call i1 @cq_theta_i1(i1 %4, double 3.000000e-01)
  br label %16

16:
  %17 = phi i1 [ %15, %14 ], [ %4, %11 ]
  %18 = call i1 @cq_measure_i1(i1 %1)
  %19 = zext i1 %18 to i32
  %20 = call i1 @cq_measure_i1(i1 %8)
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %21, %19
  %23 = call i1 @cq_measure_i1(i1 %2)
  %24 = zext i1 %23 to i32
  %25 = add nuw nsw i32 %22, %24
  %26 = call i1 @cq_measure_i1(i1 %17)
  %27 = zext i1 %26 to i32
  %28 = add nuw nsw i32 %25, %27
  %29 = call i1 @cq_measure_i1(i1 %12)
  %30 = zext i1 %29 to i32
  %31 = add nuw nsw i32 %28, %30
  ret i32 %31
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H3]], double 2.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H4]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 2.000000e-01)
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H4]], i32 %[[H5]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H5]], i32 %[[H3]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H4]], i32 %[[H5]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H5]])
; CHECK-NEXT: %[[H6:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H7:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H4]])
; CHECK:      %[[H8:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H9:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H3]])
; CHECK:      %[[H10:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
; CRCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
