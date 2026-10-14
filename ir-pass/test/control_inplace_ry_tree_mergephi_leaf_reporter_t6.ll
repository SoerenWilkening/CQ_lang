; control_inplace_ry_tree_mergephi_leaf_reporter_t6.ll — ACCEPT: the reporter's 3-qubit Dicke cascade (t6.c).
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
;   q0 Ry(1); q1 Ry(.3); if (q0) Ry(q1,.4);              c = q0 + q1
;   q2 Ry(.1); if (c == 1) Ry(q2,.1); if (c == 2) Ry(q2,.3); c += q2
; -O1: `c == 1` -> `xor i1 %q0, %q1.phi` (in-Pred phi leaf), `c == 2` -> `and i1
; %q0, %q1.phi` (CROSS-BLOCK leaf; region 2's arm Ry on q2 is in the gap, a
; disjoint rail). Region 3's target is region 2's merge (same rail as q2).
; Trace check: xor = CNOT,CNOT into |0>, cRy(.1), CNOT,CNOT, free; and =
; Toffoli, cRy(.3), Toffoli, free; then c's zext/add templates + _unc strips.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br i1 %1, label %3, label %5

3:
  %4 = call i1 @cq_theta_i1(i1 %2, double 4.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ %2, %0 ]
  %7 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %8 = xor i1 %1, %6
  br i1 %8, label %9, label %11

9:
  %10 = call i1 @cq_theta_i1(i1 %7, double 1.000000e-01)
  br label %11

11:
  %12 = phi i1 [ %10, %9 ], [ %7, %5 ]
  %13 = and i1 %1, %6
  br i1 %13, label %14, label %16

14:
  %15 = call i1 @cq_theta_i1(i1 %12, double 3.000000e-01)
  br label %16

16:
  %17 = phi i1 [ %15, %14 ], [ %12, %11 ]
  %18 = zext i1 %1 to i32
  %19 = zext i1 %6 to i32
  %20 = add nuw nsw i32 %19, %18
  %21 = zext i1 %17 to i32
  %22 = add nuw nsw i32 %20, %21
  %23 = call i1 @cq_measure_i1(i1 %1)
  %24 = zext i1 %23 to i32
  %25 = call i1 @cq_measure_i1(i1 %6)
  %26 = zext i1 %25 to i32
  %27 = add nuw nsw i32 %26, %24
  %28 = call i1 @cq_measure_i1(i1 %17)
  %29 = zext i1 %28 to i32
  %30 = add nuw nsw i32 %27, %29
  %31 = call i32 @cq_measure_si32(i32 %22)
  %32 = add nsw i32 %30, %31
  ret i32 %32
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 4.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H0]], i32 %[[H1]], i32 %[[H4]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H4]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H0]], i32 %[[H1]], i32 %[[H4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H4]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H1]])
; CHECK-NEXT: %[[H7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H5]], i32 %[[H6]])
; CHECK-NEXT: %[[H8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H2]])
; CHECK-NEXT: %[[H9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H7]], i32 %[[H8]])
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H7]], i32 %[[H5]], i32 %[[H6]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H7]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[H6]], i32 %[[H1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H6]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[H5]], i32 %[[H0]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H5]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[H8]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H8]])
; CHECK-NEXT: %[[H10:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H11:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H12:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[H13:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H9]])
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
; FCNT-COUNT-6: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
