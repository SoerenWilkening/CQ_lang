; control_inplace_ry_mergephi_root_crossblock.ll — ACCEPT: a CROSS-BLOCK merge phi root, disjoint Ry in the gap.
;
; bd test_C_libtooling-dm7f.53 (R11 round-1 item 2) — a claimed REGION-MERGE
; phi as the WHOLE condition of an in-place controlled Ry / state prep. It is
; the one-leaf tree `collectCondTree` returns for a phi root, admitted by the
; leaf ladder (`condTreePhiLeafRefusal`: claimed InPlaceRotation merge,
; tainted, not measured before the branch) and lowered as a REGISTER-AS-CONTROL
; exactly like a bare `_Bool` rail (`PhiRootCond` / `RegCond` in
; `classifyArms`): `cqrt_ry_<W>_controlled(t_rail, u, θ)`, the phi never minted,
; bracketed or freed; a negated arm is `ry(u,θ); ry_controlled(t,u,−θ)`. The
; region is emitted before the prep that owns the phi (hcrg alias edge, or
; `PrepRegionIdxs` cross-block); the wire question is the kickback phi root's
; (`condWireDisposition` with `CondIsClaimedRailPhi` and the covered producer
; gates; a cross-block phi asks the wire-scoped `crossBlockPhiLeafMintable`).
;
;   if (a) Ry(t,.3); if (c) Ry(v,.4); if (t) Ry(u,.2);   (v prepped)
; Region 2's chained Ry on v sits between t's merge and the third branch; it
; relabels no member of t's rail, so the wire-scoped gap admits it (the same
; question bd dm7f.62 asked for the kickback root, closed here). The record
; `PrepRegionIdxs` orders region 3 before region 1.
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
  %2 = call i1 @cq_theta_i1(i1 false, double 6.000000e-01)
  %3 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  br i1 %1, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ false, %0 ]
  br i1 %2, label %8, label %10

8:
  %9 = call i1 @cq_theta_i1(i1 %3, double 4.000000e-01)
  br label %10

10:
  %11 = phi i1 [ %9, %8 ], [ %3, %6 ]
  br i1 %7, label %12, label %14

12:
  %13 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  br label %14

14:
  %15 = phi i1 [ %13, %12 ], [ false, %10 ]
  %16 = call i1 @cq_measure_i1(i1 %1)
  %17 = zext i1 %16 to i32
  %18 = call i1 @cq_measure_i1(i1 %7)
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %19, %17
  %21 = call i1 @cq_measure_i1(i1 %15)
  %22 = zext i1 %21 to i32
  %23 = add nuw nsw i32 %20, %22
  %24 = call i1 @cq_measure_i1(i1 %2)
  %25 = zext i1 %24 to i32
  %26 = add nuw nsw i32 %23, %25
  %27 = call i1 @cq_measure_i1(i1 %11)
  %28 = zext i1 %27 to i32
  %29 = add nuw nsw i32 %26, %28
  ret i32 %29
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 6.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H3]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 4.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H4]], double 2.000000e-01)
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H6:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H3]])
; CHECK:      %[[H7:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H4]])
; CHECK:      %[[H8:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H9:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
